# [ PURITY SEAL ] Original scene. The bridge.
"""Ultramarines wallpaper: the command bridge of a warship. A deck of blue armour plate with gold trim runs to
a great window divided by strict mullions; beyond it a planet turns its lit edge to a cold sun. A command
table holds a tactical hologram at the centre. Ordered, cold, monumental. No heraldry from any real setting."""
import math, os, random, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

reset(23)
enamel = paint("enamel", (0.012, 0.035, 0.13), rough=0.28, coat=0.9, wear=0.25)
deep = paint("deep", (0.006, 0.012, 0.035), rough=0.4, coat=0.5, wear=0.15)
gold = metal("gold", (0.85, 0.62, 0.22), rough=0.22, scuff=0.35, scale=6)
steel = metal("steel", (0.18, 0.2, 0.24), rough=0.4, scuff=0.4)
holo = glow("holo", (0.08, 0.38, 1.0), 1.6)
holo_dim = glow("holo2", (0.06, 0.3, 1.0), 0.7)
star = glow("star", (0.9, 0.95, 1.0), 25)

# deck: plates and gold seams
for i in range(-4, 5):
    for j in range(0, 10):
        box((i * 3.05, j * 3.05 - 8, -0.2), (3, 3, 0.4), deep if (i + j) % 2 else steel, bevel=0.03)
for i in range(-4, 5):
    box((i * 3.05 + 1.52, 6, 0.01), (0.06, 30, 0.04), gold)
# side walls: armour plates in two tiers, gold frames, buttresses
for side in (-1, 1):
    x = side * 13
    box((x, 8, 9), (1, 36, 18), deep)
    for j in range(5):
        y = j * 6 - 3
        for z, h in ((3.4, 5.6), (10.2, 6.4)):
            box((x - side * 0.6, y, z), (0.3, 5.2, h), enamel, bevel=0.12)
            box((x - side * 0.78, y, z + h / 2 - 0.15), (0.12, 5.2, 0.14), gold)
            box((x - side * 0.78, y, z - h / 2 + 0.15), (0.12, 5.2, 0.14), gold)
        box((x - side * 0.9, y + 3, 9), (1.2, 0.9, 18), steel, bevel=0.08)
        box((x - side * 1.5, y + 3, 13.6), (0.18, 0.95, 0.18), gold)
        for dy in (-0.47, 0.47):   # gilt edges down the buttress
            box((x - side * 1.52, y + 3 + dy, 9), (0.06, 0.06, 18), gold)
        sphere((x - side * 1.0, y + 3, 6.5), 0.18, glow("lamp%d%d" % (j, side), (0.6, 0.8, 1.0), 12))
# ceiling: coffered
box((0, 8, 18.5), (28, 36, 1), deep)
for j in range(6):
    box((0, j * 6 - 3, 17.8), (26, 0.6, 0.8), enamel, bevel=0.05)
    box((0, j * 6 - 3, 17.38), (26, 0.62, 0.06), gold)

# the window: a frame of armour, strict mullions, chamfered top corners
yw = 26
box((0, yw + 0.6, 1.0), (26, 1.2, 2.0), enamel, bevel=0.1)
box((0, yw + 0.6, 17.2), (26, 1.2, 2.4), enamel, bevel=0.1)
for x in (-12.5, 12.5):
    box((x, yw + 0.6, 9), (1.6, 1.2, 18), enamel, bevel=0.1)
for x in (-7.5, -2.5, 2.5, 7.5):
    box((x, yw + 0.4, 9), (0.45, 0.6, 15), steel, bevel=0.04)
    box((x, yw + 0.05, 9), (0.12, 0.1, 15), gold)
for z in (6.0, 11.5):
    box((0, yw + 0.4, z), (24, 0.6, 0.35), steel, bevel=0.03)
for x in (-11.7, 11.7):
    box((x, yw + 0.2, 15.6), (2.8, 0.8, 2.8), enamel, rot=(0, math.radians(45), 0), bevel=0.05)
