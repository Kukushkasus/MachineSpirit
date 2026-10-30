#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Check text/background pairs of a generated colors.json against WCAG contrast.

  contrast_check.py [colors.json]     exit code 1 if any pair fails
"""
import json, sys

PAIRS = [   # (foreground, background, minimum, what)
    ("glow", "glass", 7.0, "text on cogitator screens"),
    ("glow_dim", "glass", 4.5, "secondary text on screens"),
    ("on_surface", "surface_container", 4.5, "body text on panels"),
    ("on_surface_variant", "surface_container", 4.5, "labels on panels"),
    ("on_surface", "metal", 4.5, "text on metal frames"),
    ("brass_hi", "metal", 3.0, "brass details on metal"),
    ("on_primary", "primary", 4.5, "text on accent"),
    ("primary", "surface_container", 3.0, "accent on panels"),
]


def lum(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


path = sys.argv[1] if len(sys.argv) > 1 else __import__("os").path.expanduser("~/.local/state/machinespirit/colors.json")
c = json.load(open(path))
bad = 0
for fg, bg, need, what in PAIRS:
    if fg not in c or bg not in c:
        print(f"  ?    {what}: missing {fg}/{bg}"); bad += 1; continue
    r = ratio(c[fg], c[bg])
    ok = r >= need
    bad += not ok
    print(f"  {'ok ' if ok else 'BAD'}  {r:5.2f} >= {need:<4} {what} ({fg} on {bg})")
sys.exit(1 if bad else 0)
