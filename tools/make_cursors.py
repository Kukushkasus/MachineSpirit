#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Build the four MachineSpirit cursor themes (original shapes, drawn in code).

  make_cursors.py svg OUTDIR                 one SVG per shape and faction (for review)
  make_cursors.py build OUTDIR [--faction ID ...] [--sizes 24,32,...] [--no-hyprcursor]
        writes OUTDIR/MachineSpirit-<Faction>/ with an XCursor theme (cursors/, index.theme)
        and, when hyprcursor-util is present, the hyprcursor form (manifest.hl + hyprcursors/)

Every shape is drawn as parts on a 256-unit canvas. Each part is painted in three passes over all parts (a dark
outer contour, a light inner contour, then the faction body), so overlapping parts read as one silhouette with an
unbroken double outline that shows on white, black and busy pictures alike. Needs rsvg-convert (librsvg).
"""
import math, os, shutil, struct, subprocess, sys, tempfile, zlib
from concurrent.futures import ThreadPoolExecutor

CANVAS = 256
DARK_W = 23      # outer contour reach beyond a part's edge (units of 256)
LIGHT_W = 12     # light contour reach
SIZES = (24, 32, 40, 48, 64, 80)

FACTIONS = {
    "mechanicus": dict(name="Mechanicus", dark="#140d08", light="#fbf0d8",
                       body=("#f2cf7c", "#a77a2c"), body2="#3a2a1d", accent="#d0291b", trim="#7a5418",
                       join="round", spin="cog"),
    "ultramarines": dict(name="Ultramarines", dark="#070e1e", light="#ffffff",
                         body=("#3f78dc", "#173a86"), body2="#0f2552", accent="#f2d27a", trim="#f2d27a",
                         join="miter", spin="ring"),
    "necrons": dict(name="Necrons", dark="#030806", light="#d9ece4",
                    body=("#4f5d59", "#1d2624"), body2="#0d1311", accent="#3dff9e", trim="#8aa59a",
                    join="miter", spin="tri"),
    "khorne": dict(name="Khorne", dark="#0c0303", light="#f6e2d0",
                   body=("#46342e", "#1a1210"), body2="#120b09", accent="#d81f14", trim="#d9a441",
                   join="miter", spin="spike"),
}


def f(v): return f"{v:.2f}".rstrip("0").rstrip(".")


def poly(pts): return "M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + " Z"


def rrect(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    return (f"M{f(x + r)} {f(y)} H{f(x + w - r)} A{f(r)} {f(r)} 0 0 1 {f(x + w)} {f(y + r)} V{f(y + h - r)} "
            f"A{f(r)} {f(r)} 0 0 1 {f(x + w - r)} {f(y + h)} H{f(x + r)} A{f(r)} {f(r)} 0 0 1 {f(x)} {f(y + h - r)} "
            f"V{f(y + r)} A{f(r)} {f(r)} 0 0 1 {f(x + r)} {f(y)} Z")


def circle(cx, cy, r):
    return f"M{f(cx - r)} {f(cy)} a{f(r)} {f(r)} 0 1 0 {f(2 * r)} 0 a{f(r)} {f(r)} 0 1 0 {f(-2 * r)} 0 Z"


def rot(pts, ang, cx=128, cy=128):
    a = math.radians(ang); c, s = math.cos(a), math.sin(a)
    return [(cx + (x - cx) * c - (y - cy) * s, cy + (x - cx) * s + (y - cy) * c) for x, y in pts]


def shift(pts, dx, dy): return [(x + dx, y + dy) for x, y in pts]


def scale(pts, k, cx=0, cy=0): return [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in pts]


# ---------------------------------------------------------------- silhouettes
# Arrow tips sit at (36, 26): the hotspot for every arrow-based cursor.

def arrow_pts(fac):
    if fac == "mechanicus":   # a sturdy pointer with a cog tooth stepped into its wing
        return [(36, 26), (36, 198), (78, 160), (106, 222), (138, 208), (112, 150), (150, 148), (150, 136), (170, 136)]
    if fac == "ultramarines":  # a clean, straight-edged chevron arrow
        return [(36, 26), (36, 196), (82, 156), (110, 220), (140, 207), (113, 145), (172, 145)]
    if fac == "necrons":       # long and narrow, the tail cut square like a monolith
        return [(36, 26), (36, 214), (70, 180), (90, 234), (114, 225), (95, 172), (138, 170)]
    return [(36, 26), (36, 190), (64, 168), (72, 196), (96, 180), (114, 224), (142, 210), (122, 160),   # khorne: barbed
            (148, 166), (136, 144), (174, 142)]


def arrow_detail(fac, s):
    """Accents inside the arrow body."""
    a, t = s["accent"], s["trim"]
    if fac == "mechanicus":
        return (f'<path d="{circle(76, 118, 17)}" fill="{s["body2"]}"/>'
                f'<path d="{circle(76, 118, 9)}" fill="{a}"/>'
                f'<path d="M52 70 L52 170" stroke="{s["body2"]}" stroke-opacity="0.55" stroke-width="7" stroke-linecap="round"/>')
    if fac == "ultramarines":
        return (f'<path d="M50 64 L50 164 L74 143" fill="none" stroke="{t}" stroke-width="9" stroke-linejoin="miter"/>')
    if fac == "necrons":
        return (f'<path d="M49 70 L49 180" stroke="{a}" stroke-width="8"/>'
                f'<path d="{poly([(66, 118), (80, 142), (66, 142)])}" fill="{a}"/>')
    return (f'<path d="M50 62 L50 158" stroke="{a}" stroke-width="10"/>'
            f'<path d="{circle(86, 132, 7)}" fill="{t}"/>')


# ---------------------------------------------------------------- composition

def svg_doc(parts, detail, s, shadow=True, extra=""):
    """parts: list of path strings. Three passes give one silhouette with a double outline."""
    j = s["join"]
    jl = f'stroke-linejoin="{j}" stroke-miterlimit="3" stroke-linecap="round"'
    d = " ".join(parts)
    body = (f'<path d="{d}" fill="none" stroke="{s["dark"]}" stroke-width="{2 * (DARK_W + LIGHT_W)}" {jl}/>'
            f'<path d="{d}" fill="none" stroke="{s["light"]}" stroke-width="{2 * LIGHT_W}" {jl}/>'
            f'<path d="{d}" fill="url(#g)" fill-rule="nonzero"/>')
    sh = ""
    if shadow:
        sh = (f'<path d="{d}" fill="#000" stroke="#000" stroke-width="{2 * (DARK_W + LIGHT_W)}" {jl} '
              f'opacity="0.32" transform="translate(5 9)" filter="url(#b)"/>')
    g0, g1 = s["body"]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CANVAS} {CANVAS}" width="{CANVAS}" height="{CANVAS}">'
            f'<defs><linearGradient id="g" x1="0" y1="0" x2="0.6" y2="1"><stop offset="0" stop-color="{g0}"/>'
            f'<stop offset="1" stop-color="{g1}"/></linearGradient>'
            f'<filter id="b" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="7"/></filter></defs>'
            f'{sh}{body}{detail}{extra}</svg>')


def badge(s, glyph, cx=194, cy=196, r=40, fill=None):
    """A round sign at the arrow's foot: help, copy, alias, no-drop, menu, progress."""
    fill = fill or s["body2"]
    return (f'<path d="{circle(cx, cy, r + DARK_W * 0.7 + LIGHT_W * 0.7)}" fill="{s["dark"]}"/>'
            f'<path d="{circle(cx, cy, r + LIGHT_W * 0.7)}" fill="{s["light"]}"/>'
            f'<path d="{circle(cx, cy, r)}" fill="{fill}"/>{glyph}')


