// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines key: a square plate with cut corners. Under the pointer it lights blue; engaged it takes a
// gold edge and a gold bar along its foot. Round keys are square here too: nothing on the bridge is round.
Item {
    id: root
    required property Item host
    readonly property color tone: host.danger ? Theme.rustText : Theme.glow
    readonly property real a: host.pressed ? 0.26 : host.on ? 0.16 : host.hovered ? 0.12 : 0
    Poly {   // a solid key's enamel body
        visible: root.host.solid
        anchors.fill: parent
        points: Skin.chamfer(width, height, Math.min(5, height / 4))
        upper: Qt.lighter(Theme.metal, 1.12); lower: Qt.darker(Theme.metal, 1.3)
    }
    Poly {
        anchors.fill: parent
        points: Skin.chamfer(width, height, Math.min(5, height / 4))
        upper: Qt.alpha(root.tone, root.a * 1.2); lower: Qt.alpha(root.tone, root.a * 0.7)
        stroke: root.host.on ? Theme.brass : root.host.hovered || root.host.pressed ? Qt.alpha(Theme.brass, 0.75) : root.host.solid ? Qt.alpha(Theme.brass, 0.4) : "transparent"
        strokeWidth: 1
    }
    Rectangle {
        visible: root.host.on
        anchors { bottom: parent.bottom; bottomMargin: 2; horizontalCenter: parent.horizontalCenter }
        width: parent.width * 0.5; height: 2; color: Theme.brassHi
    }
}
