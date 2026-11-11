# [ PURITY SEAL ] Original scene. The war forge.
"""Khorne wallpaper: a war forge. Massive iron girders and riveted columns frame a great furnace mouth burning
crimson at the centre; heavy chains hang in the foreground and across the hall; brass bands and a quenching
trough catch the fire; smoke rolls under the roof and embers rise. Grim and heavy, no emblems."""
import math, os, random, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

reset(47)
iron = metal("iron", (0.03, 0.027, 0.026), rough=0.72, scuff=0.65, scale=3)
black = metal("black", (0.02, 0.018, 0.017), rough=0.85, scuff=0.35, scale=2, metallic=0.7)
brass = metal("brass", (0.42, 0.27, 0.1), rough=0.4, scuff=0.6, scale=4)
chainm = metal("chain", (0.12, 0.1, 0.09), rough=0.45, scuff=0.5, scale=8)
fire = glow("fire", (1.0, 0.04, 0.01), 6)
fire_hot = glow("hot", (1.0, 0.12, 0.02), 4)

# floor: heavy plates, scorched
for i in range(-4, 5):
    for j in range(0, 10):
        box((i * 4.2, j * 4.2 - 8, -0.3), (4.1, 4.1, 0.6), iron if (i + j) % 2 else black, bevel=0.05)
# side walls of black iron with deep ribs
for side in (-1, 1):
    box((side * 15, 12, 11), (1, 48, 24), black)
    for j in range(7):
        box((side * 14, j * 6 - 4, 11), (1.5, 1.2, 24), black, bevel=0.06)
# columns: square iron piers with brass bands and rivet rows, girders spanning between them
for side in (-1, 1):
    for j in range(4):
        x, y = side * 8.5, j * 7 - 2
        box((x, y, 10), (2.2, 2.2, 20), black, bevel=0.08)
        for k in range(4):   # sunk panels down the inner face, catching the fire only at their edges
            box((x - side * 1.08, y, 3.6 + k * 4.4), (0.08, 1.5, 3.4), iron, bevel=0.03)
        for z in (1.0, 6.5, 12.0, 17.5):
            box((x, y, z), (2.4, 2.4, 0.22), brass, bevel=0.03)
            for k in range(-2, 3):
                sphere((x - side * 1.27, y + k * 0.42, z + 0.4), 0.07, brass)
for j in range(4):
    box((0, j * 7 - 2, 19.4), (19, 1.4, 1.8), iron, bevel=0.06)          # cross girders
    box((0, j * 7 - 2, 18.4), (19, 0.5, 0.25), brass)
for side in (-1, 1):
    box((side * 8.5, 9, 19.4), (1.4, 24, 1.8), iron, bevel=0.06)          # long girders

# the furnace: a great mouth in the end wall, framed in brass, fire inside, a hood above
Y = 24
box((0, Y + 3.2, 11), (30, 2, 24), black)
for x in (-7.6, 7.6):   # the furnace's cheeks, so its mouth has depth
    box((x, Y + 1.2, 11), (2.4, 2.4, 24), black)
box((0, Y + 1.2, 13.6), (13, 2.4, 13), black)
box((0, Y - 0.2, 7.0), (13.6, 0.6, 1.0), brass, bevel=0.06)
box((0, Y - 0.2, 0.4), (13.6, 0.6, 0.8), brass, bevel=0.06)
for x in (-6.5, 6.5):
    box((x, Y - 0.2, 3.7), (1.0, 0.6, 7.4), brass, bevel=0.06)
box((0, Y + 2.0, 3.7), (12, 0.2, 6.2), fire)
sphere((0, Y + 1.7, 2.4), 1.5, fire_hot)
box((0, Y + 1.2, 0.5), (12, 1.6, 1.0), glow("coals", (1.0, 0.1, 0.02), 3))
for k in range(11):   # grate bars over the fire
    box((-5.0 + k * 1.0, Y - 0.1, 3.7), (0.26, 0.3, 6.4), black)
for k in (2.2, 4.8):
    box((0, Y - 0.1, k), (12, 0.3, 0.22), black)
cone((0, Y - 1.5, 13.5), 10, 3, 6, iron, verts=4, rot=(0, 0, math.pi / 4))     # the hood
box((0, Y - 0.5, 18.5), (3, 3, 6), iron, bevel=0.1)                           # the flue
# an anvil and a quenching trough before the furnace
box((-3.8, 13, 0.9), (2.6, 1.2, 1.8), iron, bevel=0.1)
box((-3.8, 13, 2.0), (4.2, 1.6, 0.5), black, bevel=0.15)
box((5, 15, 0.6), (3.2, 1.6, 1.2), brass, bevel=0.06)
box((5, 15, 1.15), (2.8, 1.2, 0.05), fire)

# chains: two great ones hanging close to the camera, more across the hall
for side, x in ((-1, -7.0), (1, 7.4)):
    chain([(x, -2.5, 19), (x + side * 0.3, -2.6, 6.5)], 0.22, chainm)
for j, sag in ((3, 5.0), (10, 4.2)):
    chain(catenary((-8.5, j, 17), (8.5, j, 17), sag, 30), 0.26, chainm)
chain(catenary((-8.5, 19, 15), (0, 21, 17.5), 2.0, 20), 0.18, chainm)
# hooks hanging from the cross chains
for x in (-2, 3):
    chain([(x, 12, 14.2), (x, 12, 9.5)], 0.16, chainm)

# light: the furnace, a hot glow on the floor, a dim cold fill from above, embers rising
light("AREA", (0, Y - 1.2, 3.5), 2600, (1.0, 0.07, 0.02), size=10, rot=(math.radians(-90), 0, 0))
light("POINT", (0, 18, 3), 500, (1.0, 0.1, 0.03), size=3)
light("SPOT", (-10, -8, 18), 7000, (0.45, 0.5, 0.62), size=0.5, rot=(math.radians(45), math.radians(-25), 0), spot=math.radians(45))
scatter(90, ((-6, 6), (12, 23)), (0.5, 16), 0.02, [glow("ember", (1.0, 0.3, 0.05), 40), glow("ember2", (1.0, 0.15, 0.03), 30)])
room_haze((28, 44, 22), (0, 10, 11), haze("smoke", (0.55, 0.45, 0.45), density=0.012, anisotropy=0.4, noise=1.2))

light("AREA", (6, -6, 20), 900, (0.5, 0.6, 0.8), size=6, rot=(math.radians(30), math.radians(20), 0))   # a cold rim on the iron
camera((1.0, -14, 4.2), (0, 24, 5.6), lens=26, shift=(0, 0.04))
render()
