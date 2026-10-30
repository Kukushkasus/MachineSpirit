#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Render the small textures the shell uses: the spark, a streak for fast sparks and the anode-mesh tile.

White with alpha; the shell tints them. Run from the repo root:
    python3 tools/make_fx.py
"""
import numpy as np
from PIL import Image

OUT = "quickshell/assets"
def spark():
    # hot core with a soft halo, 16x16
    n = 16
    y, x = np.mgrid[0:n, 0:n] - (n - 1) / 2
    r = np.sqrt(x * x + y * y) / (n / 2)
    a = np.clip(np.exp(-r * r * 9) + 0.35 * np.exp(-r * r * 2.2), 0, 1)
    rgba = np.zeros((n, n, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = (a * 255).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(f"{OUT}/spark.png", optimize=True)


def mesh():
    # 8x8 tile with one lit dot: a nixie anode mesh as one tiled image instead of hundreds of items
    t = np.zeros((8, 8, 4), np.uint8)
    t[4, 4] = (255, 255, 255, 255)
    Image.fromarray(t, "RGBA").save(f"{OUT}/mesh.png", optimize=True)


if __name__ == "__main__":
    spark()
    mesh()
