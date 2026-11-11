// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron well: a lit diamond standing in a ring of four short ticks; engaged, the diamond fills with light.
Item {
    id: root
    required property Item host
    Poly {
        anchors.fill: parent
        readonly property real c: width / 2
        points: [[c, 0], [width, c], [c, height], [0, c]]
        upper: root.host.lit ? Qt.alpha(Theme.glow, 0.26) : Qt.darker(Theme.glass, 1.4)
        lower: root.host.lit ? Qt.alpha(Theme.glowFaint, 0.5) : Qt.darker(Theme.metal, 1.6)
        stroke: root.host.lit ? Theme.glow : Qt.alpha(Theme.glowDim, 0.5); strokeWidth: root.host.lit ? 1.4 : 1
    }
    Strokes {
        anchors.fill: parent
        color: Qt.alpha(Theme.glowDim, root.host.lit ? 0.9 : 0.4); lineWidth: 1
        readonly property real c: width / 2
        lines: [[c, -4, c, -1], [c, height + 1, c, height + 4], [-4, c, -1, c], [width + 1, c, width + 4, c]]
    }
}
