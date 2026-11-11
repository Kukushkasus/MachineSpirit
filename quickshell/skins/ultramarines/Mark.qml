// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines key: the engaged sector is a gold shield with a pointed foot; an occupied one carries a small
// chevron under its numeral.
Item {
    id: root
    required property Item host
    Poly {
        anchors { fill: parent; topMargin: -1; bottomMargin: -3 }
        points: [[0, 0], [width, 0], [width, height - 6], [width / 2, height], [0, height - 6]]
        upper: Theme.brassHi; lower: Theme.brass
        stroke: Theme.brassLo; strokeWidth: 1
        opacity: root.host.focused ? 1 : root.host.hovered ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
    }
    Strokes {
        visible: root.host.occupied && !root.host.focused
        anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 4; width: 7; height: 3
        color: Theme.brass; lineWidth: 1.2; round: false
        lines: [[0, 0, 3.5, 3, 7, 0]]
    }
}
