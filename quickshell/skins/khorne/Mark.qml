// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne key: the engaged sector is a block of iron glowing red through, under a brass lip; an occupied one
// carries a notch of brass at its foot.
Item {
    id: root
    required property Item host
    Poly {
        anchors.fill: parent
        points: Skin.iron(width, height, 3, 0)
        upper: Qt.tint(Theme.metalLo, Qt.alpha(Theme.rust, 0.6)); lower: Qt.tint(Theme.metalLo, Qt.alpha(Theme.rustText, 0.55))
        stroke: Theme.brass; strokeWidth: 1.2
        opacity: root.host.focused ? 1 : root.host.hovered ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
    }
    Poly {
        visible: root.host.occupied && !root.host.focused
        anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 4; width: 6; height: 4
        points: [[0, 0], [6, 0], [3, 4]]
        upper: Theme.brass; lower: Theme.brassLo
    }
}
