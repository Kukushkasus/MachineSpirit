// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus strip: segments in a dark well, the last tenth in danger red.
Item {
    id: root
    required property Item host
    readonly property int segments: Math.max(14, Math.round(width / 11))
    Rectangle { anchors { fill: parent; margins: -4 } radius: 4; color: Qt.darker(Theme.glass, 1.35)
        border { width: 1; color: Qt.alpha(Theme.glow, root.host.hovered ? 0.45 : 0.18) }
        Behavior on border.color { ColorAnimation { duration: Theme.dShort } } }
    Row {
        anchors.fill: parent; spacing: 3
        Repeater {
            model: root.segments
            Rectangle {
                required property int index
                readonly property real step: (index + 1) / root.segments
                width: (root.width - (root.segments - 1) * 3) / root.segments; height: root.height; radius: 1.5
                color: root.host.level >= step - 0.5 / root.segments
                    ? (root.host.off ? Qt.alpha(Theme.glow, 0.28) : (step > 0.9 ? Theme.rustText : Theme.glow))
                    : Qt.alpha(Theme.glow, 0.08)
            }
        }
    }
}