def badge_glyph(kind, s, cx=194, cy=196):
    c, a = s["light"], s["accent"]
    if kind == "help":
        return (f'<path d="M{cx - 14} {cy - 12} q0 -18 14 -18 q16 0 16 15 q0 10 -10 15 q-6 3 -6 12" fill="none" '
                f'stroke="{c}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
                f'<path d="{circle(cx, cy + 25, 6.5)}" fill="{c}"/>')
    if kind == "copy":
        return f'<path d="M{cx} {cy - 22} V{cy + 22} M{cx - 22} {cy} H{cx + 22}" stroke="{c}" stroke-width="11" stroke-linecap="square"/>'
    if kind == "alias":
        return (f'<path d="M{cx - 18} {cy + 18} Q{cx - 18} {cy - 12} {cx + 12} {cy - 12}" fill="none" stroke="{c}" stroke-width="10"/>'
                f'<path d="{poly([(cx + 6, cy - 30), (cx + 28, cy - 12), (cx + 6, cy + 6)])}" fill="{c}"/>')
    if kind == "menu":
        return "".join(f'<path d="M{cx - 20} {cy + dy} H{cx + 20}" stroke="{c}" stroke-width="8"/>' for dy in (-16, 0, 16))
    if kind == "nodrop":
        return (f'<path d="{circle(cx, cy, 22)}" fill="none" stroke="{a}" stroke-width="9"/>'
                f'<path d="M{cx - 15} {cy + 15} L{cx + 15} {cy - 15}" stroke="{a}" stroke-width="9"/>')
    return ""


