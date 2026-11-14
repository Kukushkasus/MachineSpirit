pragma Singleton
// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import Quickshell
import qs.common

// skin layer: every structural part is drawn by one of four built-in liveries in skins/<style>/. Packs pick
// a style per slot from this whitelist, never a path. Only decoration is swapped, user state survives
Singleton {
    id: root
    readonly property var styles: ["mechanicus", "ultramarines", "necrons", "khorne"]
    readonly property var slots: ["frame", "card", "control", "screen", "bar", "instrument", "glyph", "type"]
    // style for one slot: the pack's choice when it is a known style, else the pack's kit
    function of(slot) {
        const s = Theme.pack.skin ? Theme.pack.skin[slot] : undefined
        return styles.includes(s) ? s : Theme.kit
    }
    readonly property string frame: of("frame")
    readonly property string card: of("card")
    readonly property string control: of("control")
    readonly property string screen: of("screen")
    readonly property string bar: of("bar")
    readonly property string instrument: of("instrument")
    readonly property string glyph: of("glyph")
    readonly property string type: of("type")

    // ---- type. Faction faces ship with the shell and load from its own folder, nothing system-wide.
    // Plex Condensed until a face is loaded, and for Cyrillic (none of the three has it)
    FontLoader { id: cinzel; source: Qt.resolvedUrl("../assets/fonts/Cinzel.ttf") }
    FontLoader { id: michroma; source: Qt.resolvedUrl("../assets/fonts/Michroma.ttf") }
    FontLoader { id: grenze; source: Qt.resolvedUrl("../assets/fonts/GrenzeGotisch.ttf") }
    function ready(f) { return f.status === FontLoader.Ready ? f.name : "" }
    readonly property string fontDisplayRaw: type === "ultramarines" ? ready(cinzel) : type === "necrons" ? ready(michroma) : type === "khorne" ? ready(grenze) : ""
    readonly property string fontDisplay: fontDisplayRaw || Theme.fontNum
    readonly property bool displayIsOwn: fontDisplayRaw !== ""
    // the face for a given string: the faction's when it can write it, Plex Condensed otherwise
    // Grenze's black-letter capitals make Roman numerals unreadable (IV reads as DV), so those stay in Plex
    function display(text) {
        if (!displayIsOwn || !/^[\x00-\u024f\u2000-\u206f]*$/.test(text || "")) return Theme.fontNum
        if (type === "khorne" && /^\s*[IVXLC]+\s*$/.test(text || "")) return Theme.fontNum
        return fontDisplay
    }
    // how titles are set: Cinzel needs air and no forced weight, Michroma is wide already, Grenze is heavy and tight
    readonly property int titleWeight: type === "ultramarines" ? Font.DemiBold : type === "necrons" ? Font.Normal : type === "khorne" ? Font.Black : Font.Bold
    readonly property real titleSpacing: type === "ultramarines" ? 3.5 : type === "necrons" ? 2.2 : type === "khorne" ? 1.2 : 3
    readonly property real titleScale: type === "necrons" ? 0.82 : type === "khorne" ? 1.18 : 1     // Michroma runs wide, Grenze runs small
    readonly property int titleCase: type === "khorne" ? Font.MixedCase : Font.AllUppercase
    // readouts: the faction's face carries the numbers too (Cinzel's Roman figures, Michroma's wide ones,
    // Grenze's forged ones); Mechanicus keeps its condensed tubes
    readonly property string numFont: type !== "mechanicus" && displayIsOwn ? fontDisplay : Theme.fontNum
    readonly property real numScale: numFont === Theme.fontNum ? 1 : type === "necrons" ? 0.74 : type === "khorne" ? 1.12 : 0.92
    readonly property int numWeight: numFont === Theme.fontNum ? Font.Medium : type === "khorne" ? Font.Bold : type === "ultramarines" ? Font.DemiBold : Font.Normal
    readonly property string fontIcon: control === "ultramarines" || control === "necrons" ? "Material Symbols Sharp" : "Material Symbols Outlined"
    readonly property int iconWeight: control === "necrons" ? 300 : control === "khorne" ? 600 : 400

    // ---- geometry: polygons for the cut-cornered liveries. Points are [x, y] pairs; Poly closes them.
    // chamfer: four equal cuts (ultramarines plate)
    function chamfer(w, h, c) {
        c = Math.max(0, Math.min(c, w / 2, h / 2))
        return [[c, 0], [w - c, 0], [w, c], [w, h - c], [w - c, h], [c, h], [0, h - c], [0, c]]
    }
    // two cuts only, top left and bottom right: the plate's armour line
    function bevel2(w, h, c) {
        c = Math.max(0, Math.min(c, w / 2, h / 2))
        return [[c, 0], [w, 0], [w, h - c], [w - c, h], [0, h], [0, c]]
    }
    // monolith: a deep cut top left, a lesser one bottom right, the other corners square, and a slot let
    // into the left flank. Nothing in it is symmetrical (necrons)
    function monolith(w, h, c, slot) {
        c = Math.max(0, Math.min(c, w / 3, h / 3))
        const a = c * 1.6, b = c, p = []
        p.push([a, 0], [w - c * 0.35, 0], [w, c * 0.35], [w, h - b], [w - b, h], [c * 0.35, h], [0, h - c * 0.35])
        if (slot && h > c * 6) { const m = h * 0.56, s = c * 0.7, d = Math.min(4, c * 0.3); p.push([0, m + s], [d, m + s - d], [d, m - s + d], [0, m - s]) }
        p.push([0, a])
        return p
    }
    // parallelogram: leans right by `k` (necrons keys)
    function lean(w, h, k) { k = Math.min(k, w / 3); return [[k, 0], [w, 0], [w - k, h], [0, h]] }
    // iron: small cuts at the corners and, when `teeth` > 0, a saw edge along the foot (khorne)
    function iron(w, h, c, teeth) {
        c = Math.max(0, Math.min(c, w / 2, h / 2))
        const p = [[c, 0], [w - c, 0], [w, c], [w, h - c]]
        if (teeth > 0 && w > 6 * teeth) {
            const n = Math.max(3, Math.round((w - 2 * c) / (teeth * 3.2))), step = (w - 2 * c) / n
            p.push([w - c, h])
            for (let i = n - 1; i >= 0; i--) {
                const x0 = c + i * step
                p.push([x0 + step * 0.62, h], [x0 + step * 0.5, h - teeth], [x0 + step * 0.38, h])
            }
            p.push([c, h])
        } else p.push([w - c, h], [c, h])
        p.push([0, h - c], [0, c])
        return p
    }
    // a shape built at a margin `m` inside a w x h box: the outline function is called for the smaller box and
    // the points are shifted back, so a rim and its body share one shape. `cut` shrinks the corner measure.
    function at(fn, w, h, m, c, extra) {
        const pts = fn(w - 2 * m, h - 2 * m, Math.max(0, c - m * 0.42), extra)
        return pts.map(p => [p[0] + m, p[1] + m])
    }
    // the same outline shrunk by `m` on every side, for a rim or the glass inside it. Good enough for the
    // convex shapes used here: each point moves toward the box centre on both axes.
    function inset(pts, w, h, m) {
        return pts.map(p => [p[0] + (p[0] < w / 2 ? m : p[0] > w / 2 ? -m : 0), p[1] + (p[1] < h / 2 ? m : p[1] > h / 2 ? -m : 0)])
    }
    // the outline a style gives a box of this size; `size` is the style's corner measure
    function outline(style, w, h, size, opts) {
        opts = opts || {}
        if (style === "ultramarines") return chamfer(w, h, size)
        if (style === "necrons") return monolith(w, h, size, !!opts.slot)
        if (style === "khorne") return iron(w, h, size * 0.55, opts.teeth || 0)
        return null     // mechanicus: rounded rectangles
    }
    // a fixed pseudo-random number per size, so wear marks and glyphs sit differently on each part and never move
    function hash(w, h, i) { return ((Math.round(w) * 9301 + Math.round(h) * 49297 + i * 7919) % 233280) / 233280 }
    // necron glyphs: original marks made of strokes on a 10 x 10 grid, used as decoration only
    readonly property var glyphs: [
        [[5, 0, 5, 10], [2, 3, 8, 3], [2, 7, 8, 7]],
        [[0, 5, 5, 0], [5, 0, 10, 5], [5, 0, 5, 10]],
        [[2, 0, 2, 10], [2, 5, 8, 5], [8, 2, 8, 8]],
        [[0, 2, 10, 2], [5, 2, 5, 10], [2, 10, 8, 10]],
        [[0, 10, 5, 0], [5, 0, 10, 10], [3, 6, 7, 6]],
        [[0, 0, 10, 0], [0, 5, 6, 5], [0, 10, 10, 10], [0, 0, 0, 10]],
        [[5, 0, 5, 4], [5, 6, 5, 10], [0, 5, 10, 5]],
        [[2, 0, 8, 0], [8, 0, 8, 10], [2, 10, 8, 10], [2, 4, 5, 6]]
    ]
}
