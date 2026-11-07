"""Draw the Vietnamese bitmap font and build the shared Godot 9-slice theme."""
from __future__ import annotations

from pathlib import Path
import unicodedata

from PIL import Image

from build_sao_mai_kit import ART

UI = ART / "ui"
# Five rows per letter. The first two atlas rows are reserved for Vietnamese marks.
CAPS = {
    "A":"01110/10001/11111/10001/10001", "B":"11110/10001/11110/10001/11110",
    "C":"01111/10000/10000/10000/01111", "D":"11110/10001/10001/10001/11110",
    "E":"11111/10000/11110/10000/11111", "F":"11111/10000/11110/10000/10000",
    "G":"01111/10000/10111/10001/01111", "H":"10001/10001/11111/10001/10001",
    "I":"111/010/010/010/111", "J":"00111/00010/00010/10010/01100",
    "K":"10001/10010/11100/10010/10001", "L":"10000/10000/10000/10000/11111",
    "M":"10001/11011/10101/10001/10001", "N":"10001/11001/10101/10011/10001",
    "O":"01110/10001/10001/10001/01110", "P":"11110/10001/11110/10000/10000",
    "Q":"01110/10001/10001/10011/01111", "R":"11110/10001/11110/10010/10001",
    "S":"01111/10000/01110/00001/11110", "T":"11111/00100/00100/00100/00100",
    "U":"10001/10001/10001/10001/01110", "V":"10001/10001/10001/01010/00100",
    "W":"10001/10001/10101/11011/10001", "X":"10001/01010/00100/01010/10001",
    "Y":"10001/01010/00100/00100/00100", "Z":"11111/00010/00100/01000/11111",
    "Đ":"01110/01001/11101/01001/01110",
}
LOWER = {
    "a":"0000/0110/0001/0111/0111", "b":"1000/1000/1110/1001/1110",
    "c":"0000/0111/1000/1000/0111", "d":"0001/0001/0111/1001/0111",
    "e":"0000/0110/1001/1110/0111", "f":"001/010/111/010/010",
    "g":"0000/0111/1001/0111/0001/1110", "h":"1000/1000/1110/1001/1001",
    "i":"1/0/1/1/1", "j":"01/00/01/01/01/10", "k":"1000/1001/1010/1100/1011",
    "l":"10/10/10/10/01", "m":"00000/11010/10101/10101/10101", "n":"0000/1110/1001/1001/1001",
    "o":"0000/0110/1001/1001/0110", "p":"0000/1110/1001/1110/1000/1000",
    "q":"0000/0111/1001/0111/0001/0001", "r":"000/101/110/100/100",
    "s":"0000/0111/1100/0011/1110", "t":"010/111/010/010/001",
    "u":"0000/1001/1001/1001/0111", "v":"000/101/101/101/010",
    "w":"00000/10001/10101/10101/01010", "x":"000/101/010/010/101",
    "y":"0000/1001/1001/0111/0001/1110", "z":"0000/1111/0010/0100/1111",
    "đ":"0010/0111/0010/0110/1010/0111",
}
DIGITS = {
    "0":"01110/10001/10011/10101/11001/10001/01110", "1":"010/110/010/010/010/010/111",
    "2":"01110/10001/00001/00010/00100/01000/11111", "3":"11110/00001/00001/01110/00001/00001/11110",
    "4":"00010/00110/01010/10010/11111/00010/00010", "5":"11111/10000/10000/11110/00001/00001/11110",
    "6":"01110/10000/10000/11110/10001/10001/01110", "7":"11111/00001/00010/00100/01000/01000/01000",
    "8":"01110/10001/10001/01110/10001/10001/01110", "9":"01110/10001/10001/01111/00001/00001/01110",
}
SIGNS = {
    " ":"000/000/000/000/000", "!":"1/1/1/0/1", "?":"110/001/010/000/010",
    ".":"0/0/0/0/1", ",":"00/00/00/00/01/10", ":":"0/1/0/1/0", ";":"00/01/00/01/10",
    "/":"001/001/010/100/100", "-":"000/000/111/000/000",
    "−":"000/000/111/000/000", "+":"000/010/111/010/000", "=":"000/111/000/111/000",
    "·":"0/0/1/0/0", "…":"00000/00000/00000/00000/10101", "×":"000/101/010/101/000",
    "’":"1/1/0/0/0", "'":"1/1/0/0/0", "\"":"101/101/000/000/000",
    "(":"01/10/10/10/01", ")":"10/01/01/01/10", "%":"11001/11010/00100/01011/10011",
    "°":"111/101/111/000/000", "✓":"00001/00010/10100/01000/00000",
    "→":"00100/00010/11111/00010/00100", "←":"00100/01000/11111/01000/00100",
    "↑":"00100/01110/10101/00100/00100", "↓":"00100/00100/10101/01110/00100",
    "★":"00100/11111/01110/01010/10001", "☆":"00100/11011/01010/01010/10001",
    "–":"0000/0000/1111/0000/0000", "—":"00000/00000/11111/00000/00000",
}
TONES = {"\u0300":"100/010", "\u0301":"001/010", "\u0303":"011/110", "\u0309":"011/001"}
SHAPES = {"\u0302":"010/101", "\u0306":"101/010", "\u031b":"001/011"}