def double_arrow(length=200, width=40, head=80, headlen=62):
    """A horizontal two-headed arrow centred on the canvas."""
    h, w, hl = length / 2, width / 2, head / 2
    cx, cy = 128, 128
    return [(cx - h, cy), (cx - h + headlen, cy - hl), (cx - h + headlen, cy - w), (cx + h - headlen, cy - w),
            (cx + h - headlen, cy - hl), (cx + h, cy), (cx + h - headlen, cy + hl), (cx + h - headlen, cy + w),
            (cx - h + headlen, cy + w), (cx - h + headlen, cy + hl)]


def resize(ang, s, fac):
    pts = rot(double_arrow(196 if ang % 90 == 0 else 176), ang)
    det = ""
    if fac in ("ultramarines", "khorne", "necrons", "mechanicus"):
        bar = rot([(128 - 26, 128), (128 + 26, 128)], ang)
        det = f'<path d="M{f(bar[0][0])} {f(bar[0][1])} L{f(bar[1][0])} {f(bar[1][1])}" stroke="{s["accent"] if fac != "ultramarines" else s["trim"]}" stroke-width="8"/>'
    return [poly(pts)], det


def move_parts():
    parts = []
    for ang in (0, 90):
        parts.append(poly(rot(double_arrow(212, 30, 70, 54), ang)))
    return parts


def ibeam(vertical=False):
    pts = [(98, 30), (158, 30), (158, 50), (138, 50), (138, 206), (158, 206), (158, 226), (98, 226), (98, 206),
           (118, 206), (118, 50), (98, 50)]
    return [poly(rot(pts, 90) if vertical else pts)]


def crosshair_parts():
    g, L, w = 26, 92, 10
    c = 128
    return [poly([(c - w, c - L), (c + w, c - L), (c + w, c - g), (c - w, c - g)]),
            poly([(c - w, c + g), (c + w, c + g), (c + w, c + L), (c - w, c + L)]),
            poly([(c - L, c - w), (c - g, c - w), (c - g, c + w), (c - L, c + w)]),
            poly([(c + g, c - w), (c + L, c - w), (c + L, c + w), (c + g, c + w)])]


def cell_parts():
    w, L, c = 22, 82, 128
    return [poly([(c - w, c - L), (c + w, c - L), (c + w, c - w), (c + L, c - w), (c + L, c + w), (c + w, c + w),
                  (c + w, c + L), (c - w, c + L), (c - w, c + w), (c - L, c + w), (c - L, c - w), (c - w, c - w)])]


def ring_path(cx, cy, r_out, r_in):
    return circle(cx, cy, r_out) + " " + f"M{f(cx - r_in)} {f(cy)} a{f(r_in)} {f(r_in)} 0 1 1 {f(2 * r_in)} 0 a{f(r_in)} {f(r_in)} 0 1 1 {f(-2 * r_in)} 0 Z"


