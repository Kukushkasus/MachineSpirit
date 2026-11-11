# [ PURITY SEAL ] Original scene. The machine temple.
"""Adeptus Mechanicus wallpaper: a forge-temple hall. Two rows of machine columns run into haze toward an altar
of cogs with a red core; cables sag between the columns, red lamps burn on them, light falls in shafts from
high windows. The left top and the right side stay dark for the shell's instruments and panels."""
import math, os, random, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

reset(11)
iron = metal("iron", (0.07, 0.065, 0.06), rough=0.55, scuff=0.6, scale=3)
dark = metal("dark", (0.03, 0.03, 0.03), rough=0.7, scuff=0.3, scale=2)
brass = metal("brass", (0.62, 0.42, 0.16), rough=0.3, scuff=0.5, scale=5)
copper = metal("copper", (0.55, 0.25, 0.12), rough=0.35, scuff=0.4)
rubber = metal("rubber", (0.02, 0.02, 0.02), rough=0.8, scuff=0.1, metallic=0)
red = glow("red", (1.0, 0.1, 0.03), 5)
core = glow("core", (0.85, 0.07, 0.02), 2.6)
amber = glow("amber", (1.0, 0.55, 0.15), 10)

# floor of plates, and the ceiling dark above
for i in range(-3, 4):
    for j in range(0, 12):
        box((i * 4.1, j * 4.1 - 10, -0.25), (4, 4, 0.5), iron if (i + j) % 3 else dark, bevel=0.04)
box((0, 14, 22), (40, 60, 1), dark)
# the side walls, buttressed
for side in (-1, 1):
    box((side * 15, 14, 10), (1, 60, 22), dark)
    for j in range(7):
        box((side * 13.6, j * 6 - 6, 10), (1.6, 1.6, 22), iron, bevel=0.1)

for side in (-1, 1):
    for k in range(4):
        cyl((side * (14.2 - k * 0.0), 14, 2 + k * 1.1), 0.22 + 0.05 * (k % 2), 60, copper if k % 2 else iron, rot=(math.pi / 2, 0, 0))
# machine columns: a shaft, brass rings, a collar of teeth, a red lamp
for side in (-1, 1):
    for j in range(6):
        y = j * 6 - 2; x = side * 7.5
        cyl((x, y, 9), 1.0, 18, iron, verts=40)
        for k in range(8):   # fluting: ribs round the shaft
            a = k / 8 * math.tau
            box((x + math.cos(a) * 1.02, y + math.sin(a) * 1.02, 9), (0.16, 0.16, 17), dark, rot=(0, 0, a))
        for z in (0.6, 3.5, 13.5, 17.4):
            cyl((x, y, z), 1.25, 0.35, brass, verts=40)
        gear((x, y, 8), 1.7, 18, 0.5, brass, rot=(0, 0, random.uniform(0, 1)))
        box((x - side * 1.12, y, 4.6), (0.08, 0.4, 0.7), red)
        for k in range(3):
            cyl((x - side * 1.05, y - 0.6 + k * 0.6, 11), 0.12, 2.5, copper)

# cables sagging between the columns and from the ceiling
for side in (-1, 1):
    for j in range(5):
        for h, sag, r in ((15.5, 2.4, 0.09), (14.6, 3.2, 0.13), (16.2, 1.6, 0.07)):
            cable(catenary((side * 7.5, j * 6 - 2, h), (side * 7.5, j * 6 + 4, h), sag), r, rubber)
    for j in range(4):
        cable(catenary((side * 7.5, j * 6 + 1, 16), (side * 0.8, j * 6 + 7, 21.5), 3.0), 0.1, rubber)

# the altar: a great cog with a red core, lesser cogs round it, steps up to it
gear((0, 33, 9), 6.2, 40, 1.2, brass, rot=(math.pi / 2, 0, 0))
cyl((0, 33.9, 9), 4.5, 0.3, dark, rot=(math.pi / 2, 0, 0))
# the core: a red furnace glimpsed through a grille, brightest at its heart
cyl((0, 34.2, 9), 4.3, 0.1, core, rot=(math.pi / 2, 0, 0))
for k in range(-6, 7):
    box((k * 0.62, 33.7, 9), (0.16, 0.2, 8.4 * math.sqrt(max(0, 1 - (k * 0.62 / 4.3) ** 2))), iron)
sphere((0, 34.0, 9), 1.1, glow("heart", (1.0, 0.35, 0.08), 9))
cyl((0, 33.3, 9), 1.6, 1.6, iron, rot=(math.pi / 2, 0, 0))
gear((-8.5, 32.5, 13), 3.0, 22, 0.8, iron, rot=(math.pi / 2, 0, 0.2))
gear((8.2, 32.5, 4.5), 3.4, 24, 0.8, iron, rot=(math.pi / 2, 0, 0.1))
gear((6.5, 32.2, 15.5), 1.8, 14, 0.6, brass, rot=(math.pi / 2, 0, 0.3))
box((0, 36, 10), (30, 1, 22), dark)
for k in range(5):
    box((0, 26 - k * 1.1, k * 0.35 + 0.15), (12 - k * 1.2, 1.1, 0.35), iron, bevel=0.03)
# censers of amber light either side of the steps
for x in (-5, 5):
    cyl((x, 24, 1.2), 0.5, 2.4, brass)
    sphere((x, 24, 2.6), 0.35, amber)

# light: shafts from high windows on the left, the core's glow, a cold fill
# shafts through slits in the vault, falling slightly toward the camera
for j, x in ((0, -2.5), (1, 2.0), (2, -1.0), (3, 1.5)):
    light("SPOT", (x, j * 8 + 2, 21.4), 26000, (1.0, 0.84, 0.66), size=0.15, rot=(math.radians(-14), math.radians(8 if x < 0 else -8), 0), spot=math.radians(9))
# embers drifting up from the altar
scatter(90, ((-6, 6), (18, 31)), (0.3, 9), 0.024, [glow("ember", (1.0, 0.45, 0.1), 40), glow("ember2", (1.0, 0.25, 0.05), 25)])
light("POINT", (0, 30, 9), 4000, (1.0, 0.28, 0.07), size=3)
light("AREA", (0, 10, 20), 900, (0.55, 0.65, 0.9), size=20, rot=(0, 0, 0))
room_haze((30, 56, 22), (0, 14, 11), haze("haze", (0.85, 0.78, 0.7), density=0.022, anisotropy=0.6, noise=0.8))

camera((1.2, -19, 4.2), (0, 30, 7.2), lens=30, shift=(0, 0.04))
render()
