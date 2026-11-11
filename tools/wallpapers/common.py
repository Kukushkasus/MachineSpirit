# [ PURITY SEAL ] Original scenes, built from nothing but code.
"""Shared parts for the faction wallpaper scenes. Run a scene with the portable Blender:

    blender -b -P tools/wallpapers/mechanicus.py -- --out walls/mechanicus.png [--preview]

Every shape, material and light is made here from primitives; no outside models, textures or artwork are used.
"""
import math, random, sys
import bpy
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PREVIEW = "--preview" in ARGS
OUT = ARGS[ARGS.index("--out") + 1] if "--out" in ARGS else "/tmp/wall.png"


def reset(seed=7):
    random.seed(seed)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    for kind in ("OPTIX", "CUDA"):
        try:
            prefs.compute_device_type = kind; prefs.get_devices()
            if any(d.type == kind for d in prefs.devices):
                for d in prefs.devices: d.use = d.type == kind
                s.cycles.device = "GPU"; break
        except Exception:
            pass
    s.cycles.samples = 48 if PREVIEW else 192
    s.cycles.use_denoising = True
    s.cycles.denoiser = "OPENIMAGEDENOISE"
    s.cycles.max_bounces = 8
    s.cycles.volume_bounces = 1
    s.cycles.volume_step_rate = 4 if PREVIEW else 2
    s.render.resolution_x, s.render.resolution_y = (960, 540) if PREVIEW else (3840, 2160)
    s.render.resolution_percentage = 100
    s.view_settings.view_transform = "AgX"
    s.view_settings.look = "AgX - Medium High Contrast"
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.color_depth = "16" if not PREVIEW else "8"
    s.render.filepath = OUT
    w = bpy.data.worlds.new("World"); s.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.002, 0.002, 0.003, 1)
    return s


def render():
    bpy.ops.render.render(write_still=True)


# ---------------------------------------------------------------- materials
def _nodes(m):
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        if n.type != "OUTPUT_MATERIAL": nt.nodes.remove(n)
    return nt, nt.nodes["Material Output"]


def metal(name, color, rough=0.35, scuff=0.45, bump=0.25, scale=6.0, metallic=1.0):
    """Worn metal: roughness and colour broken up by noise, with a fine hammered bump."""
    m = bpy.data.materials.new(name); nt, out = _nodes(m); n = nt.nodes; l = nt.links
    b = n.new("ShaderNodeBsdfPrincipled")
    b.inputs["Metallic"].default_value = metallic
    tc = n.new("ShaderNodeTexCoord")
    nz = n.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = scale; nz.inputs["Detail"].default_value = 12
    l.new(tc.outputs["Object"], nz.inputs["Vector"])
    ramp = n.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.35; ramp.color_ramp.elements[0].color = (rough * (1 - scuff), 0, 0, 1)
    ramp.color_ramp.elements[1].position = 0.75; ramp.color_ramp.elements[1].color = (min(1, rough * (1 + scuff)), 0, 0, 1)
    l.new(nz.outputs["Fac"], ramp.inputs["Fac"]); l.new(ramp.outputs["Color"], b.inputs["Roughness"])
    mix = n.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = scuff
    mix.inputs["A"].default_value = (*color, 1)
    l.new(nz.outputs["Color"], mix.inputs["B"]); l.new(mix.outputs["Result"], b.inputs["Base Color"])
    fine = n.new("ShaderNodeTexNoise"); fine.inputs["Scale"].default_value = scale * 18; fine.inputs["Detail"].default_value = 4
    l.new(tc.outputs["Object"], fine.inputs["Vector"])
    bp = n.new("ShaderNodeBump"); bp.inputs["Strength"].default_value = bump; bp.inputs["Distance"].default_value = 0.02
    l.new(fine.outputs["Fac"], bp.inputs["Height"]); l.new(bp.outputs["Normal"], b.inputs["Normal"])
    l.new(b.outputs["BSDF"], out.inputs["Surface"])
    return m


def paint(name, color, rough=0.45, coat=0.4, wear=0.25):
    """Enamel over metal: a lacquered colour with a clear coat, worn through to metal at the noise peaks."""
    m = metal(name, color, rough=rough, scuff=wear, bump=0.12, metallic=0.15)
    b = next(x for x in m.node_tree.nodes if x.type == "BSDF_PRINCIPLED")
    b.inputs["Coat Weight"].default_value = coat
    return m


