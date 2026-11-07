"""Build the Làng Sao Mai pixel UI kit and spring terrain using Sprite Forge."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/art/sao_mai"
SKILLS = Path.home() / ".codex/skills"
PALETTE = {
    "i": "#2B1B17", "d": "#5A3A2A", "w": "#8B5E3C", "h": "#B98554",
    "p": "#F4E4BC", "c": "#FFF6DA", "g": "#6DB04A", "G": "#3E7B3A",
    "r": "#D94A4A", "R": "#8E2D3A", "y": "#F2C14E", "b": "#4A86C5",
    "v": "#8A64B8", "o": "#E8884A", "l": "#E58FA8", "s": "#8C8578",
    "a": "#5A3A2A", "t": "#8B5E3C", "u": "#8C8578", "q": "#C9A24A",
}
ICONS = {
    "sun": ["...y....", ".y.y.y..", "..yyy...", "yyyyyyy.", "..yyy...", ".y.y.y..", "...y...."],
    "coin": ["..yyy...", ".yoooy..", "yooyoyy.", "yoyyoyy.", "yoyoyoy.", ".yoooy..", "..yyy..."],
    "heart": [".rr.rr..", "rllrrlr.", "rllrrrr.", ".rrrrr..", "..rrr...", "...r...."],
    "bolt": ["...yy...", "..yy....", ".yyyy...", "..yy....", ".yy.....", ".y......"],
    "book": ["........", ".yhhhy..", ".ydpdy..", ".ydpdy..", ".ydpdy..", ".yhhhy..", "..pppp.."],
    "bag": ["..iii...", ".iwcwi..", ".iwwwi..", "ihhhhhi.", "iwwpwwi.", "iwwwwwi.", ".iiiii.."],
    "map": ["..p..p..", ".pbppbp.", ".pbbpbp.", ".pbbpbp.", ".pbppbp.", ".pp..pp."],
    "leaf": ["....ggg.", "...ggGg.", "..ggGg..", ".ggGg...", ".gGg....", "..G.....", ".G......"],
    "fish": ["........", "..bb.b..", ".bccbb..", "bcbccb..", ".bbb.b..", "..b....."],
    "spark": ["...y....", "...y....", "..yyy...", "yyyyyyy.", "..yyy...", "...y....", "...y...."],
    "gear": ["..s.s...", ".ssssss.", "sscpcss.", ".sp.ps..", "sscpcss.", ".ssssss.", "..s.s..."],
    "sword": [".....pp.", "....pbp.", "...pbp..", ".opbp...", "..op....", ".odo....", "od......"],
    "letter": ["........", ".pppppp.", ".pippip.", ".ppippp.", ".pppppp.", "........"],
    "cloud": ["........", "...cc...", "..cccc..", ".cccccc.", "cccccccc", ".cccccc."],
    "lock": ["..iii...", ".i...i..", ".i...i..", "yyyyyyy.", "yyyiyyy.", "yyyyyyy."],
    "clock": ["..ppp...", ".pcccp..", "pcciicp.", "pcciccp.", "pcccccp.", ".pcccp..", "..ppp..."],
    "hand": ["........", "..cc....", "..cc....", "..ccccc.", "ccccccc.", ".cccccc.", "..cccc.."],
    "pen": [".....oo.", "....opp.", "...opp..", "..opp...", ".opp....", "oi......", "i......."],
    "flask": ["..ppp...", "...p....", "...p....", "..pgp...", ".pgGgp..", ".pgggp..", "..ppp..."],
    "dialogue": ["........", ".vvvvvv.", "vccccccv", "vcvcvcvv", "vccccccv", ".vvvvvv.", "..v....."],
    "history": [".qqqqqp.", ".qppppq.", ".qddpq..", ".qpppq..", ".qddpq..", ".qpppq..", ".pqqqqp."],
    "calculator": [".bbbbb..", ".bcccb..", ".bbbbb..", ".bcbcb..", ".bbbbb..", ".bcbcb..", ".bbbbb.."],
}
ITEMS = {
    "hoe": ["......iii...", ".....issssi.", "....ihiii...", "...ihwi.....",
            "..ihwi......", ".ihwi.......", "ihwi........", "iwi.........", ".i.........."],
    "watering_can": ["...iii......", "..ibci..ii..", "..ibciiibbi.", "iiibbbbibbbi",
                     "ibbccccibbbi", ".ibbbbbibbi.", "..ibbbiiii..", "..iiii......",
                     "............", ".....b......", "......b....."],
    "seed_greens": ["..iiiiiii...", "..icpppci...", "..idwwwdi...", ".ihhhhhhhi..",
                    ".ihppppphi..", ".ihppgpphi..", ".ihpggpphi..", ".ihppGpphi..",
                    ".ihppppphi..", ".ihwwwwwdi..", "..iiiiiii..."],
    "crop_greens": ["..iii.......", ".igggi..ii..", "igcggiiiggi.", "igggGiggggGi",
                    ".iGggggcggGi", ".iggGggggGii", "..iGGgggGi..", "...icpGGi...",
                    "...icppi....", "....iii....."],
    "stone": [".....iii....", "....isssi...", "..iisssssi..", ".isssspsssi.",
              "issspssswssi", "isssssswwdsi", ".iisssdddsi.", "...iiiiiii.."],
    "wood": ["...iiiii....", "..ihwwhii...", ".ihwwwdwpi..", "ihhwwdwphwi.",
             "ihhwddwphhwi", ".iwdwphdhhwi", "..iwwphhhwi.", "...iiiiiii.."],
}

def save_json(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

def forge(skill, script, *args):
    command = [sys.executable, str(SKILLS / skill / "scripts" / script), *map(str, args)]
    subprocess.run(command, cwd=ROOT, check=True)

def panel_rows(kind, edge="i"):
    rows = []
    for y in range(9):
        row = ""
        for x in range(9):
            if x in (0, 8) and y in (0, 8):
                color = "."
            elif x in (0, 8) or y in (0, 8):
                color = edge
            elif kind == "paper":
                color = "w" if x in (1, 7) or y in (1, 7) else "p"
            elif kind == "slot":
                color = "d" if min(x, y) == 1 else "h" if max(x, y) == 7 else "a"
            elif kind == "pressed":
                color = "d"
            elif kind == "disabled":
                color = "u"
            elif kind == "hover":
                color = "h" if max(x, y) < 7 else "d"
            elif kind == "tab" and x >= 6 and 1 < y < 7:
                color = "p"
            else:
                color = "h" if min(x, y) == 1 else "d" if max(x, y) == 7 else "t"
            row += color
        rows.append(row)
    return rows

def pixel_asset(name, size, frames, workspace, destination="ui"):
    spec_path = ART / "source" / f"{name}.pixelspec.json"
    spec = {
        "schema": "codeart2d.pixelspec.v1", "name": name, "canvas": [size, size],
        "palette": PALETTE, "layers": [{"name": "ink", "rows": ["."]}],
        "frames": [{"name": key, "layers": {"ink": {"rows": rows}}} for key, rows in frames.items()],
    }
    save_json(spec_path, spec)
    output = workspace / name
    forge("codeart2d", "render_pixelspec.py", "--spec", spec_path, "--output-dir", output, "--strict-qc")
    for frame in output.glob("*/frames/*.png"):
        target = ART / destination / frame.name
        if name == "panels":
            # The Forge raster QA expects binary alpha. Apply the spec's intentional material opacity after rendering.
            image = Image.open(frame).convert("RGBA")
            for y, row in enumerate(frames[frame.stem]):
                for x, token in enumerate(row):
                    if token in "atu":
                        alpha = {"a": 102, "t": 230, "u": 128}[token]
                        image.putpixel((x, y), (*image.getpixel((x, y))[:3], alpha))
            image.save(target)
        else:
            shutil.copyfile(frame, target)
    shutil.copyfile(output / "codeart-meta.json", ART / "source" / f"{name}-qa.json")

def terrain(workspace):
    path = ART / "source" / "spring.material.json"
    save_json(path, {
        "schema": "codeart2d.material_spec.v1", "tile_size": 16, "seed": 337, "variants": 8,
        "materials": {
            "grass": {
                "ramp": ["#668748", "#7D9E56", "#91AC61", "#A2B970", "#D6CD86", "#FAE4AB"],
                "texture": {"base": 2, "marks": [{"rows": ["1.1", ".0."], "weight": 3},
                    {"rows": ["33", ".3"], "weight": 5}, {"rows": ["4.", ".1"]},
                    {"rows": [".5.", "541", ".1."], "weight": 0.5}], "marks_per_tile": [1, 3]},
            },
            "dirt": {
                "ramp": ["#99734E", "#B78C60", "#CCA576", "#D8B786"],
                "texture": {"base": 2, "marks": [{"rows": ["1.1"]}, {"rows": ["33"]}], "marks_per_tile": [1, 3]},
                "edge": {"colors": [0, 1], "against": ["grass"]},
            },
        },
        "sets": [{"id": "spring-ground", "kind": "wang_corner", "materials": ["grass", "dirt"], "wobble": 0.4}],
    })
    output = workspace / "terrain"
    forge("codeart2d", "autotile_build.py", "--material-spec", path, "--output-dir", output, "--strict-qc")
    manifest = next(output.rglob("*.tileset.json"))
    data = json.loads(manifest.read_text(encoding="utf-8"))
    shutil.copyfile(manifest, ART / "farm" / "spring-ground.tileset.json")
    shutil.copyfile(manifest.parent / data["image"], ART / "farm" / data["image"])
    shutil.copyfile(output / "autotile-qa.json", ART / "source" / "terrain-qa.json")

def main():
    with tempfile.TemporaryDirectory(prefix="forge-", dir=ROOT) as temporary:
        workspace = Path(temporary)
        (workspace / ".gdignore").touch()
        panels = {f"panel_{kind}": panel_rows(kind) for kind in ("wood", "paper", "slot", "tab", "pressed", "disabled", "hover")}
        panels.update({"panel_focus": panel_rows("wood", "y"), "panel_warning": panel_rows("wood", "r")})
        pixel_asset("panels", 9, panels, workspace)
        pixel_asset("icons", 8, ICONS, workspace)
        (ART / "items").mkdir(exist_ok=True)
        pixel_asset("items", 16, {key: [""] * 2 + [".." + row for row in rows]
                                  for key, rows in ITEMS.items()}, workspace, "items")
        terrain(workspace)

if __name__ == "__main__":
    main()
