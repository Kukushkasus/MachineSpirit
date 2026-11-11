# [ PURITY SEAL ] Original scene. The tomb under the stars.
"""Necrons wallpaper: a plain of black metal under a dead sky. A stepped monolith stands at the centre with a
seam of emerald energy; obelisks flank an avenue toward it, their channels lit; geometric shards hang in the
air above; a low green mist lies on the ground. Cold, exact, inhuman. Shapes are generic geometry."""
import math, os, random, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

reset(31)
black = metal("black", (0.02, 0.025, 0.024), rough=0.25, scuff=0.35, scale=2.5)
gun = metal("gun", (0.06, 0.07, 0.068), rough=0.35, scuff=0.5, scale=4)
green = glow("green", (0.1, 1.0, 0.45), 5)
green_dim = glow("green2", (0.05, 0.8, 0.35), 1.3)
w = bpy.context.scene.world.node_tree.nodes["Background"]; w.inputs[0].default_value = (0.0015, 0.004, 0.004, 1)

# the plain: great tiles, channels of light in a few seams
for i in range(-12, 13):
    for j in range(0, 26):
        box((i * 6.1, j * 6.1 - 6, -0.3), (6, 6, 0.6), black if (i * 7 + j) % 4 else gun, bevel=0.05)
for i in (-1, 1):
    box((i * 3.05, 30, 0.02), (0.08, 72, 0.04), green_dim)
for j in range(0, 10):
    box((0, j * 6.1 - 2.95, 0.02), (6.1, 0.06, 0.04), green_dim)

# the monolith: five stepped tiers, a seam of light up its face, a lit core at the crown
Y = 50
for k in range(5):
    w_ = 38 - k * 6.6; h = 4.4
    box((0, Y, h * k + h / 2), (w_, w_, h), black, bevel=0.2)
    box((0, Y - w_ / 2 - 0.02, h * k + h - 0.3), (w_ * 0.84, 0.06, 0.1), green_dim)
    for sx in (-1, 1):   # glyph-like slots in each tier, lit faintly
        box((sx * w_ * 0.3, Y - w_ / 2 - 0.02, h * k + h * 0.45), (0.25, 0.06, h * 0.45), green_dim)
box((0, Y - 19.05, 11), (0.6, 0.1, 22), green)
box((0, Y, 23.5), (6, 6, 2.6), gun, bevel=0.2)
sphere((0, Y, 27), 1.5, glow("core", (0.2, 1.0, 0.55), 12))
for k in range(3):   # rings of light round the crown
    bpy.ops.mesh.primitive_torus_add(major_radius=3.4 + k * 1.2, minor_radius=0.05, location=(0, Y, 27), rotation=(math.radians(70 + k * 12), 0, math.radians(k * 40)))
    bpy.context.object.data.materials.append(green_dim)

# obelisks down the avenue: tapering shafts with a lit groove, a pyramidion, a small lit shard above each
for side in (-1, 1):
    for j in range(3):
        x, y = side * (12 + j * 0.5), 4 + j * 12
        h = 14 + j * 2
        cone((x, y, h / 2), 1.6, 0.9, h, black, verts=4, rot=(0, 0, math.pi / 4))
        cone((x, y, h + 0.9), 0.9, 0.0, 1.8, gun, verts=4, rot=(0, 0, math.pi / 4))
        box((x - side * 0.8, y - 0.8, h / 2), (0.07, 0.07, h * 0.75), green, rot=(0, 0, math.pi / 4))
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=0, radius=0.35, location=(x, y, h + 3.0)); o = bpy.context.object
        o.scale = (1, 1, 2.2); o.data.materials.append(green)

# shards hanging in the air above the monolith
for k in range(18):
    loc = (random.uniform(-30, 30), random.uniform(30, 80), random.uniform(16, 40))
    s_ = random.uniform(0.6, 2.2)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=0, radius=s_, location=loc, rotation=(random.random() * 3, random.random() * 3, random.random() * 3))
    o = bpy.context.object; o.scale = (1, 1, random.uniform(1.6, 3.2))
    o.data.materials.append(gun)

# a dead sky: faint stars, a pale band low on the horizon
scatter(240, ((-160, 160), (199, 201)), (10, 120), 0.08, [glow("star", (0.7, 0.9, 0.85), 14)])
# (no horizon band: the mist makes the horizon)

light("POINT", (0, 50, 27), 24000, (0.2, 1.0, 0.5), size=2)
light("AREA", (0, 20, 40), 3000, (0.4, 0.7, 0.65), size=40)
light("SPOT", (-30, -10, 30), 40000, (0.5, 0.8, 0.75), size=0.4, rot=(math.radians(55), math.radians(-35), 0), spot=math.radians(35))
# mist on the ground, thicker low
bpy.ops.mesh.primitive_cube_add(location=(0, 60, 4)); m = bpy.context.object; m.scale = (90, 90, 4)
m.data.materials.append(haze("mist", (0.5, 1.0, 0.8), density=0.06, anisotropy=0.3, ground=True))
room_haze((120, 140, 50), (0, 50, 25), haze("air", (0.7, 0.9, 0.9), density=0.0012, anisotropy=0.5))

camera((3, -24, 4.5), (0, 50, 13), lens=28, shift=(0, 0.04))
render()