box((0, yw - 0.05, 2.05), (24.6, 0.1, 0.14), gold)
box((0, yw - 0.05, 15.95), (24.6, 0.1, 0.14), gold)

# space: a planet with an atmosphere, a cold sun behind it, stars
planet = bpy.data.materials.new("planet"); planet.use_nodes = True
nt = planet.node_tree; b = nt.nodes["Principled BSDF"]
b.inputs["Base Color"].default_value = (0.05, 0.12, 0.3, 1); b.inputs["Roughness"].default_value = 0.9
nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 3; nz.inputs["Detail"].default_value = 10
ramp = nt.nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color = (0.015, 0.035, 0.1, 1); ramp.color_ramp.elements[1].color = (0.25, 0.35, 0.5, 1)
ramp.color_ramp.elements[0].position = 0.45; ramp.color_ramp.elements[1].position = 0.62
nt.links.new(nz.outputs["Fac"], ramp.inputs["Fac"]); nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
sphere((14, 140, -22), 52, planet, seg=96)
atmo = bpy.data.materials.new("atmo"); atmo.use_nodes = True
an = atmo.node_tree; an.nodes.remove(an.nodes["Principled BSDF"])
vol = an.nodes.new("ShaderNodeVolumePrincipled"); vol.inputs["Color"].default_value = (0.3, 0.55, 1.0, 1); vol.inputs["Density"].default_value = 0.05
an.links.new(vol.outputs[0], an.nodes["Material Output"].inputs["Volume"])
sphere((14, 140, -22), 54.5, atmo, seg=96)
# the sun stands behind the planet: the planet shows a lit edge, and its light comes in through the window in shafts
from mathutils import Vector
sun = light("SUN", (0, 0, 0), 6, (0.8, 0.88, 1.0))
sun.rotation_euler = Vector((0.25, -1.0, -0.32)).to_track_quat("-Z", "Y").to_euler()
sun.data.angle = math.radians(1.5)
scatter(320, ((-90, 90), (180, 182)), (-30, 70), 0.06, [star])

# the command table: an octagonal plinth, a gold rim, a tactical hologram of rings and a globe of light
cyl((0, 9, 0.9), 3.2, 1.8, steel, verts=8, bevel=0.06)
cyl((0, 9, 1.2), 3.25, 0.5, enamel, verts=8, bevel=0.03)
cyl((0, 9, 1.86), 3.35, 0.12, gold, verts=8)
cyl((0, 9, 1.95), 2.9, 0.06, holo_dim, verts=8)
for k, (r, z) in enumerate(((2.2, 2.6), (1.6, 3.2), (1.0, 3.7))):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=0.025, location=(0, 9, z), rotation=(math.radians(8 * k), 0, 0))
    bpy.context.object.data.materials.append(holo)
sphere((0, 9, 4.3), 0.55, glow("globe", (0.1, 0.45, 1.0), 1.1))
for k in range(12):
    a = k / 12 * math.tau
    box((math.cos(a) * 2.6, 9 + math.sin(a) * 2.6, 2.3), (0.04, 0.04, 0.6), holo_dim)
# consoles at the sides of the table
for x in (-6, 6):
    box((x, 7, 0.7), (2.6, 1.4, 1.4), enamel, bevel=0.08)
    box((x, 7.2, 1.48), (2.2, 1.0, 0.06), holo_dim, rot=(math.radians(-20), 0, 0))

light("AREA", (0, 8, 17), 260, (0.7, 0.82, 1.0), size=14)
for x in (-9, 9):   # cold downlights picking out the gilt on the side walls
    light("SPOT", (x, 8, 17), 9000, (0.85, 0.9, 1.0), size=0.2, rot=(0, math.radians(-25 if x > 0 else 25), 0), spot=math.radians(50))
light("POINT", (0, 9, 3.4), 600, (0.3, 0.6, 1.0), size=1)
room_haze((26, 34, 18), (0, 8, 9), haze("haze", (0.7, 0.8, 1.0), density=0.009, anisotropy=0.6, noise=0.6))

camera((0, -15, 5.2), (0, 26, 7.6), lens=24, shift=(0, 0.02))
render()
