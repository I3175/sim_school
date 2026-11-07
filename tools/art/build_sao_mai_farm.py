"""Conform the accepted Image Gen assets and build the Godot farm map data."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile

from PIL import Image, ImageOps

from build_sao_mai_kit import ART, ROOT, forge, save_json

FARM = ART / "farm"
SOURCE = ART / "source"
UI = ART / "ui"
PROP_SIZES = {
    "farmhouse": (56, 48), "fruit-tree": (32, 32),
    "moss-rocks": (18, 12), "shipping-chest": (16, 14),
}

def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def prepare_media(work):
    boxes = SOURCE / "farm-prop-boxes.json"
    save_json(boxes, {"schema": "forge-crop-boxes/v1", "items": [
        {"id": "farmhouse", "box": [12, 112, 627, 616]},
        {"id": "fruit-tree", "box": [635, 60, 1240, 624]},
        {"id": "moss-rocks", "box": [64, 786, 567, 1110]},
        {"id": "shipping-chest", "box": [665, 773, 1205, 1140]},
    ]})
    output = work / "props"
    forge("generate2dmap", "extract_prop_pack.py", "--input", SOURCE / "farm-props.png",
          "--boxes-file", boxes, "--background-mode", "native_alpha", "--component-mode", "all",
          "--alpha-hygiene", "both", "--reject-edge-touch", "--art-source", "host_image",
          "--output-dir", output)
    pack = load_json(output / "prop-pack.json")
    anchors = {}
    for prop in pack["accepted"]:
        label = prop["label"]
        image = Image.open(output / prop["image"]).convert("RGBA")
        alpha = image.getchannel("A")
        bbox = alpha.point(lambda value: 255 if value >= 32 else 0).getbbox()
        cropped = image.crop(bbox)
        sprite = ImageOps.contain(cropped, PROP_SIZES[label], Image.Resampling.BOX)
        ground_x = round((prop["anchor_px"][0] - bbox[0]) * sprite.width / cropped.width)
        anchors[label] = [ground_x, sprite.height]
        sprite.save(FARM / f"{label}.png")
    portrait = work / "portrait"
    forge("generate2dsprite", "generate2dsprite.py", "process", "--input", SOURCE / "di_nam.png",
          "--target", "asset", "--mode", "single", "--background-mode", "native_alpha",
          "--alpha-hygiene", "both", "--single-size", 48, "--anchor-mode", "center",
          "--strict-qc", "--output-dir", portrait)
    (UI / "di_nam.png").write_bytes((portrait / "clean.png").read_bytes())
    title = ImageOps.fit(Image.open(SOURCE / "title.png").convert("RGB"), (320, 180), Image.Resampling.LANCZOS)
    title.save(UI / "title.png")
    portrait_meta = load_json(portrait / "pipeline-meta.json")
    save_json(SOURCE / "image-assets.json", {
        "route": "host_image", "tool": "Codex Image Gen", "model": None, "estimateUsd": None,
        "prompts": "image-gen-prompts.json",
        "inputs": {file.name: {"sha256": digest(file), "size": list(Image.open(file).size)}
                   for file in SOURCE.glob("*.png")},
        "portrait_qa": portrait_meta["qa"],
        "prop_qa": pack["qa"],
        "art": {
            path.relative_to(ART).as_posix(): {
                "sha256": digest(path), "size": list(Image.open(path).size),
                **({"anchor_px": anchors[path.stem]} if path.stem in anchors else {}),
            } for path in [UI / "title.png", UI / "di_nam.png", *(FARM / f"{key}.png" for key in anchors)]
        },
    })
    return anchors

def ground(layout, farming, manifest):
    width, height = layout["size"]
    field_x, field_y = farming["field_origin"]
    field_w, field_h = farming["field_size"]
    roads = [(0, 30, width, 31), (39, 0, 40, height), (37, 21, 39, 31),
             (36, 20, 39, 22), (35, 34, 43, 37)]
    beds = [(x, field_y + 1, x + 3, field_y + 10) for x in range(field_x + 1, field_x + field_w - 2, 5)]
    dirt_areas = roads + beds
    vertices = [[int(any(x0 <= x <= x1 and y0 <= y <= y1 for x0, y0, x1, y1 in dirt_areas))
                 for x in range(width + 1)] for y in range(height + 1)]
    tile_ids = {(tuple(tile["wang"]), tile["variant"]): tile["index"] for tile in manifest["tiles"]}
    return [[tile_ids[((vertices[y][x], vertices[y][x + 1], vertices[y + 1][x + 1], vertices[y + 1][x]),
                       ((x * 73) ^ (y * 151) ^ (x * y * 13)) % manifest["variants"])]
             for x in range(width)] for y in range(height)]

def build_map(anchors):
    balance = ROOT / "data/balance"
    layout = load_json(balance / "farm_layout.json")
    farming = load_json(balance / "farming.json")
    world = load_json(balance / "world.json")
    manifest_path = FARM / "spring-ground.tileset.json"
    manifest = load_json(manifest_path)
    tiles = ground(layout, farming, manifest)
    grid_path = FARM / "ground-tiles.json"
    grid_path.write_text("[\n" + ",\n".join("  " + json.dumps(row, separators=(",", ":")) for row in tiles)
                         + "\n]\n", encoding="utf-8")
    width, height = (16 * amount for amount in layout["size"])
    props = {}
    objects = []
    for prop, placements, (w, h) in (
        ("farmhouse", [layout["house"]], (44, 14)),
        ("fruit-tree", layout["trees"], (8, 6)),
        ("moss-rocks", layout["rocks"], (12, 8)),
        ("shipping-chest", [[680, 480]], (14, 8)),
    ):
        art = FARM / f"{prop}.png"
        props[prop] = {"image": art.name, "sha256": digest(art), "anchor_px": anchors[prop]}
        for index, (x, y) in enumerate(placements):
            objects.append({
                "id": f"{prop}-{index + 1}", "prop": prop, "x": x, "y": y, "anchor_px": anchors[prop],
                "footprint": {"shape": "rect", "width": w, "depth": h, "offset": [0, -h / 2], "basis": "world_px"},
                "occlusion_class": "tall" if prop in {"farmhouse", "fruit-tree"} else "low",
                "occupant_policy": "y_sort", "layer": "props",
            })
    spawn_x, spawn_y = layout["spawn"]
    farm = world["farm_main"]
    destinations = farm["links"] + farm["buildings"]
    interactions = [{"id": f"to-{name}", "x": spawn_x + (i % 4) * 72 - 108,
                     "y": spawn_y + 64 + (i // 4) * 48, "reach": 12} for i, name in enumerate(destinations)]
    interactions.append({"id": "shipping", "x": farming["shipping_position"][0],
                         "y": farming["shipping_position"][1], "reach": 28})
    save_json(FARM / "map-bundle.json", {
        "schema": "generate2dmap.map_bundle.v2", "id": "farm_main", "name": farm["name"],
        "art_source": "mixed", "world": {"width": width, "height": height, "unit": "px"},
        "tile_size": 16, "tilesets": [{"id": manifest["id"], "manifest": manifest_path.name, "sha256": digest(manifest_path)}],
        "layers": [{"name": "ground", "kind": "tiles", "data": grid_path.name, "tileset": manifest["id"],
                    "sha256": digest(grid_path)}, {"name": "props", "kind": "objects"}],
        "props": props, "objects": objects,
        "collision": {"actorRadius": 4, "ySquash": 0.625,
                      "rects": [[0, 0, width, 8], [0, height-8, width, 8],
                                [0, 0, 8, height], [width-8, 0, 8, height]]},
        "spawns": [{"id": "new-game", "x": spawn_x, "y": spawn_y, "facing": "down"}],
        "interactions": interactions,
        "camera": {"pixelToWorld": 1, "bounds": [0, 0, width, height]},
    })
    atlas = Image.open(FARM / manifest["image"]).convert("RGBA")
    artboard = Image.new("RGBA", (width, height))
    sprites = [atlas.crop((i % 16 * 16, i // 16 * 16, i % 16 * 16 + 16, i // 16 * 16 + 16))
               for i in range(manifest["tilecount"])]
    for y, row in enumerate(tiles):
        for x, index in enumerate(row):
            artboard.paste(sprites[index], (x * 16, y * 16))
    for obj in sorted(objects, key=lambda item: item["y"]):
        sprite = Image.open(FARM / props[obj["prop"]]["image"]).convert("RGBA")
        ax, ay = obj["anchor_px"]
        artboard.alpha_composite(sprite, (obj["x"] - ax, obj["y"] - ay))
    artboard.crop((480, 390, 800, 570)).convert("RGB").save(UI / "farm-preview.png")
    artboard.resize((160, 120), Image.Resampling.BOX).convert("RGB").save(UI / "farm-minimap.png")

if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="forge-", dir=ROOT) as temp:
        work = Path(temp)
        (work / ".gdignore").touch()
        build_map(prepare_media(work))