def draw_glyph(char, numbers):
    base, *accents = unicodedata.normalize("NFD", char)
    source = CAPS | LOWER | SIGNS | DIGITS
    rows = source.get(base, source["?"]).split("/")
    digit = char in DIGITS
    if digit and not numbers:
        rows = [rows[i] for i in (0, 1, 3, 5, 6)]
    marks = [(mark, TONES.get(mark) or SHAPES.get(mark)) for mark in accents if mark != "\u0323"]
    width = max(max(map(len, rows)), 5 if len(marks) == 2 else 3 if marks else 1)
    glyph = Image.new("RGBA", (width, 7 if numbers else 8))
    left = (width - len(rows[0])) // 2
    top = 0 if numbers else 2
    for y, row in enumerate(rows):
        for x, pixel in enumerate(row):
            if pixel == "1" and y + top < glyph.height:
                glyph.putpixel((x + left, y + top), (255, 255, 255, 255))
    for mark, pattern in marks:
        if pattern is None:
            continue
        if base == "i":
            glyph.putpixel((left, 2), (0, 0, 0, 0))
        if len(marks) == 2 and mark in TONES:
            continue
        left_mark = 0 if len(marks) == 2 else (width - 3) // 2
        for y, row in enumerate(pattern.split("/")):
            for x, pixel in enumerate(row):
                if pixel == "1":
                    glyph.putpixel((x + left_mark, y), (255, 255, 255, 255))
    if len(marks) == 2:
        # A distinct two-column mark fits beside the vowel shape in the two accent rows.
        tone = next((mark for mark, _ in marks if mark in TONES), "")
        tone_dots = {"\u0300": [(3, 0), (4, 1)], "\u0301": [(4, 0), (3, 1)],
                     "\u0303": [(3, 0), (4, 0), (3, 1)], "\u0309": [(3, 0), (4, 0), (4, 1)]}
        for point in tone_dots.get(tone, []):
            glyph.putpixel(point, (255, 255, 255, 255))
    if "\u0323" in accents:
        glyph.putpixel((width // 2, glyph.height - 1), (255, 255, 255, 255))
    return glyph

def write_font(name, size, line, numbers=False):
    letters = set(DIGITS | SIGNS) if numbers else set(CAPS | LOWER | DIGITS | SIGNS)
    if not numbers:
        letters.update(chr(code) for code in [*range(0x00C0, 0x0100), 0x0102, 0x0103, 0x0128, 0x0129,
                                             0x0168, 0x0169, 0x01A0, 0x01A1, 0x01AF, 0x01B0,
                                             *range(0x1EA0, 0x1EFA)]
                       if unicodedata.normalize("NFD", chr(code))[0] in (CAPS | LOWER))
    letters = sorted(letters)
    side = size + 4
    atlas = Image.new("RGBA", (16 * side, ((len(letters) + 15) // 16) * side))
    items = []
    for i, char in enumerate(letters):
        glyph = draw_glyph(char, numbers)
        width = round(glyph.width * size / glyph.height)
        glyph = glyph.resize((width, size), Image.Resampling.NEAREST)
        x, y = (i % 16) * side + 1, (i // 16) * side + 1
        atlas.paste(glyph, (x, y))
        items.append(f"char id={ord(char)} x={x} y={y} width={width} height={size} xoffset=0 "
                     f"yoffset={(line - size) // 2} xadvance={width + 1} page=0 chnl=15")
    atlas.save(UI / f"{name}.png")
    lines = [
        f'info face="Sao Mai" size={size} bold=0 italic=0 unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,0',
        f"common lineHeight={line} base={size} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0",
        f'page id=0 file="{name}.png"', f"chars count={len(items)}", *items,
    ]
    (UI / f"{name}.fnt").write_text("\n".join(lines) + "\n", encoding="utf-8")

def write_theme():
    styles = ["wood", "paper", "slot", "tab", "focus", "warning", "pressed", "disabled", "hover"]
    lines = [f'[gd_resource type="Theme" load_steps={len(styles) * 2 + 2} format=3]', "",
             '[ext_resource type="FontFile" path="res://assets/art/sao_mai/ui/sao-mai-8.fnt" id="font"]']
    for style in styles:
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/art/sao_mai/ui/panel_{style}.png" id="tex_{style}"]')
    for style in styles:
        lines.extend(["", f'[sub_resource type="StyleBoxTexture" id="{style}"]',
                      f'texture = ExtResource("tex_{style}")'])
        for side in ("left", "top", "right", "bottom"):
            lines.append(f"texture_margin_{side} = 3.0")
            lines.append(f"content_margin_{side} = 2.0")
        if style == "pressed":
            lines.extend(["content_margin_top = 3.0", "content_margin_bottom = 1.0"])
    lines.extend(["", "[resource]", 'default_font = ExtResource("font")', "default_font_size = 8"])
    styles_by_control = {
        "PanelContainer": {"panel": "wood"},
        "WoodPanel": {"panel": "wood"}, "PaperPanel": {"panel": "paper"},
        "SlotPanel": {"panel": "slot"}, "TabPanel": {"panel": "tab"},
        "Button": {"normal":"wood", "hover":"hover", "focus":"focus", "pressed":"pressed", "disabled":"disabled"},
        "AlertButton": {"focus":"warning"},
        "LineEdit": {"normal":"paper", "focus":"focus", "read_only":"disabled"},
        "ProgressBar": {"background":"slot", "fill":"focus"},
    }
    for name in ("WoodPanel", "PaperPanel", "SlotPanel", "TabPanel"):
        lines.append(f'{name}/base_type = &"Panel"')
    lines.append('AlertButton/base_type = &"Button"')
    for control, states in styles_by_control.items():
        for state, style in states.items():
            lines.append(f'{control}/styles/{state} = SubResource("{style}")')
    lines.extend(["Button/colors/font_color = Color(1, 0.965, 0.855, 1)",
                  "Button/colors/font_focus_color = Color(1, 0.965, 0.855, 1)",
                  "Button/colors/font_disabled_color = Color(0.78, 0.76, 0.71, 1)",
                  "LineEdit/colors/font_color = Color(0.169, 0.106, 0.090, 1)"])
    (UI / "ui_theme.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")

if __name__ == "__main__":
    for pixels, line_height in ((8, 12), (10, 14), (12, 16)):
        write_font(f"sao-mai-{pixels}", pixels, line_height)
    write_font("sao-mai-digits", 7, 7, numbers=True)
    write_theme()
