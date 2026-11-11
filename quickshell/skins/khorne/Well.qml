// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne well: an octagonal iron socket in a brass ring; engaged, embers glow in it.
Item {
    id: root
    required property Item host
    Poly {
        anchors.fill: parent
        points: Skin.chamfer(width, height, width * 0.3)
        upper: Theme.brass; lower: Theme.brassLo
    }
    Poly {
        anchors { fill: parent; margins: 2.5 }
        points: Skin.chamfer(width, height, width * 0.3)
        upper: root.host.lit ? Qt.tint(Theme.metalLo, Qt.alpha(Theme.rust, 0.7)) : Qt.darker(Theme.metal, 1.3)
        lower: root.host.lit ? Qt.tint(Theme.metalLo, Qt.alpha(Theme.rustText, 0.45)) : Qt.darker(Theme.metalLo, 1.4)
    }
}