def notallowed(s, cx=128, cy=128, r=84, w=26):
    slash = rot([(cx - r + 8, cy - w / 2), (cx + r - 8, cy - w / 2), (cx + r - 8, cy + w / 2), (cx - r + 8, cy + w / 2)], -45, cx, cy)
    parts = [ring_path(cx, cy, r, r - w), poly(slash)]
    return parts


def hand_parts(kind, fac):
    """Pointing, open and closed gauntlet. The fingertip of the pointing hand sits at (104, 24)."""
    if kind == "pointer":
        return [rrect(88, 24, 34, 112, 17), rrect(66, 108, 118, 88, 26),
                rrect(58, 116, 34, 70, 17), rrect(80, 190, 98, 40, 8 if fac != "mechanicus" else 12)]
    if kind == "grab":
        fingers = [rrect(70, 46, 30, 92, 15), rrect(102, 34, 30, 100, 15), rrect(134, 42, 30, 96, 15), rrect(164, 66, 28, 78, 14)]
        thumb = poly(rot([(40, 120), (70, 106), (96, 150), (70, 166)], 0))
        return fingers + [rrect(64, 110, 128, 92, 30), thumb, rrect(80, 196, 102, 36, 8)]
    # grabbing: a closed fist seen from the back
    return [rrect(64, 88, 128, 108, 32), rrect(56, 116, 40, 58, 18), rrect(80, 190, 98, 40, 8)]


def hand_detail(kind, s, fac):
    d = s["body2"]
    if kind == "pointer":
        cuffy = 190
        k = "".join(f'<path d="M{x} 124 V150" stroke="{d}" stroke-opacity="0.6" stroke-width="6" stroke-linecap="round"/>' for x in (124, 154))
    elif kind == "grab":
        cuffy = 196
        k = ""
    else:
        cuffy = 190
        k = "".join(f'<path d="M{x} 96 V122" stroke="{d}" stroke-opacity="0.6" stroke-width="6" stroke-linecap="round"/>' for x in (100, 132, 162))
    a, t = s["accent"], s["trim"]
    if fac == "mechanicus":
        cuff = f'<path d="{rrect(80, cuffy, 98, 12, 4)}" fill="{t}"/><path d="{circle(129, cuffy + 26, 6)}" fill="{a}"/>'
    elif fac == "ultramarines":
        cuff = f'<path d="{rrect(80, cuffy, 98, 10, 0)}" fill="{t}"/><path d="{rrect(80, cuffy + 28, 98, 6, 0)}" fill="{t}"/>'
    elif fac == "necrons":
        cuff = f'<path d="M86 {cuffy + 20} H172" stroke="{a}" stroke-width="7"/>'
    else:
        cuff = (f'<path d="{rrect(80, cuffy, 98, 10, 0)}" fill="{a}"/>'
                + "".join(f'<path d="{circle(x, cuffy + 26, 5)}" fill="{t}"/>' for x in (100, 158)))
    return k + cuff


def zoom(s, plus):
    parts = [ring_path(108, 108, 74, 46), poly(rot([(160, 152), (232, 152), (232, 180), (160, 180)], 45, 175, 175))]
    g = f'M84 108 H132' + (' M108 84 V132' if plus else '')
    return parts, f'<path d="{g}" stroke="{s["accent"] if True else s["light"]}" stroke-width="12"/>'


