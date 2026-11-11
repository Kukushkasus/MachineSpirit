// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron key: the engaged sector is a leaning cell of light with a node above it; an occupied one shows a
// short lit bar at its foot.
Item {
    id: root
    required property Item host
    Poly {
        anchors.fill: parent
        points: Skin.lean(width, height, 5)
        upper: Qt.alpha(Theme.glow, 0.22); lower: Qt.alpha(Theme.glowFaint, 0.4)
        stroke: Theme.glow; strokeWidth: 1
        opacity: root.host.focused ? 1 : root.host.hovered ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
    }
    Rectangle {
        visible: root.host.focused
        anchors.horizontalCenter: parent.horizontalCenter; y: -4; width: 4; height: 4; rotation: 45; color: Theme.glow
    }
    Rectangle {
        visible: root.host.occupied && !root.host.focused
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
        width: 8; height: 1.5; color: Theme.glowDim
    }
}
