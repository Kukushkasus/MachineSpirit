// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// The parts of a window come up one after another, in the faction's manner, instead of all at once:
//   mechanicus    each part drops into place with a relay's kick while its lamp warms (a dip in the light, then full)
//   ultramarines  each slides in from the left and stops dead, crisp and in order
//   necrons       each phases in: it shimmers sideways and its light wavers before it holds
//   khorne        each falls a short way and lands heavily, bouncing once
// Give it `items` (the parts, in reading order) and call play() when the window opens. It drives only a Translate
// and the opacity of each part; a part whose opacity is bound to something else declares `property real reveal: 1`
// and multiplies it into its own opacity.
// Everything is shown at once with reduced motion or low power.
Item {
    id: root
    property var items: []
    property string kit: Theme.kit
    property int gap: Theme.dStagger
    property int each: Math.max(1, Math.round(Theme.dEnter * 0.85))
    property real t: 1e6                 // the clock: large means everything is in place
    readonly property bool running: anim.running
    visible: false; width: 0; height: 0

    function play() {
        if (!Theme.motionEnabled || items.length === 0) { anim.stop(); t = 1e6; return }
        anim.stop(); t = 0
        anim.to = (items.length - 1) * gap + each
        anim.duration = anim.to
        anim.start()
    }
    function finish() { anim.stop(); t = 1e6 }
    NumberAnimation { id: anim; target: root; property: "t"; from: 0; easing.type: Easing.Linear; onFinished: root.t = 1e6 }

    function prog(i) { return Math.max(0, Math.min(1, (t - i * gap) / each)) }
    function backOut(p, s) { const q = p - 1; return q * q * ((s + 1) * q + s) + 1 }
    function alpha(p) {
        if (p >= 1) return 1
        if (kit === "mechanicus") return p < 0.28 ? p / 0.28 * 0.8 : p < 0.42 ? 0.8 - (p - 0.28) / 0.14 * 0.4 : Math.min(1, 0.4 + (p - 0.42) / 0.3 * 0.6)
        if (kit === "necrons") return Math.min(1, p * 1.4) * (0.75 + 0.25 * Math.cos(p * 26))
        if (kit === "khorne") return Math.min(1, p * 3)
        return Math.min(1, p * 2.2)
    }
    function dx(p) {
        if (p >= 1) return 0
        if (kit === "ultramarines") return -16 * Math.pow(1 - p, 4)
        if (kit === "necrons") return 7 * (1 - p) * Math.sin(p * 34)
        return 0
    }
    function dy(p) {
        if (p >= 1) return 0
        if (kit === "mechanicus") return 9 * (1 - backOut(p, 2.2))
        if (kit === "khorne") return -16 * (1 - backOut(p, 2.8))
        return 0
    }

    // Each part gets one Translate of its own, made the first time it is staggered and owned by the part, so it
    // goes when the part goes. A part's transform list is only ever touched to add that Translate to a living part:
    // rewriting the list of a part that is being torn down (a closing window) left other transforms pointing at
    // a dead item, and Qt crashed when those were deleted.
    property var bound: []      // [{item, tr}] currently driven
    onItemsChanged: attach()
    Component.onCompleted: attach()
    function translateOf(it) {
        for (const b of bound) if (b.item === it && b.tr) return b.tr
        for (let k = 0; k < it.transform.length; k++) if (it.transform[k].objectName === "staggerShift") return it.transform[k]
        return null
    }
    function attach() {
        const made = []
        for (let i = 0; i < items.length; i++) {
            const it = items[i]
            if (!it) continue
            const idx = i
            let tr = translateOf(it)
            if (!tr) {
                tr = Qt.createQmlObject('import QtQuick; Translate { objectName: "staggerShift" }', it)
                const keep = []
                for (let k = 0; k < it.transform.length; k++) keep.push(it.transform[k])
                keep.push(tr)
                it.transform = keep
            }
            tr.x = Qt.binding(() => root.dx(root.prog(idx)))
            tr.y = Qt.binding(() => root.dy(root.prog(idx)))
            // a part that owns its opacity exposes `reveal` (0..1) and multiplies it in itself
            if ("reveal" in it) it.reveal = Qt.binding(() => root.alpha(root.prog(idx)))
            else it.opacity = Qt.binding(() => root.alpha(root.prog(idx)))
            made.push({item: it, tr: tr})
        }
        // parts no longer in the list stay where they are: their Translate rests at zero, their light at full
        for (const b of bound) {
            if (!b.item || made.some(m => m.item === b.item)) continue
            if (b.tr) { b.tr.x = 0; b.tr.y = 0 }
            if ("reveal" in b.item) b.item.reveal = 1; else b.item.opacity = 1
        }
        bound = made
    }
    // nothing of the parts is touched here: they may be halfway through their own destruction
    Component.onDestruction: { for (const b of bound) if (b.tr) { b.tr.x = 0; b.tr.y = 0 } }
}