def spinner(s, fac, frame, frames, cx=128, cy=128, r=88, small=False):
    """One frame of the busy mark. Returns (parts, detail) around (cx, cy)."""
    ph = frame / frames
    a, t = s["accent"], s["trim"]
    if fac == "mechanicus":
        teeth, ro, ri = 10, r, r * 0.78
        pts = []
        pitch = 2 * math.pi / teeth
        off = ph * pitch * 2
        for i in range(teeth):
            b = i * pitch + off
            for fr, rr in ((0, ro), (0.36, ro), (0.48, ri), (0.9, ri)):
                ang = b + fr * pitch
                pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
        parts = [poly(pts) + " " + circle(cx, cy, r * 0.36)]
        det = f'<path d="{circle(cx, cy, r * 0.16)}" fill="{a}"/>'
        return parts, det
    parts = [ring_path(cx, cy, r, r * 0.64)]
    if fac == "necrons":
        tri = [(cx, cy - r * 0.42), (cx + r * 0.36, cy + r * 0.21), (cx - r * 0.36, cy + r * 0.21)]
        tri = rot(tri, -ph * 120, cx, cy)
        parts = [ring_path(cx, cy, r, r * 0.72)]
        det = f'<path d="{poly(tri)}" fill="{a}"/>'
    elif fac == "khorne":
        spikes = []
        for i in range(8):
            spikes.append(poly(rot([(cx - 9, cy - r + 4), (cx, cy - r - 22), (cx + 9, cy - r + 4)], i * 45 + ph * 45, cx, cy)))
        parts = parts + spikes
        det = ""
    else:
        det = ""
    # the lit arc sweeps round the ring
    a0 = ph * 360
    rm = r * (0.86 if fac == "necrons" else 0.82)
    p0 = (cx + rm * math.cos(math.radians(a0)), cy + rm * math.sin(math.radians(a0)))
    p1 = (cx + rm * math.cos(math.radians(a0 + 100)), cy + rm * math.sin(math.radians(a0 + 100)))
    col = t if fac == "ultramarines" else a
    det += (f'<path d="M{f(p0[0])} {f(p0[1])} A{f(rm)} {f(rm)} 0 0 1 {f(p1[0])} {f(p1[1])}" fill="none" '
            f'stroke="{col}" stroke-width="{f(r * 0.2)}" stroke-linecap="butt"/>')
    return parts, det


def scaled_group(svg_inner, k, cx, cy):
    return f'<g transform="translate({f(cx)} {f(cy)}) scale({f(k)}) translate(-128 -128)">{svg_inner}</g>'


# ---------------------------------------------------------------- the catalogue
# name: (hotspot in 256 units, X11/CSS aliases)
ARROW_HOT = (36, 26)
CATALOG = {
    "default": (ARROW_HOT, ["left_ptr", "arrow", "top_left_arrow", "left_arrow", "right_ptr"]),
    "pointer": ((104, 24), ["hand2", "hand", "pointing_hand", "hand1", "e29285e634086352946a0e7090d73106",
                            "9d800788f1b08800ae810202380a0822"]),
    "text": ((128, 128), ["xterm", "ibeam"]),
    "vertical-text": ((128, 128), []),
    "help": (ARROW_HOT, ["question_arrow", "whats_this", "left_ptr_help", "5c6cd98b3f3ebcb1f9c7f1c204630408",
                         "d9ce0ab605698f320427677b8f8e5303"]),
    "context-menu": (ARROW_HOT, []),
    "copy": (ARROW_HOT, ["dnd-copy", "1081e37283d90000800003c07f3ef6bf", "6407b0e94181790501fd1e167b474872"]),
    "alias": (ARROW_HOT, ["link", "dnd-link", "3085a0e285430894940527032f8b26df", "640fb0e74195791501fd1ed57b41487f"]),
    "no-drop": (ARROW_HOT, ["dnd-no-drop", "dnd-none"]),
    "progress": (ARROW_HOT, ["left_ptr_watch", "half-busy", "00000000000000020006000e7e9ffc3f",
                             "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"]),
    "wait": ((128, 128), ["watch"]),
    "crosshair": ((128, 128), ["cross", "tcross", "cross_reverse", "diamond_cross", "target"]),
    "cell": ((128, 128), ["plus"]),
    "not-allowed": ((128, 128), ["forbidden", "circle", "crossed_circle", "X_cursor", "03b6e0fcb3499374a867c041f52298f0"]),
    "move": ((128, 128), ["fleur", "all-scroll", "size_all", "dnd-move", "4498f0e0c1937ffe01fd06f973665830",
                          "9081237383d90e509aa00f00170e968f"]),
    "grab": ((128, 120), ["openhand", "fcf1c3c7cd4491d801f1e1c78f100000"]),
    "grabbing": ((128, 140), ["closedhand", "fcf21c00b30f7e3f85fe24f62fe9fa8f"]),
    "ew-resize": ((128, 128), ["col-resize", "sb_h_double_arrow", "h_double_arrow", "size_hor", "e-resize", "w-resize",
                               "right_side", "left_side", "split_h", "14fef782d02440884392942c11205230",
                               "028006030e0e7ebffc7f7070c0600140"]),
    "ns-resize": ((128, 128), ["row-resize", "sb_v_double_arrow", "v_double_arrow", "size_ver", "n-resize", "s-resize",
                               "top_side", "bottom_side", "split_v", "2870a09082c103050810ffdffffe0204",
                               "00008160000006810000408080010102"]),
    "nwse-resize": ((128, 128), ["size_fdiag", "bd_double_arrow", "nw-resize", "se-resize", "top_left_corner",
                                 "bottom_right_corner", "c7088f0f3e6c8088236ef8e1e3e70000"]),
    "nesw-resize": ((128, 128), ["size_bdiag", "fd_double_arrow", "ne-resize", "sw-resize", "top_right_corner",
                                 "bottom_left_corner", "fcf1c3c7cd4491d801f1e1c78f100000x"]),
    "zoom-in": ((108, 108), []),
    "zoom-out": ((108, 108), []),
}
CATALOG["nesw-resize"][1].pop()   # guard against a duplicated alias above
PREVIEW = ("default", "pointer", "text", "grab", "move", "ew-resize", "nwse-resize", "crosshair", "wait", "not-allowed")
SPIN_FRAMES = 12
SPIN_DELAY = 55