def glow(name, color, strength=12.0):
    m = bpy.data.materials.new(name); nt, out = _nodes(m)
    e = nt.nodes.new("ShaderNodeEmission")
    e.inputs["Color"].default_value = (*color, 1); e.inputs["Strength"].default_value = strength
    nt.links.new(e.outputs[0], out.inputs["Surface"])
    return m


def haze(name, color=(0.8, 0.8, 0.8), density=0.02, anisotropy=0.35, noise=0.0, ground=False):
    """A volume to fill a room: light shafts and depth. `noise` > 0 makes it drift in clouds. `ground` makes it a
    mist that thins out with height inside its box instead of ending at a hard top."""
    m = bpy.data.materials.new(name); nt, out = _nodes(m); n = nt.nodes; l = nt.links
    v = n.new("ShaderNodeVolumePrincipled")
    v.inputs["Color"].default_value = (*color, 1); v.inputs["Density"].default_value = density
    v.inputs["Anisotropy"].default_value = anisotropy
    if ground:
        tc = n.new("ShaderNodeTexCoord"); sep = n.new("ShaderNodeSeparateXYZ")
        mr = n.new("ShaderNodeMapRange"); mr.inputs["From Min"].default_value = 0; mr.inputs["From Max"].default_value = 1
        mr.inputs["To Min"].default_value = 1; mr.inputs["To Max"].default_value = 0
        pw = n.new("ShaderNodeMath"); pw.operation = "POWER"; pw.inputs[1].default_value = 3
        mul = n.new("ShaderNodeMath"); mul.operation = "MULTIPLY"; mul.inputs[1].default_value = density
        l.new(tc.outputs["Generated"], sep.inputs[0]); l.new(sep.outputs["Z"], mr.inputs["Value"])
        l.new(mr.outputs["Result"], pw.inputs[0]); l.new(pw.outputs[0], mul.inputs[0]); l.new(mul.outputs[0], v.inputs["Density"])
        noise = 0
    if noise > 0:
        nz = n.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 0.35; nz.inputs["Detail"].default_value = 3
        ramp = n.new("ShaderNodeValToRGB"); ramp.color_ramp.elements[0].position = 0.4; ramp.color_ramp.elements[1].position = 0.75
        mul = n.new("ShaderNodeMath"); mul.operation = "MULTIPLY"; mul.inputs[1].default_value = density * (1 + noise * 3)
        l.new(nz.outputs["Fac"], ramp.inputs["Fac"]); l.new(ramp.outputs["Color"], mul.inputs[0]); l.new(mul.outputs[0], v.inputs["Density"])
    l.new(v.outputs[0], out.inputs["Volume"])
    return m


# ---------------------------------------------------------------- shapes
def _finish(o, mat=None, bevel=0.0, segments=2, smooth=False):
    if mat: o.data.materials.append(mat)
    if bevel > 0:
        md = o.modifiers.new("bevel", "BEVEL"); md.width = bevel; md.segments = segments; md.limit_method = "ANGLE"
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    return o


def box(loc, size, mat=None, bevel=0.0, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.object; o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, mat, bevel)


