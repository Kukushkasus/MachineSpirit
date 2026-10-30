#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Emblem of the Machine Spirit for fastfetch and the README (original vector art), drawn like the shell:
a phosphor line drawing on a cogitator screen. A dial of ticks, a hollow cog, and inside it a hooded
tech-priest whose three optics burn red. Soft bloom and scanlines; transparent background.

  make_emblem.py OUT.svg [--glow HEX --dim HEX --faint HEX --eye HEX]
"""
import argparse, math

p = argparse.ArgumentParser()
p.add_argument("out")
p.add_argument("--glow", default="#b8f5a0")
p.add_argument("--dim", default="#7cc56a")
p.add_argument("--faint", default="#2f5a28")
p.add_argument("--eye", default="#ff4a32")
a = p.parse_args()
f = lambda v: f"{v:.2f}"
CX = CY = 200


def cog(r_out, r_root, teeth):
    pts, pitch = [], 2 * math.pi / teeth
    for i in range(teeth):
        b = i * pitch - math.pi / 2
        for fr, r in ((-0.31, r_root), (-0.19, r_out), (0.19, r_out), (0.31, r_root)):
            pts.append((CX + r * math.cos(b + fr * pitch), CY + r * math.sin(b + fr * pitch)))
    return "M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + " Z"


ticks = []
for i in range(60):
    ang = i / 60 * 2 * math.pi
    r1, r2 = (170, 186) if i % 5 == 0 else (176, 184)
    ticks.append(f'<line x1="{f(CX + r1 * math.cos(ang))}" y1="{f(CY + r1 * math.sin(ang))}" '
                 f'x2="{f(CX + r2 * math.cos(ang))}" y2="{f(CY + r2 * math.sin(ang))}"/>')

# hooded tech-priest: a pointed hood, the dark of the face, a collar of cables
hood = ("M200 86 C228 104 246 140 248 186 C249 206 252 220 262 228 "
        "C276 236 284 248 286 262 L114 262 C116 248 124 236 138 228 "
        "C148 220 151 206 152 186 C154 140 172 104 200 86 Z")
face = ("M200 150 C222 162 234 184 234 206 C234 226 222 242 200 246 "
        "C178 242 166 226 166 206 C166 184 178 162 200 150 Z")
collar = "M138 228 C170 244 230 244 262 228"
cables = "M176 262 C174 280 182 290 188 300 M224 262 C226 280 218 290 212 300 M200 244 L200 302"
eyes = [(186, 200, 7), (214, 200, 7), (200, 222, 5)]

art = f'''
  <g fill="none" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="{CX}" cy="{CY}" r="190" stroke="{a.faint}" stroke-width="2"/>
    <g stroke="{a.dim}" stroke-width="3">{"".join(ticks)}</g>
    <path d="{cog(158, 134, 12)}" stroke="{a.glow}" stroke-width="7" fill="{a.glow}" fill-opacity="0.06"/>
    <circle cx="{CX}" cy="{CY}" r="118" stroke="{a.dim}" stroke-width="3"/>
    <path d="{hood}" stroke="{a.glow}" stroke-width="7" fill="{a.glow}" fill-opacity="0.08"/>
    <path d="{face}" stroke="{a.dim}" stroke-width="3" fill="#000" fill-opacity="0.55"/>
    <path d="{collar}" stroke="{a.glow}" stroke-width="5"/>
    <path d="{cables}" stroke="{a.dim}" stroke-width="4"/>
  </g>
  <g fill="{a.eye}">{"".join(f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in eyes)}</g>'''

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">
  <defs>
    <filter id="bloom" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="7"/></filter>
    <pattern id="scan" width="4" height="6" patternUnits="userSpaceOnUse">
      <rect width="4" height="6" fill="#fff"/><rect y="4" width="4" height="2" fill="#000" fill-opacity="0.45"/>
    </pattern>
    <mask id="lines"><rect width="400" height="400" fill="url(#scan)"/></mask>
  </defs>
  <g opacity="0.55" filter="url(#bloom)">{art}</g>
  <g mask="url(#lines)">{art}</g>
  <g opacity="0.9" filter="url(#bloom)" fill="{a.eye}">{"".join(f'<circle cx="{x}" cy="{y}" r="{r + 4}"/>' for x, y, r in eyes)}</g>
</svg>
'''
open(a.out, "w").write(svg)