def shape_svgs(name, fac):
    """List of SVG documents (one, or one per frame for the busy shapes)."""
    s = FACTIONS[fac]
    if name in ("default", "help", "context-menu", "copy", "alias", "no-drop"):
        extra = ""
        kind = {"help": "help", "context-menu": "menu", "copy": "copy", "alias": "alias", "no-drop": "nodrop"}.get(name)
        if kind:
            fill = s["accent"] if kind in ("copy",) and fac != "ultramarines" else None
            extra = badge(s, badge_glyph(kind, s), fill=fill)
        return [svg_doc([poly(arrow_pts(fac))], arrow_detail(fac, s), s, extra=extra)]
    if name == "progress":
        out = []
        for i in range(SPIN_FRAMES):
            parts, det = spinner(s, fac, i, SPIN_FRAMES)
            inner = svg_doc(parts, det, s, shadow=False)
            inner = inner[inner.index("</defs>") + 7:-6]
            extra = scaled_group(inner, 0.42, 190, 192)
            out.append(svg_doc([poly(arrow_pts(fac))], arrow_detail(fac, s), s, extra=extra))
        return out
    if name == "wait":
        return [svg_doc(*spinner(s, fac, i, SPIN_FRAMES), s) for i in range(SPIN_FRAMES)]
    if name in ("pointer", "grab", "grabbing"):
        return [svg_doc(hand_parts(name, fac), hand_detail(name, s, fac), s)]
    if name in ("text", "vertical-text"):
        return [svg_doc(ibeam(name == "vertical-text"), "", s)]
    if name == "crosshair":
        return [svg_doc(crosshair_parts(), f'<path d="{circle(128, 128, 7)}" fill="{s["accent"]}"/>', s)]
    if name == "cell":
        return [svg_doc(cell_parts(), "", s)]
    if name == "not-allowed":
        # always red: the meaning must not change with the livery
        s2 = dict(s, body=("#e0362b", "#9c1610"))
        return [svg_doc(notallowed(s2), "", s2)]
    if name == "move":
        return [svg_doc(move_parts(), f'<path d="{circle(128, 128, 14)}" fill="{s["accent"] if fac != "ultramarines" else s["trim"]}"/>', s)]
    if name.endswith("-resize"):
        ang = {"ew-resize": 0, "ns-resize": 90, "nwse-resize": 45, "nesw-resize": -45}[name]
        parts, det = resize(ang, s, fac)
        return [svg_doc(parts, det, s)]
    if name in ("zoom-in", "zoom-out"):
        parts, det = zoom(s, name == "zoom-in")
        return [svg_doc(parts, det, s)]
    raise KeyError(name)