def cyl(loc, r, depth, mat=None, verts=48, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    return _finish(bpy.context.object, mat, bevel, smooth=True)


def sphere(loc, r, mat=None, seg=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=loc)
    return _finish(bpy.context.object, mat, smooth=True)


def cone(loc, r1, r2, depth, mat=None, verts=4, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    return _finish(bpy.context.object, mat)


def join(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    return objs[0]


def gear(loc, r, teeth, depth, mat, rot=(0, 0, 0), tooth=0.18, hub=0.35, spokes=6):
    """A cog: a ring, square teeth round it, spokes and a hub, joined into one object."""
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=max(32, teeth * 4), radius=r, depth=depth, location=(0, 0, 0))
    ring = bpy.context.object
    bpy.ops.mesh.primitive_cylinder_add(vertices=max(32, teeth * 4), radius=r * 0.78, depth=depth * 1.5, location=(0, 0, 0))
    hole = bpy.context.object
    md = ring.modifiers.new("cut", "BOOLEAN"); md.object = hole; md.operation = "DIFFERENCE"
    bpy.context.view_layer.objects.active = ring; bpy.ops.object.modifier_apply(modifier="cut")
    bpy.data.objects.remove(hole)
    parts.append(ring)
    t = r * tooth
    for i in range(teeth):
        a = i / teeth * math.tau
        bpy.ops.mesh.primitive_cube_add(location=(math.cos(a) * (r + t * 0.4), math.sin(a) * (r + t * 0.4), 0), rotation=(0, 0, a))
        o = bpy.context.object; o.scale = (t * 0.6, math.tau * r / teeth * 0.24, depth / 2); parts.append(o)
    for i in range(spokes):
        a = i / spokes * math.tau
        bpy.ops.mesh.primitive_cube_add(location=(math.cos(a) * r * 0.45, math.sin(a) * r * 0.45, 0), rotation=(0, 0, a))
        o = bpy.context.object; o.scale = (r * 0.42, r * 0.06, depth * 0.4); parts.append(o)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r * hub * 0.5, depth=depth * 1.4, location=(0, 0, 0)); parts.append(bpy.context.object)
    g = join(parts)
    bpy.ops.object.transform_apply(scale=True)
    g.location = loc; g.rotation_euler = rot
    _finish(g, mat, bevel=r * 0.012, segments=1)
    return g


def catenary(a, b, sag, n=24):
    a, b = Vector(a), Vector(b)
    pts = []
    for i in range(n + 1):
        t = i / n
        p = a.lerp(b, t); p.z -= sag * (1 - (2 * t - 1) ** 2)
        pts.append(p)
    return pts


def cable(points, r, mat):
    cu = bpy.data.curves.new("cable", "CURVE"); cu.dimensions = "3D"
    cu.bevel_depth = r; cu.bevel_resolution = 4; cu.use_fill_caps = True
    sp = cu.splines.new("POLY"); sp.points.add(len(points) - 1)
    for p, q in zip(sp.points, points): p.co = (q.x, q.y, q.z, 1)
    o = bpy.data.objects.new("cable", cu); bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def chain(points, link, mat):
    """Heavy chain along a path: torus links, every other one turned a quarter, sharing one mesh."""
    bpy.ops.mesh.primitive_torus_add(major_radius=link, minor_radius=link * 0.28, major_segments=24, minor_segments=10)
    proto = bpy.context.object; proto.scale = (1.0, 1.6, 1.0); bpy.ops.object.transform_apply(scale=True)
    proto.data.materials.append(mat)
    for p in proto.data.polygons: p.use_smooth = True
    # resample the path at equal steps of one link
    path = [Vector(p) for p in points]
    step = link * 2.3
    out, carry = [path[0]], 0.0
    for a, b in zip(path, path[1:]):
        seg = (b - a).length; d = step - carry
        while d <= seg:
            out.append(a.lerp(b, d / seg)); d += step
        carry = seg - (d - step)
    links = []
    for i in range(len(out) - 1):
        a, b = out[i], out[i + 1]
        o = proto.copy(); bpy.context.collection.objects.link(o)
        o.location = (a + b) / 2
        direction = (b - a).normalized()
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = direction.to_track_quat("Y", "Z")
        if i % 2: o.rotation_quaternion = o.rotation_quaternion @ Vector((0, 1, 0)).to_track_quat("Y", "X")
        links.append(o)
    bpy.data.objects.remove(proto)
    return links


def light(kind, loc, energy, color=(1, 1, 1), size=1.0, rot=(0, 0, 0), spot=None):
    d = bpy.data.lights.new(kind, kind); d.energy = energy; d.color = color
    if kind == "AREA": d.size = size
    if kind in ("POINT", "SPOT"): d.shadow_soft_size = size
    if kind == "SPOT" and spot: d.spot_size = spot; d.spot_blend = 0.4
    o = bpy.data.objects.new(kind, d); o.location = loc; o.rotation_euler = rot
    bpy.context.collection.objects.link(o)
    return o


def camera(loc, look_at, lens=28, shift=(0, 0)):
    c = bpy.data.cameras.new("cam"); c.lens = lens; c.shift_x, c.shift_y = shift
    c.clip_end = 1000
    o = bpy.data.objects.new("cam", c); bpy.context.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector(look_at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = o
    return o


def room_haze(size, center, mat):
    bpy.ops.mesh.primitive_cube_add(location=center); o = bpy.context.object
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2); o.data.materials.append(mat)
    o.visible_shadow = False
    return o


def scatter(n, area, z, r, mats):
    """Small emissive specks: embers, motes, sparks."""
    out = []
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=r); proto = bpy.context.object
    for i in range(n):
        o = proto.copy(); o.data = proto.data.copy(); bpy.context.collection.objects.link(o)
        o.location = (random.uniform(*area[0]), random.uniform(*area[1]), random.uniform(*z))
        s = random.uniform(0.4, 1.4); o.scale = (s, s, s)
        o.data.materials.append(random.choice(mats)); out.append(o)
    bpy.data.objects.remove(proto)
    return out
