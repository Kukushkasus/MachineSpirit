// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron housing: a monolith of dark living metal. A deep cut at the upper left, a lesser one at the lower
// right, a slot let into the left flank of a large window. No rivets, no bolts: energy runs in channels let
// into the edge, a shard hangs free off the great cut, and a column of glyphs is set into the right flank.
Item {
    id: root
    required property Item host
    readonly property real c: Math.max(5, root.host.radius * 1.1)
    readonly property bool big: root.host.role === "window" || root.host.role === "toast"
    readonly property bool dressed: Theme.ornaments > 0 && width > 120 && height > 60
    readonly property var outline: Skin.monolith(width, height, c, big)
    readonly property real a: c * 1.6

    Poly {   // the body: dark metal, a little light caught at the top
        anchors.fill: parent
        points: root.outline
        upper: Qt.lighter(Theme.metal, 1.12); lower: Qt.darker(Theme.metal, 1.7)
        stroke: Qt.alpha(Theme.glowDim, 0.5); strokeWidth: 1
    }
    Strokes {   // the channel round the great cut, and its twin at the lower right
        anchors.fill: parent
        visible: root.width > 40 && root.height > 30
        readonly property real m: 3.2
        readonly property real lx: Math.min(root.width * 0.42, 160)
        readonly property real ly: Math.min(root.height * 0.45, 80)
        color: Qt.alpha(Theme.glow, 0.7); lineWidth: 1.2
        lines: [[m, root.a + ly, m, root.a + 1.3, root.a + 1.3, m, root.a + lx, m],
                [root.width - m, root.height - root.c - ly * 0.6, root.width - m, root.height - root.c - 1.3, root.width - root.c - 1.3, root.height - m, root.width - root.c - lx * 0.5, root.height - m]]
    }
    Repeater {   // nodes where the channels end
        model: root.width > 40 && root.height > 30 ? 2 : 0
        Rectangle {
            required property int index
            readonly property real lx: Math.min(root.width * 0.42, 160)
            width: 4; height: 4; radius: 2; color: Theme.glow
            x: index === 0 ? root.a + lx - 2 : root.width - root.c - lx * 0.5 - 2
            y: index === 0 ? 3.2 - 2 : root.height - 3.2 - 2
        }
    }
    Poly {   // a shard hanging free off the great cut
        visible: root.dressed
        x: -7; y: -7; width: root.a + 7; height: root.a + 7
        readonly property real k: root.a
        points: [[k * 0.32 + 7 - 3.5, k * 0.68 + 7 - 3.5], [k * 0.68 + 7 - 3.5, k * 0.32 + 7 - 3.5], [k * 0.5 + 7 - 8.5, k * 0.5 + 7 - 8.5]]
        upper: Qt.alpha(Theme.glowFaint, 0.9); lower: Qt.alpha(Theme.metal, 0.9)
        stroke: Qt.alpha(Theme.glow, 0.75); strokeWidth: 1
    }
    Column {   // glyphs set into the right flank
        visible: root.dressed && root.big && root.height > 260
        x: root.width - 6.5; y: root.c + 26; spacing: 9
        Repeater {
            model: Math.max(0, Math.min(6, Math.floor((root.height * 0.4) / 14)))
            Strokes {
                required property int index
                width: 5; height: 5; unit: 0.5; lineWidth: 0.9
                color: Qt.alpha(Theme.glow, 0.55)
                lines: Skin.glyphs[(index * 3 + Math.round(root.height)) % Skin.glyphs.length]
            }
        }
    }
}
