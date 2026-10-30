#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Render an SVG to truecolor half-block ANSI art (for fastfetch). Needs rsvg-convert and Pillow.

  svg_to_ansi.py IN.svg OUT.ansi [COLUMNS]
"""
import subprocess, sys, tempfile
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
cols = int(sys.argv[3]) if len(sys.argv) > 3 else 36
with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
    big = cols * 8   # render large, then downsample: smooth edges
    subprocess.run(["rsvg-convert", "-w", str(big), "-h", str(big), src, "-o", tmp.name], check=True)
    im = Image.open(tmp.name).convert("RGBA").resize((cols, cols), Image.LANCZOS)

def px(x, y):
    r, g, b, a = im.getpixel((x, y))
    return None if a < 90 else (r, g, b)

lines = []
for y in range(0, cols, 2):
    row = ""
    for x in range(cols):
        t, b = px(x, y), px(x, y + 1) if y + 1 < cols else None
        if t is None and b is None: row += " "
        elif b is None: row += "\x1b[38;2;%d;%d;%dm▀\x1b[0m" % t
        elif t is None: row += "\x1b[38;2;%d;%d;%dm▄\x1b[0m" % b
        else: row += "\x1b[38;2;%d;%d;%dm\x1b[48;2;%d;%d;%dm▀\x1b[0m" % (t + b)
    lines.append(row.rstrip())
open(out, "w").write("\n".join(lines) + "\n")
