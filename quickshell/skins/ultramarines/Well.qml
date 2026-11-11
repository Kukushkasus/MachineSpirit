// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines well: a square socket with cut corners in a gilt frame; engaged, blue light fills it and the
// frame brightens to full gold.
Item {
    id: root
    required property Item host
    Poly {
        anchors.fill: parent
        points: Skin.chamfer(width, height, width * 0.2)
        upper: root.host.lit ? Qt.alpha(Theme.glow, 0.22) : Qt.lighter(Theme.metal, 1.1)
        lower: root.host.lit ? Qt.alpha(Theme.glow, 0.08) : Qt.darker(Theme.metal, 1.5)
        stroke: root.host.lit ? Theme.brassHi : Qt.alpha(Theme.brass, 0.5); strokeWidth: root.host.lit ? 1.5 : 1
    }
    Poly {
        anchors { fill: parent; margins: 3.5 }
        points: Skin.chamfer(width, height, width * 0.18)
        stroke: Qt.alpha(Theme.brass, root.host.lit ? 0.5 : 0.22); strokeWidth: 0.8
    }
}
