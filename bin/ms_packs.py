# [ PURITY SEAL ] A theme pack is data. It never becomes code.
"""Theme packs: discovery and validation.

A pack is a folder with `theme.json` and pictures. It selects one of the decor kits built into the shell
and tunes it with values; it cannot carry QML, JavaScript or commands. Everything read from a pack goes
through `normalise()`, which keeps only the keys of the schema and rejects unsafe paths and resources.
"""
import json, os, re
from pathlib import Path

SCHEMA = 2
SCHEMAS = (1, 2)           # schema 1 packs (0.2.x themes) are read as schema 2 with every skin slot on their kit
SKIN_SLOTS = ("frame", "card", "control", "screen", "bar", "instrument", "glyph", "type")
HOME = Path.home()
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
SHARE = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share"))
BUILTIN = CONFIG / "quickshell/machinespirit/themes"
USER = SHARE / "machinespirit/themes"
DEFAULT_ID = "mechanicus"

KITS = ("mechanicus", "ultramarines", "necrons", "khorne")
IMAGES = {".png", ".jpg", ".jpeg", ".webp", ".svg"}
MAX_JSON = 64 * 1024
MAX_IMAGE = 24 * 1024 * 1024
MAX_SVG = 1024 * 1024
MAX_TOTAL = 96 * 1024 * 1024
MAX_FILES = 32
MAX_WALLPAPERS = 8

HEX = re.compile(r"#[0-9a-fA-F]{6}")
IDENT = re.compile(r"[a-z][a-z0-9-]{1,31}")
ANCHORS = ("energy", "danger", "dangerText", "warn", "seal", "trimLight", "trimDark")
MATERIALS = ("metal_lo", "metal", "metal_hi", "metal_edge", "brass_lo", "brass", "brass_hi",
             "glass", "glass_hi", "glow", "glow_dim", "glow_faint")
# Decorative words only. Functions that must stay plain in every faction (settings, errors, power,
# network, security, lock) have no key here, so a pack cannot rename them.
LEXICON = ("panelTitle", "busTitle", "logTitle", "logEmpty", "logCleared", "counter", "uptime",
           "launcherTitle", "launcherPrompt", "powerTitle", "archiveTitle", "clock", "weather",
           "resources", "media", "notes", "sector", "greeting", "updated", "restarted", "motto")
LITANY_MAX = 12
MOTION = {"character": ("mechanical", "precise", "phase", "heavy"), }
EFFECTS = ("discharge", "screenLife", "particles", "messages", "glyphs")


class PackError(ValueError):
    pass


def _text(v, limit, what):
    if not isinstance(v, str) or not v.strip() or len(v) > limit or any(ord(c) < 32 for c in v):
        raise PackError(f"{what} must be a short line of text")
    return v.strip()


def _hex(v, what):
    if not isinstance(v, str) or not HEX.fullmatch(v):
        raise PackError(f"{what} must be a colour like #1a2b3c")
    return v.lower()


def _num(v, lo, hi, what):
    if type(v) not in (int, float) or v != v or not lo <= v <= hi:
        raise PackError(f"{what} must be {lo}..{hi}")
    return v


def _resource(root, rel, what, limit=MAX_IMAGE):
    """A picture inside the pack folder: relative, no links, a known format, a sane size."""
    if not isinstance(rel, str) or not rel or len(rel) > 160 or "\\" in rel or "\0" in rel:
        raise PackError(f"{what}: bad path")
    p = Path(rel)
    if p.is_absolute() or ".." in p.parts or any(part.startswith(".") for part in p.parts):
        raise PackError(f"{what}: the path must stay inside the pack")
    full = root / p
    cur = root
    for part in p.parts:                      # no link anywhere on the way, the folder itself included
        cur = cur / part
        if cur.is_symlink():
            raise PackError(f"{what}: links are not allowed")
    if not full.is_file():
        raise PackError(f"{what}: {rel} is missing")
    if full.suffix.lower() not in IMAGES:
        raise PackError(f"{what}: only png, jpg, webp and svg pictures are allowed")
    size = full.stat().st_size
    svg = full.suffix.lower() == ".svg"
    if size == 0 or size > (MAX_SVG if svg else limit):
        raise PackError(f"{what}: {rel} is empty or too large")
    if svg:
        body = full.read_text(errors="replace").lower()
        if any(bad in body for bad in ("<script", "foreignobject", "javascript:", "<!entity", "<iframe")) \
                or re.search(r"""href\s*=\s*["'](?!#|data:image/)""", body) or re.search(r"\bon[a-z]+\s*=", body):
            raise PackError(f"{what}: {rel} contains scripts or outside references")
    else:
        head = full.read_bytes()[:16]
        ok = head.startswith(b"\x89PNG\r\n\x1a\n") or head.startswith(b"\xff\xd8\xff") or (head[:4] == b"RIFF" and head[8:12] == b"WEBP")
        if not ok:
            raise PackError(f"{what}: {rel} is not the picture its name claims")
    return str(full.resolve())


