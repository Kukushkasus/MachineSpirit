// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne bar section: a slab of blackened iron hung from the screen edge, its foot cut into brass teeth and a
// row of rivets above them, a brass spike jutting from each inner end. The centre slab has a jaw: one long
// fang under the sectors. The forge glass is set into the iron.
Item {
    id: root
    required property Item host
    readonly property bool heart: host.part === "heart"
    readonly property real w: width
    readonly property real d: 37                    // the iron's foot; the teeth hang below it
    function teeth() {
        const p = [[0, 0], [w, 0], [w, d]], n = Math.max(3, Math.round((w - 8) / 19)), s = (w - 8) / n
        for (let i = n - 1; i >= 0; i--) {
            const x0 = 4 + i * s, mid = x0 + s / 2
            const deep = root.heart && Math.abs(mid - w / 2) < s * 0.6
            p.push([x0 + s * 0.85, d], [mid, d + (deep ? 22 : 9)], [x0 + s * 0.15, d])
        }
        p.push([0, d])
        return p
    }
    Poly { width: root.w; height: 62; points: root.teeth(); upper: Theme.brass; lower: Qt.darker(Theme.brassLo, 1.3); stroke: Qt.darker(Theme.brassLo, 1.8); strokeWidth: 0.8 }
    Poly { x: 2.5; width: root.w - 5; height: root.d - 2.5; points: Skin.iron(width, height, 3, 0); upper: Qt.darker(Theme.metal, 1.1); lower: Qt.darker(Theme.metal, 1.9) }
    Poly {   // the forge glass
        x: 7; y: 0; width: root.w - 14; height: root.d - 6
        points: Skin.iron(width, height, 3, 0)
        upper: Qt.darker(Theme.glass, 1.2); lower: Qt.tint(Theme.glass, Qt.alpha(Theme.rust, 0.28))
        stroke: Qt.alpha(Theme.brassLo, 0.8); strokeWidth: 1
    }
    Repeater {   // rivets above the teeth
        model: Math.max(2, Math.floor((root.w - 20) / 38) + 1)
        Rectangle {
            required property int index
            readonly property int n: Math.max(2, Math.floor((root.w - 20) / 38) + 1)
            x: 10 + index * (root.w - 20) / Math.max(1, n - 1) - 2.25; y: root.d - 6; width: 4.5; height: 4.5; radius: 2.25
            gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
        }
    }
    Repeater {   // spikes off the inner ends
        model: Theme.ornaments > 0 ? 2 : 0
        Poly {
            required property int index
            readonly property bool r: index === 1
            visible: root.heart || (root.host.part === "left" ? r : !r)
            x: r ? root.w - 2 : -16; y: 10; width: 18; height: 14
            points: r ? [[0, 0], [18, 7], [0, 14], [4, 7]] : [[18, 0], [0, 7], [18, 14], [14, 7]]
            upper: Theme.brassHi; lower: Theme.brassLo
        }
    }
}