# ---------------------------------------------------------------- raster and XCursor

def rasterize(svg, size, tmp):
    fd, path = tempfile.mkstemp(suffix=".svg", dir=tmp); os.close(fd)
    with open(path, "w") as fh: fh.write(svg)
    png = subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), path], check=True, capture_output=True).stdout
    os.unlink(path)
    return decode_png(png)


def decode_png(data):
    """Minimal decoder for rsvg-convert output: 8-bit RGBA, non-interlaced. Returns (w, h, bytes RGBA)."""
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(data):
        ln, typ = struct.unpack(">I4s", data[pos:pos + 8]); chunk = data[pos + 8:pos + 8 + ln]; pos += 12 + ln
        if typ == b"IHDR":
            w, h, depth, ctype, _, _, inter = struct.unpack(">IIBBBBB", chunk)
            assert depth == 8 and ctype == 6 and inter == 0, "unexpected PNG format"
        elif typ == b"IDAT": idat += chunk
        elif typ == b"IEND": break
    raw = zlib.decompress(idat); bpp = 4; stride = w * bpp
    out = bytearray(h * stride); prev = bytearray(stride)
    for y in range(h):
        ft = raw[y * (stride + 1)]; line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0; b = prev[i]; c = prev[i - bpp] if i >= bpp else 0
            if ft == 1: line[i] = (line[i] + a) & 255
            elif ft == 2: line[i] = (line[i] + b) & 255
            elif ft == 3: line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif ft == 4:
                p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        out[y * stride:(y + 1) * stride] = line; prev = line
    return w, h, bytes(out)


def to_xcursor_pixels(rgba):
    """RGBA (straight) -> little-endian ARGB, premultiplied, as XCursor stores it."""
    px = bytearray(len(rgba))
    for i in range(0, len(rgba), 4):
        r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
        if a != 255:
            r, g, b = r * a // 255, g * a // 255, b * a // 255
        px[i], px[i + 1], px[i + 2], px[i + 3] = b, g, r, a
    return bytes(px)


def write_xcursor(path, images):
    """images: list of (nominal, w, h, xhot, yhot, delay, argb bytes)."""
    n = len(images)
    header = struct.pack("<4sIII", b"Xcur", 16, 0x10000, n)
    pos = 16 + 12 * n
    toc, chunks = b"", b""
    for nominal, w, h, xh, yh, delay, px in images:
        toc += struct.pack("<III", 0xfffd0002, nominal, pos)
        chunk = struct.pack("<IIIIIIIII", 36, 0xfffd0002, nominal, 1, w, h, xh, yh, delay) + px
        chunks += chunk; pos += len(chunk)
    with open(path, "wb") as fh: fh.write(header + toc + chunks)


