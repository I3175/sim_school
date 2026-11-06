"""Build the NPC PNGs and browser manifest from per-character profile.json files."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageColor, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets" / "characters"
FRAME = 32
INK = "#463144"
CREAM = "#fff0c5"
GOLD = "#edbd6b"
BROWN = "#9e6651"
TEAL = "#69b6ac"
ROSE = "#e88783"
STEEL = "#8298aa"

# Width of shoulders, top of head, waist, coat hem, head radius.
BODY = {
    "petite": (10, 8, 22, 26, 6),
    "child": (9, 11, 24, 27, 6),
    "slim": (10, 6, 21, 27, 5),
    "sport": (13, 7, 22, 26, 5),
    "square": (14, 7, 22, 27, 6),
    "broad": (17, 6, 21, 27, 6),
    "tall": (12, 5, 20, 27, 5),
    "elder": (13, 8, 23, 28, 6),
}


def tone(color, amount):
    rgb = ImageColor.getrgb(color)
    target = (255, 241, 205) if amount > 0 else (56, 35, 62)
    return tuple(round(a + (b - a) * abs(amount)) for a, b in zip(rgb, target))


class Pixels:
    def __init__(self, image, scale=1, origin=(0, 0)):
        self.draw = ImageDraw.Draw(image)
        self.scale = scale
        self.origin = origin

    def pos(self, x, y):
        return x * self.scale + self.origin[0], y * self.scale + self.origin[1]

    def box(self, x, y, w, h, color):
        if w <= 0 or h <= 0:
            return
        a, b = self.pos(x, y)
        c, d = self.pos(x + w, y + h)
        self.draw.rectangle((a, b, c - 1, d - 1), fill=color)

    def poly(self, points, color):
        self.draw.polygon([self.pos(x, y) for x, y in points], fill=color)

    def line(self, points, color, width=1):
        self.draw.line([self.pos(x, y) for x, y in points], fill=color, width=width * self.scale)

    def oval(self, x, y, w, h, color, outline=None):
        a, b = self.pos(x, y)
        c, d = self.pos(x + w, y + h)
        self.draw.ellipse((a, b, c - 1, d - 1), fill=color, outline=outline, width=self.scale)


def draw_prop(p, kind, x, y, face):
    """Anchor the prop to a hand or the side of the body."""
    b, o, l = p.box, p.oval, p.line
    if kind in {"journal", "sketch", "lesson", "botany", "books", "notebook", "ledger", "clipboard", "score", "card", "tablet"}:
        colors = {
            "journal": GOLD, "sketch": CREAM, "lesson": "#708e86", "botany": "#729e68",
            "books": "#bd686b", "notebook": "#6c8caa", "ledger": "#6d5146",
            "clipboard": "#b68861", "score": "#a8c491", "card": "#f0af8d", "tablet": STEEL,
        }
        w, h = (5, 4) if kind == "card" else (7, 7)
        b(x, y, w, h, INK)
        b(x + 1, y + 1, w - 2, h - 2, colors[kind])
        b(x + w - 2, y + 2, 1, h - 3, CREAM)
        if kind in {"sketch", "notebook", "clipboard", "score"}:
            b(x + 2, y + 2, 3, 1, BROWN)
            b(x + 2, y + 4, 2, 1, BROWN)
        if kind == "books":
            b(x - 1, y + h - 2, w + 2, 2, "#729e8c")
        return
    if kind in {"ball", "rope", "ring", "float", "cable", "palette"}:
        color = {"ball": "#d88756", "rope": "#e2a44c", "ring": GOLD,
                 "float": "#dc765e", "cable": "#6d6588", "palette": "#c59468"}[kind]
        o(x, y, 8, 8, color, INK)
        if kind in {"rope", "ring", "float", "cable"}:
            o(x + 2, y + 2, 4, 4, INK)
        elif kind == "ball":
            l([(x+2,y+1),(x+4,y+6)], BROWN)
            l([(x+1,y+4),(x+6,y+3)], BROWN)
        else:
            for dx, dy, pigment in [(2,2,ROSE),(4,2,GOLD),(2,4,TEAL)]:
                b(x+dx,y+dy,2,1,pigment)
        return
    if kind in {"rod", "hammer", "wrench", "keys"}:
        if kind == "rod":
            l([(x+1,y+6),(x+7,y-10)], INK, 2)
            l([(x+2,y+4),(x+7,y-10)], GOLD)
            l([(x+7,y-10),(x+7,y-4)], CREAM)
        elif kind == "keys":
            o(x+1,y,5,5,GOLD,INK)
            l([(x+3,y+4),(x+3,y+7),(x+5,y+7)],GOLD)
        else:
            l([(x+2,y+7),(x+5,y+1)], INK, 2)
            l([(x+3,y+6),(x+5,y+2)], GOLD if kind=="hammer" else STEEL)
            b(x+2,y,7 if kind=="hammer" else 5,3,STEEL)
        return
    if kind in {"vial", "honey", "can", "scale", "tray", "aid", "fruit", "glove", "pack", "sling", "seed"}:
        color = {
            "vial": "#79bfce", "honey": "#e7ab4a", "can": "#63999c", "scale": "#70968c",
            "tray": "#d6b190", "aid": "#cb615e", "fruit": "#be8a59", "glove": "#e5b56f",
            "pack": "#7b5c72", "sling": "#d99a9b", "seed": "#c29a76",
        }[kind]
        w, h = (9,4) if kind == "tray" else (4,8) if kind == "vial" else (7,7)
        if kind in {"fruit","aid","pack","can","sling"}:
            o(x+1,y-2,w-2,5,None,INK)
        b(x,y,w,h,INK)
        b(x+1,y+1,w-2,h-2,color)
        b(x+2,y+1,w-3,1,tone(color,.42))
        if kind == "aid":
            b(x+2,y+3,3,1,CREAM)
            b(x+3,y+2,1,3,CREAM)
        if kind == "can":
            l([(x+6,y+4),(x+8,y+2),(x+9,y+2)],TEAL,2)
        if kind == "fruit":
            b(x+1,y,2,2,ROSE)
            b(x+4,y-1,2,2,GOLD)
        if kind in {"tray","scale"}:
            b(x+2,y+1,3,1,CREAM)


def head(p, a, x, y, radius, face, portrait):
    b, q, o = p.box, p.poly, p.oval
    hair, skin, style = a["hairColor"], a["skin"], a["hair"]
    w = 2 * radius + 1
    left, right = x - radius, x + radius
    rear = face == 1
    side = face >= 2
    # Long hair, braids and ponytails change the outside silhouette.
    if style in {"long","partlong","roll","braid","pony","wavy","bob","pigtails","asym"}:
        drop = {"long":16,"partlong":13,"roll":11,"braid":17,"pony":14,
                "wavy":13,"bob":11,"pigtails":11,"asym":10}[style]
        q([(left-1,y+4),(right,y+3),(right+2,y+drop-1),(right-1,y+drop),
           (left-3,y+drop-1),(left-2,y+7)],INK)
        b(left-1,y+5,w+2,drop-5,hair)
        b(left,y+6,2,drop-6,tone(hair,.30))
    if style in {"bun","roll","bow","pigtails","veil","pony"}:
        if style == "pigtails":
            for dx in (-radius-4,radius+1):
                o(x+dx,y+4,5,8,hair,INK)
                b(x+dx+1,y+5,2,1,ROSE)
        else:
            dx, dy = {"bun":(0,-4),"roll":(3,-2),"bow":(-5,-1),
                      "veil":(2,-3),"pony":(-6,2)}[style]
            o(x+dx-2,y+dy,7,7,hair,INK)
            if style == "bow":
                q([(x-9,y-2),(x-4,y),(x-1,y-2),(x-2,y+3),(x-8,y+3)],ROSE)
    # Side profiles have a stepped nose and a visible ear.
    face_points = [(left+3,y),(right-2,y),(right+1,y+3),(right+1,y+7),
                   (right+2 if side else right,y+8),(right-1,y+10),
                   (left+3,y+11),(left,y+8),(left-1,y+4)]
    q(face_points,INK)
    q([(left+3,y+1),(right-2,y+1),(right,y+4),(right,y+7),
       (right+1 if side else right-1,y+8),(right-2,y+9),(left+3,y+10),
       (left+1,y+7),(left,y+4)], hair if rear else skin)
    if not rear:
        b(left+2,y+5,2,3,tone(skin,.28))
        b(right-3,y+8,3,1,tone(skin,-.20))
        b(left+3,y+9,w-6,1,tone(skin,-.16))
    # Fringe variants alter the hairline even at 1x.
    if style in {"spikes","swept","pixie","undercut","crop"}:
        q([(left-1,y+4),(left,y+1),(left+2,y-2),(left+4,y),
           (x+2,y-2),(right-2,y-1),(right,y-3 if style=="swept" else y),
           (right+1,y+3),(x+2,y+3),(left+1,y+6)],hair)
    elif style in {"round","curls","shortcurl","wavy"}:
        o(left,y-1,w,6,hair)
        for dx in range(1,w-2,3):
            o(left+dx,y-1,4,4,tone(hair,.21))
        if style == "round":
            b(left+1,y+3,w-2,2,hair)
    else:
        q([(left,y+5),(left,y+2),(left+3,y),(right-1,y),(right+1,y+3),
           (x+1,y+4),(x-2,y+2),(left+1,y+6)],hair)
    b(left+3,y+1,max(2,w//2),1,tone(hair,.38 if style!="silverpart" else .62))
    if style == "asym":
        q([(left+1,y+2),(x+1,y+1),(x-1,y+7),(left-1,y+8)],hair)
    if not rear:
        eyes = [right-2] if side else [x-3,x+3]
        for eye in eyes:
            b(eye,y+5,1,2,INK)
            if portrait:
                b(eye-1,y+5,1,1,"#fff2dd")
                b(eye-1,y+4,2,1,tone(hair,.2))
        b(right-2 if side else x-1,y+8,2,1,tone(skin,-.36))
        if portrait:
            b(left+2,y+8,2,1,tone(skin,-.22))
            b(right-3,y+8,2,1,tone(skin,-.22))
    if style == "cone":
        q([(left-5,y+3),(x-1,y-5),(x+2,y-5),(right+6,y+3),
           (right+2,y+5),(left-2,y+5)],INK)
        q([(left-3,y+3),(x,y-4),(x+1,y-4),(right+4,y+3)],GOLD)
        p.line([(x,y-3),(x-3,y+2)],CREAM)
    if style in {"straw","cap","helmet","swim","wrap","veil","scarf","band"}:
        color = {"straw":"#d8a85f","cap":"#6c8966","helmet":"#f1c253",
                 "swim":"#4a669b","wrap":"#ede3cc","veil":"#f2d499",
                 "scarf":"#7e9e5d","band":"#f0c78f"}[style]
        if style == "band":
            b(left,y+2,w,2,color)
            b(left-3,y+3,3,2,color)
        elif style in {"helmet","swim","wrap","cap","straw"}:
            o(left-1,y-3,w+2,8,color,INK)
            b(left+3,y-2,3,1,tone(color,.5))
            if style in {"helmet","straw","cap"}:
                b(left-(3 if style=="straw" else 1),y+3,w+(6 if style=="straw" else 2),2,INK)
                b(left-1,y+3,w+2,1,color)
            if style == "helmet":
                b(x,y-2,2,4,tone(color,.55))
        else:
            b(left-1,y+3,w+2,2,color)
            b(left-1,y+4,2,6,color)
            b(right,y+4,2,6,color)
            if style == "veil":
                b(left,y+9,w,1,color)
    if a["prop"] in {"tablet","lesson","card","notebook"} and not rear:
        eyes = [right-4] if side else [x-5,x+1]
        for eye in eyes:
            o(eye,y+4,5,4,None,INK)
        if not side:
            b(x,y+5,2,1,INK)
    if a["prop"] == "vial":
        b(left,y+1,w,2,"#87a6b2")
    if a["prop"] == "cable":
        b(left,y+3,2,5,STEEL)
        b(left-1,y+5,2,3,INK)
    if a["prop"] == "ring" and not rear:
        b(x-3,y+9,7,1,hair)


def body(p, a, x, y, width, waist, hem, face, walk, frame):
    b, q = p.box, p.poly
    cloth = a["cloth"]
    style = a["outfit"]
    narrow = 2 if face >= 2 else 0
    left = x - width//2 + narrow
    right = x + width//2 - narrow
    side = face >= 2
    gait = [-2,0,2,0][frame] if walk else 0
    trousers = "#465163" if style in {"uniform","vest","shirt","sports","lab"} else tone(cloth,-.53)
    for xx, offset in [(x-3,gait),(x+2,-gait)]:
        shoe = 28 if offset else 29
        b(xx-1+offset,hem-1,4,max(2,shoe-hem+1),trousers)
        b(xx-1+offset,shoe,5 if side else 4,2,INK)
        b(xx+offset,shoe,2,1,tone(cloth,.25))
    flare = 3 if style in {"dress","aodai","uniform"} else 1
    q([(left,y+1),(left+3,y),(right-2,y),(right+1,y+2),(right,y+7),
       (right+flare,hem),(left-flare,hem),(left-1,y+6)],INK)
    q([(left+1,y+2),(left+3,y+1),(right-2,y+1),(right,y+3),(right-1,y+7),
       (right+flare-1,hem-1),(left-flare+1,hem-1),(left,y+6)],cloth)
    b(left+1,y+3,2,max(1,hem-y-4),tone(cloth,.23))
    b(right-1,y+3,2,max(1,hem-y-4),tone(cloth,-.29))
    sleeve = CREAM if style in {"uniform","lab"} else tone(cloth,-.16)
    for arm, swing in [(left-2,-gait),(right,gait)]:
        arm_top=y+3+(swing>0)
        b(arm,arm_top,3,5,sleeve)
        b(arm,arm_top+4,3,2,a["skin"])
    if style in {"uniform","lab","shirt","vest","cardigan","rescue","jacket","work","apron","aodai"}:
        if style in {"uniform","shirt","lab","vest","aodai"}:
            q([(x-4,y+1),(x,y+4),(x+4,y+1),(x,y+2)],CREAM)
        if style == "uniform":
            b(x-1,y+3,2,3,TEAL)
            b(left,y+7,right-left,1,"#d9d7b7")
        if style in {"lab","cardigan","jacket","coat","aodai"}:
            b(x,y+4,1,max(1,hem-y-5),tone(cloth,-.35))
        if style in {"apron","work","rescue"}:
            b(left+2,y+5,max(1,right-left-3),3,tone(cloth,.37))
        if style in {"work","vest","apron"}:
            b(x+1,min(hem-2,waist),3,2,tone(cloth,-.27))
    if style in {"sports","shorts","scarf","sweater"}:
        b(left+2,y+4,max(1,right-left-3),1,tone(cloth,.45))
        if style == "scarf":
            b(x-4,y+1,8,2,"#bf7999")
            b(x+2,y+3,2,4,"#bf7999")
    if a["prop"] == "ledger":
        p.line([(left+2,y+2),(x+2,y+6),(right-1,y+8)],"#b9af98",2)
    prop_x = 20 if face != 1 else 5
    prop_y = min(23,hem-5) + (1 if gait > 0 else 0)
    draw_prop(p,a["prop"],prop_x,prop_y,face)


def frame_image(a, face, walk, frame):
    image = Image.new("RGBA",(FRAME,FRAME))
    p=Pixels(image)
    width, top, waist, hem, radius=BODY[a["body"]]
    bob = int((walk and frame%2==1) or (not walk and frame==1))
    x = 16 + (1 if face >= 2 else 0)
    body(p,a,x,top+10+bob,width,waist,hem,face,walk,frame)
    head(p,a,x,top+bob,radius,face,False)
    if face == 3:
        return image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return image


def portrait_image(a):
    image = Image.new("RGBA",(64,64),"#f1d6aa")
    draw = ImageDraw.Draw(image)
    draw.rectangle((1,1,62,62),fill="#e8bf8d",outline="#996a52",width=2)
    draw.ellipse((8,4,56,55),fill="#f5e2bd")
    for xy in [(8,14),(54,10),(56,40),(9,46)]:
        x,y=xy
        draw.line((x-2,y,x+2,y),fill="#fff1cd")
        draw.line((x,y-2,x,y+2),fill="#fff1cd")
    width, _, _, _, radius=BODY[a["body"]]
    # Compose a new bust at portrait scale with a sideward gaze and facial highlights.
    p=Pixels(image,2,(-1,3))
    body(p,a,16,17,max(13,width),24,28,2,False,0)
    head(p,a,16,5,min(8,radius+1),0,True)
    if a["body"] == "elder":
        p.box(10,14,2,1,tone(a["skin"],-.22))
        p.box(20,14,2,1,tone(a["skin"],-.22))
    draw.line((3,59,60,59),fill="#ba8c62",width=2)
    return image


def build(profile_path, profile):
    folder = profile_path.parent.parent
    for child in ("sprites","portraits"):
        (folder / child).mkdir(exist_ok=True)
    appearance=profile["appearance"]
    for name,walk,count in (("walk",True,4),("idle",False,2)):
        sheet=Image.new("RGBA",(FRAME*count,FRAME*4))
        for row in range(4):
            for col in range(count):
                sheet.paste(frame_image(appearance,row,walk,col),(col*FRAME,row*FRAME))
        sheet.save(folder / "sprites" / (name+".png"))
    portrait_image(appearance).save(folder / "portraits" / "default.png")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sample",action="store_true",help="draw the four style samples only")
    args=parser.parse_args()
    catalog=[]
    for map_id in ("school","farm"):
        for path in sorted((CHARACTERS / map_id).glob("*/data/profile.json")):
            p=json.loads(path.read_text(encoding="utf-8-sig"))
            if args.sample and p["id"] not in {"school_mai","school_binh","farmhand_kid","fisher"}:
                continue
            build(path,p)
            catalog.append({key:p[key] for key in ("id","name","scene","tile","dialogue")} | {"map":map_id})
    if not args.sample:
        ids=[p["id"] for p in catalog]
        if len(ids)!=len(set(ids)):
            raise ValueError("Duplicate NPC ids")
        manifest=ROOT/"game"/"npc-catalog.js"
        manifest.write_text("// Generated by draw-npcs.py from assets/characters/*/*/data/profile.json\n"
            "window.NPC_CATALOG = "+json.dumps(catalog,ensure_ascii=False,indent=2)+";\n",encoding="utf-8")
    print(f"Built {len(catalog)} NPC asset folders.")


if __name__ == "__main__":
    main()

