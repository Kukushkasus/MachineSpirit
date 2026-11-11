// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron strip: a row of narrow leaning cells of light, thin brackets at its ends and no frame round it.
Item {
    id: root
    required property Item host
    readonly property int segments: Math.max(18, Math.round(width / 8))
    Strokes {
        x: -5; y: -4; width: parent.width + 10; height: parent.height + 8
        color: Qt.alpha(Theme.glowDim, root.host.hovered ? 0.95 : 0.55); lineWidth: 1
        lines: [[5, 0, 0, 0, 0, height, 5, height], [width - 5, 0, width, 0, width, height, width - 5, height]]
    }
    Row {
        anchors.fill: parent; spacing: 2
        // every cell leans: the row is sheared, not each cell drawn
        transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -0.45, 0, root.height * 0.45 / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
        Repeater {
            model: root.segments
            Rectangle {
                required property int index
                readonly property real step: (index + 1) / root.segments
                readonly property bool on: root.host.level >= step - 0.5 / root.segments
                width: (root.width - (root.segments - 1) * 2) / root.segments; height: root.height
                color: on ? (root.host.off ? Qt.alpha(Theme.glow, 0.25) : step > 0.9 ? Theme.rustText : Qt.alpha(Theme.glow, 0.55 + 0.45 * step))
                          : Qt.alpha(Theme.glowFaint, 0.25)
            }
        }
    }
}
