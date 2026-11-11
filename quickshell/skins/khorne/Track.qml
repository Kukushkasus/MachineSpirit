// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne strip: few heavy iron blocks in a brass-lipped trough; the lit ones glow like iron in the fire,
// hotter toward the top, each with a notch cut in its head.
Item {
    id: root
    required property Item host
    readonly property int segments: Math.max(8, Math.round(width / 22))
    Poly {
        x: -4; y: -4; width: parent.width + 8; height: parent.height + 8
        points: Skin.iron(width, height, 3, 0)
        upper: Qt.darker(Theme.metalLo, 1.5); lower: Qt.darker(Theme.metal, 1.4)
        stroke: root.host.hovered ? Theme.brass : Qt.darker(Theme.brassLo, 1.1); strokeWidth: 1.2
    }
    Row {
        anchors.fill: parent; spacing: 3
        Repeater {
            model: root.segments
            Poly {
                required property int index
                readonly property real step: (index + 1) / root.segments
                readonly property bool on: root.host.level >= step - 0.5 / root.segments
                width: (root.width - (root.segments - 1) * 3) / root.segments; height: root.height
                points: [[0, 0], [width * 0.4, 0], [width * 0.5, 3], [width * 0.6, 0], [width, 0], [width, height], [0, height]]
                upper: on ? (root.host.off ? Qt.alpha(Theme.glow, 0.25) : Qt.lighter(Theme.glow, 1 + 0.25 * step)) : Qt.alpha(Theme.metal, 0.6)
                lower: on ? (root.host.off ? Qt.alpha(Theme.glow, 0.15) : Qt.tint(Theme.rust, Qt.alpha(Theme.glow, 0.3 + 0.5 * step))) : Qt.alpha(Theme.metalLo, 0.8)
            }
        }
    }
}
