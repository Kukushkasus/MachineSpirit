// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne key: a block of iron with cut corners set into the plate. Under the pointer the iron warms; pressed
// it sinks; engaged it glows red through and a brass lip shows at its foot.
Item {
    id: root
    required property Item host
    readonly property color tone: host.danger ? Theme.rustText : Theme.glow
    readonly property bool shown: host.hovered || host.pressed || host.on || host.solid
    Poly {
        anchors.fill: parent
        anchors.topMargin: root.host.pressed ? 1 : 0
        points: Skin.iron(width, height, Math.min(4, height / 5), 0)
        upper: Qt.alpha(Theme.metal, root.shown ? 0.9 : 0)
        lower: Qt.tint(Qt.alpha(Theme.metalLo, root.shown ? 0.9 : 0), Qt.alpha(root.tone, root.host.on ? 0.35 : root.host.pressed ? 0.3 : root.host.hovered ? 0.16 : 0))
        stroke: root.shown ? Qt.darker(Theme.brassLo, root.host.on ? 0.8 : 1.2) : "transparent"; strokeWidth: 1
    }
    Rectangle {
        visible: root.host.on || root.host.hovered
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
        height: 2; color: root.host.on ? Theme.brassHi : Theme.brassLo
    }
}