def normalise(raw, root):
    """Validate one pack. Returns the plain dictionary the shell reads; raises PackError otherwise."""
    root = Path(root)
    if not isinstance(raw, dict):
        raise PackError("theme.json must be an object")
    if type(raw.get("schema")) is not int:
        raise PackError("theme.json has no schema number")
    if raw["schema"] not in SCHEMAS:
        raise PackError(f"made for pack schema {raw['schema']}; this MachineSpirit reads schemas {', '.join(map(str, SCHEMAS))}")
    out = {"schema": SCHEMA}
    if not isinstance(raw.get("id"), str) or not IDENT.fullmatch(raw["id"]):
        raise PackError("id must be lowercase letters, digits and dashes")
    if raw["id"] != root.name:
        raise PackError("id must match the folder name")
    out["id"] = raw["id"]
    out["name"] = _text(raw.get("name"), 48, "name")
    out["tagline"] = _text(raw.get("tagline", out["name"]), 120, "tagline")
    out["author"] = _text(raw.get("author", "unknown"), 60, "author")
    out["version"] = _text(str(raw.get("version", "1")), 16, "version")
    if raw.get("kit") not in KITS:
        raise PackError("kit must be one of: " + ", ".join(KITS))
    out["kit"] = raw["kit"]

    pal = raw.get("palette")
    if not isinstance(pal, dict):
        raise PackError("palette is required")
    band = pal.get("band", [0, 360]); accept = pal.get("accept", band)
    for name, pair in (("band", band), ("accept", accept)):
        if not isinstance(pair, list) or len(pair) != 2: raise PackError(f"palette.{name} must be two hue angles")
        for x in pair: _num(x, 0, 360, f"palette.{name}")
    light = pal.get("lightness", [0.38, 0.62])
    if not isinstance(light, list) or len(light) != 2: raise PackError("palette.lightness must be two numbers")
    for x in light: _num(x, 0.1, 0.9, "palette.lightness")
    if light[0] > light[1]: raise PackError("palette.lightness: the first number must be the smaller one")
    scheme = pal.get("scheme", "scheme-tonal-spot")
    if scheme not in ("scheme-tonal-spot", "scheme-content", "scheme-neutral", "scheme-fidelity", "scheme-vibrant", "scheme-expressive"):
        raise PackError("palette.scheme is not a known matugen scheme")
    anchors = pal.get("anchors")
    if not isinstance(anchors, dict): raise PackError("palette.anchors is required")
    # skin: which built-in livery draws each structural slot. Names only, from the same whitelist as the kit;
    # a slot left out follows the kit. Schema 1 has no skin section and gets the kit everywhere.
    skin = raw.get("skin", {}) if raw["schema"] >= 2 else {}
    if not isinstance(skin, dict):
        raise PackError("skin must be an object")
    for k, v in skin.items():
        if k not in SKIN_SLOTS:
            raise PackError(f"skin.{k}: unknown slot")
        if v not in KITS:
            raise PackError(f"skin.{k}: unknown livery {v!r}")
    out["skin"] = {k: skin.get(k, out["kit"]) for k in SKIN_SLOTS}
    out["palette"] = {
        "seed": _hex(pal.get("seed"), "palette.seed"), "band": band, "accept": accept, "lightness": light,
        "minSaturation": _num(pal.get("minSaturation", 0.45), 0, 1, "palette.minSaturation"),
        "scheme": scheme,
        "anchors": {k: _hex(anchors.get(k), "palette.anchors." + k) for k in ANCHORS},
    }
    mats = raw.get("materials", {})
    if not isinstance(mats, dict): raise PackError("materials must be an object")
    out["materials"] = {k: _hex(mats[k], "materials." + k) for k in MATERIALS if k in mats}

    lex = raw.get("lexicon", {})
    if not isinstance(lex, dict): raise PackError("lexicon must be an object")
    out["lexicon"] = {k: _text(lex[k], 64, "lexicon." + k) for k in LEXICON if k in lex}
    lit = raw.get("litanies", [])
    if not isinstance(lit, list) or len(lit) > LITANY_MAX: raise PackError(f"litanies: at most {LITANY_MAX} lines")
    out["litanies"] = [_text(x, 64, "litanies") for x in lit]

    mo = raw.get("motion", {})
    if not isinstance(mo, dict): raise PackError("motion must be an object")
    ch = mo.get("character", "mechanical")
    if ch not in MOTION["character"]: raise PackError("motion.character is unknown")
    out["motion"] = {"character": ch, "scale": _num(mo.get("scale", 1), 0.6, 1.8, "motion.scale"),
                     "overshoot": _num(mo.get("overshoot", 0), 0, 3, "motion.overshoot")}

    fx = raw.get("effects", {})
    if not isinstance(fx, dict): raise PackError("effects must be an object")
    out["effects"] = {}
    for k in EFFECTS:
        v = fx.get(k, True)
        if type(v) is bool:
            out["effects"][k] = v
        elif isinstance(v, list) and len(v) == 2:      # seconds between occurrences: [shortest, longest]
            a, b = _num(v[0], 2, 3600, "effects." + k), _num(v[1], 2, 3600, "effects." + k)
            if a > b: raise PackError(f"effects.{k}: the first number must be the smaller one")
            out["effects"][k] = [a, b]
        else:
            raise PackError(f"effects.{k} must be true, false or [min, max] seconds")

    walls = raw.get("wallpapers", [])
    if not isinstance(walls, list) or len(walls) > MAX_WALLPAPERS: raise PackError(f"wallpapers: at most {MAX_WALLPAPERS}")
    out["wallpapers"] = []
    for w in walls:
        if not isinstance(w, dict): raise PackError("wallpapers: each entry is {file, name}")
        out["wallpapers"].append({"file": _resource(root, w.get("file"), "wallpaper"),
                                  "name": _text(w.get("name", Path(str(w.get("file"))).stem), 48, "wallpaper name"),
                                  "draft": bool(w.get("draft", False))})
    out["preview"] = _resource(root, raw["preview"], "preview", 4 * 1024 * 1024) if raw.get("preview") else ""

    # the folder as a whole: nothing but pictures and theme.json counts, and not too much of it
    total = 0; count = 0
    for p in root.rglob("*"):
        if p.is_symlink(): raise PackError("links are not allowed inside a pack")
        if p.is_file():
            count += 1; total += p.stat().st_size
            if count > MAX_FILES: raise PackError(f"more than {MAX_FILES} files")
            if total > MAX_TOTAL: raise PackError("the pack is too large")
            if p.name != "theme.json" and p.suffix.lower() not in IMAGES | {".json", ".md", ".txt"}:
                raise PackError(f"{p.name}: only pictures, theme.json and notes belong in a pack")
    return out


