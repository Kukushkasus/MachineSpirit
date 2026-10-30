#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Generate the MachineSpirit vector art (original, no third-party assets).

  make_svg.py OUTDIR     writes gear.svg, gear-hot.svg (the emblem lives in make_emblem.py)
"""
import math, os, sys

TEETH = 10
CANT = "01001111 01101101 01101110 01101001 01110011 01110011 01101001 01100001 01101000"  # "Omnissiah"


def f(v): return f"{v:.3f}".rstrip("0").rstrip(".")


def cog_path(cx, cy, r_out, r_root, teeth, top=0.34, flank=0.09):
    """Closed path of a cog with flat-topped teeth (fractions of one tooth pitch)."""
    pts = []
    pitch = 2 * math.pi / teeth
    for i in range(teeth):
        a = i * pitch - math.pi / 2
        for frac, r in ((0, r_out), (top, r_out), (top + flank, r_root), (1 - flank, r_root)):
            ang = a + frac * pitch
            pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return "M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + " Z"


def circle_path(cx, cy, r):
    return f"M{f(cx - r)} {f(cy)} a{f(r)} {f(r)} 0 1 0 {f(2 * r)} 0 a{f(r)} {f(r)} 0 1 0 {f(-2 * r)} 0 Z"


def gear_svg(light, dark, core):
    body = cog_path(50, 50, 46, 35, TEETH) + " " + circle_path(50, 50, 17)   # evenodd: hub is a hole
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
<defs><linearGradient id="b" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></linearGradient></defs>
<path d="{body}" fill="url(#b)" fill-rule="evenodd"/>
<circle cx="50" cy="50" r="7" fill="{core}"/>
</svg>
'''


def emblem_svg(light="#f0cf7a", dark="#8d6a27"):
    out = []
    # binary ring: each bit is a small arc segment; ones are long bars, zeroes short ticks
    bits = CANT.replace(" ", "")
    n = len(bits)
    for i, b in enumerate(bits):
        a0 = (i / n) * 2 * math.pi - math.pi / 2
        span = (2 * math.pi / n) * (0.62 if b == "1" else 0.28)
        a1 = a0 + span
        r0, r1 = (88, 96) if b == "1" else (90.5, 93.5)
        p = (f"M{f(100 + r0 * math.cos(a0))} {f(100 + r0 * math.sin(a0))} "
             f"L{f(100 + r1 * math.cos(a0))} {f(100 + r1 * math.sin(a0))} "
             f"A{r1} {r1} 0 0 1 {f(100 + r1 * math.cos(a1))} {f(100 + r1 * math.sin(a1))} "
             f"L{f(100 + r0 * math.cos(a1))} {f(100 + r0 * math.sin(a1))} "
             f"A{r0} {r0} 0 0 0 {f(100 + r0 * math.cos(a0))} {f(100 + r0 * math.sin(a0))} Z")
        out.append(p)
    ring = " ".join(out)
    cog = cog_path(100, 100, 80, 64, TEETH) + " " + circle_path(100, 100, 46)
    # hooded skull silhouette inside the hub
    hood = "M100 58 C126 58 140 78 140 102 C140 126 126 142 100 142 C74 142 60 126 60 102 C60 78 74 58 100 58 Z"
    jaw = " ".join(f"M{f(86 + k * 10)} 122 h5 v13 h-5 Z" for k in range(3))
    nose = "M98 104 h4 v10 h-4 Z"
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="512" height="512">
<defs><linearGradient id="b" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></linearGradient></defs>
<path d="{ring}" fill="url(#b)"/>
<path d="{cog}" fill="url(#b)" fill-rule="evenodd"/>
<path d="{hood}" fill="url(#b)"/>
<path d="{jaw} {nose}" fill="#18120c"/>
<circle cx="87" cy="96" r="7.5" fill="#50ff82"/>
<circle cx="113" cy="96" r="10" fill="#ff5238"/>
<circle cx="113" cy="96" r="3.5" fill="#ffd2c8"/>
</svg>
'''


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    open(os.path.join(out, "gear.svg"), "w").write(gear_svg("#f0cf7a", "#8d6a27", "#9a2a1a"))
    open(os.path.join(out, "gear-hot.svg"), "w").write(gear_svg("#ef6a50", "#9a2a1a", "#ffd9a8"))
    open(os.path.join(out, "emblem.svg"), "w").write(emblem_svg())


main()
