#!/usr/bin/env bash
# Generate Root.AICLI launcher icons at all densities using Python + PIL.
# Re-runs every build; idempotent.
set -euo pipefail
RES=${1:?usage: make-icon.sh <res-dir>}

python3 - "$RES" <<'PYEOF'
import sys, os
from PIL import Image, ImageDraw, ImageFont

res = sys.argv[1]
densities = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}

# Deep indigo background, electric-blue glyph "R.A" stylized
BG = (16, 24, 48, 255)        # near-black with blue tint
FG = (59, 130, 246, 255)      # accent blue
DOT = (245, 158, 11, 255)     # accent orange dot

def make(size):
    img = Image.new("RGBA", (size, size), BG)
    d = ImageDraw.Draw(img)
    # rounded square
    r = int(size * 0.22)
    d.rounded_rectangle([(0, 0), (size, size)], r, fill=BG)
    # central "R" glyph (bold sans-ish via PIL default; works without bundling a font)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(size * 0.55))
    except Exception:
        font = ImageFont.load_default()
    text = "R"
    bbox = d.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - w) // 2 - bbox[0], (size - h) // 2 - bbox[1] - int(size * 0.04)),
           text, fill=FG, font=font)
    # accent dot lower-right
    rd = int(size * 0.10)
    cx, cy = int(size * 0.74), int(size * 0.74)
    d.ellipse([cx - rd, cy - rd, cx + rd, cy + rd], fill=DOT)
    return img

for dirname, size in densities.items():
    d = os.path.join(res, dirname)
    os.makedirs(d, exist_ok=True)
    out = os.path.join(d, "ic_launcher.png")
    make(size).save(out, "PNG", optimize=True)
    print(f"  {dirname}/ic_launcher.png ({size}x{size})")

print("icons generated.")
PYEOF