def load(root):
    root = Path(root)
    f = root / "theme.json"
    if root.is_symlink() or f.is_symlink(): raise PackError("links are not allowed")
    if not f.is_file(): raise PackError("theme.json is missing")
    if f.stat().st_size > MAX_JSON: raise PackError("theme.json is too large")
    try:
        raw = json.loads(f.read_text())
    except (ValueError, UnicodeDecodeError) as e:
        raise PackError("theme.json is not valid JSON: " + str(e)[:80])
    return normalise(raw, root)


def roots():
    return [(BUILTIN, True), (USER, False)]


def catalogue():
    """Every pack folder found, good or not: [{id, builtin, ok, error, pack}]. Built-in ids cannot be shadowed."""
    found = []; seen = set()
    for base, builtin in roots():
        if not base.is_dir(): continue
        for d in sorted(base.iterdir()):
            if not d.is_dir() and not d.is_symlink(): continue
            entry = {"id": d.name, "builtin": builtin, "ok": False, "error": "", "pack": None}
            if d.name in seen:
                entry["error"] = "a built-in pack already uses this id"
            else:
                try:
                    entry["pack"] = load(d); entry["ok"] = True
                except PackError as e:
                    entry["error"] = str(e)
                except OSError as e:
                    entry["error"] = "cannot be read: " + str(e)[:80]
            if entry["ok"] or d.name not in seen: seen.add(d.name)
            found.append(entry)
    return found


def find(pack_id):
    """The validated pack, or PackError naming why it cannot be used."""
    if not isinstance(pack_id, str) or not IDENT.fullmatch(pack_id): raise PackError("unknown pack")
    for base, _ in roots():
        d = base / pack_id
        if d.is_dir() or d.is_symlink(): return load(d)
    raise PackError(f"pack {pack_id} is not installed")