def build(outdir, factions, sizes, hyprcursor=True):
    os.makedirs(outdir, exist_ok=True)
    have_hc = hyprcursor and shutil.which("hyprcursor-util")
    with tempfile.TemporaryDirectory() as tmp, ThreadPoolExecutor(max(2, os.cpu_count() or 2)) as pool:
        for fac in factions:
            s = FACTIONS[fac]
            theme = os.path.join(outdir, f"MachineSpirit-{s['name']}")
            if os.path.isdir(theme): shutil.rmtree(theme)
            cur = os.path.join(theme, "cursors"); os.makedirs(cur)
            src = os.path.join(tmp, fac, "hyprcursors")
            jobs = {}
            for name in CATALOG:
                docs = shape_svgs(name, fac)
                for fi, doc in enumerate(docs):
                    for sz in sizes:
                        jobs[(name, fi, sz)] = pool.submit(rasterize, doc, sz, tmp)
                if have_hc:
                    d = os.path.join(src, name); os.makedirs(d)
                    (hx, hy), aliases = CATALOG[name]
                    meta = [f"resize_algorithm = bilinear", f"hotspot_x = {hx / CANVAS:.4f}", f"hotspot_y = {hy / CANVAS:.4f}"]
                    meta += [f"define_override = {a}" for a in aliases]
                    for fi, doc in enumerate(docs):
                        fn = f"{name}-{fi:02d}.svg" if len(docs) > 1 else f"{name}.svg"
                        with open(os.path.join(d, fn), "w") as fh: fh.write(doc)
                        meta.append(f"define_size = 0, {fn}" + (f", {SPIN_DELAY}" if len(docs) > 1 else ""))
                    with open(os.path.join(d, "meta.hl"), "w") as fh: fh.write("\n".join(meta) + "\n")
            for name, ((hx, hy), aliases) in CATALOG.items():
                frames = len(shape_svgs(name, fac))
                imgs = []
                for sz in sizes:
                    for fi in range(frames):
                        w, h, rgba = jobs[(name, fi, sz)].result()
                        imgs.append((sz, w, h, round(hx * sz / CANVAS), round(hy * sz / CANVAS),
                                     SPIN_DELAY if frames > 1 else 0, to_xcursor_pixels(rgba)))
                write_xcursor(os.path.join(cur, name), imgs)
                for a in aliases:
                    if not os.path.exists(os.path.join(cur, a)):
                        os.symlink(name, os.path.join(cur, a))
            # small pictures for Settings > Appearance > Cursor (the shell cannot show XCursor files itself)
            prev = os.path.join(theme, "preview"); os.makedirs(prev, exist_ok=True)
            for name in PREVIEW:
                with open(os.path.join(tmp, "p.svg"), "w") as fh: fh.write(shape_svgs(name, fac)[0])
                subprocess.run(["rsvg-convert", "-w", "64", "-h", "64", os.path.join(tmp, "p.svg"), "-o", os.path.join(prev, name + ".png")], check=True)
            with open(os.path.join(theme, "index.theme"), "w") as fh:
                fh.write(f"[Icon Theme]\nName=MachineSpirit {s['name']}\nComment=MachineSpirit cursors, {s['name']} livery\n")
            if have_hc:
                with open(os.path.join(tmp, fac, "manifest.hl"), "w") as fh:
                    fh.write(f"name = MachineSpirit-{s['name']}\ndescription = MachineSpirit cursors, {s['name']} livery\n"
                             f"version = 1.0\ncursors_directory = hyprcursors\n")
                subprocess.run(["hyprcursor-util", "--create", os.path.join(tmp, fac), "--output", tmp],
                               check=True, capture_output=True)
                made = os.path.join(tmp, f"theme_MachineSpirit-{s['name']}")
                shutil.copy(os.path.join(made, "manifest.hl"), theme)
                shutil.copytree(os.path.join(made, "hyprcursors"), os.path.join(theme, "hyprcursors"))
            print(theme)


def main(argv):
    if len(argv) >= 2 and argv[0] == "svg":
        out = argv[1]; os.makedirs(out, exist_ok=True)
        for fac in FACTIONS:
            for name in CATALOG:
                docs = shape_svgs(name, fac)
                with open(os.path.join(out, f"{fac}-{name}.svg"), "w") as fh: fh.write(docs[0])
        return 0
    if len(argv) >= 2 and argv[0] == "build":
        out, facs, sizes, hc = argv[1], [], SIZES, True
        i = 2
        while i < len(argv):
            if argv[i] == "--faction": facs.append(argv[i + 1]); i += 2
            elif argv[i] == "--sizes": sizes = tuple(int(x) for x in argv[i + 1].split(",")); i += 2
            elif argv[i] == "--no-hyprcursor": hc = False; i += 1
            else: print(f"unknown option {argv[i]}", file=sys.stderr); return 2
        if not shutil.which("rsvg-convert"):
            print("make_cursors: rsvg-convert (librsvg) is needed", file=sys.stderr); return 1
        build(out, facs or list(FACTIONS), sizes, hc)
        return 0
    print(__doc__, file=sys.stderr); return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
