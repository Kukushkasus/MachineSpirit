// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines housing: armour plate with cut corners, gold rim and pinstripe, blue enamel. Large windows get
// gilded corner guards and three rank pips. Nothing crooked, nothing moves
Item {
    id: root
    required property Item host
    readonly property real c: Math.max(5, root.host.radius)
    readonly property bool big: root.host.role === "window" || root.host.role === "toast"
    readonly property bool dressed: Theme.ornaments > 0 && root.big && width > 120 && height > 60

    Poly {   // the gold rim
        anchors.fill: parent
        points: Skin.chamfer(width, height, root.c)
        upper: Theme.brassHi; lower: Theme.brassLo
    }
    Poly {   // enamel
        anchors.fill: parent
        points: Skin.at(Skin.chamfer, width, height, 2, root.c)
        upper: Qt.lighter(Theme.metal, 1.22); lower: Qt.darker(Theme.metal, 1.45)
    }
    Poly {   // the inlaid pinstripe
        anchors.fill: parent
        visible: root.width > 40 && root.height > 30
        points: Skin.at(Skin.chamfer, width, height, 4.5, root.c)
        stroke: Qt.alpha(Theme.brass, 0.6); strokeWidth: 1
    }
    Rectangle {   // light along the top of the plate
        x: root.c; y: 2.5; width: Math.max(0, root.width - 2 * root.c); height: 1
        color: Qt.rgba(1, 1, 1, 0.16)
    }
    Repeater {   // gilded corner guards, set just outside the cut corners
        model: root.dressed ? 4 : 0
        Strokes {
            required property int index
            readonly property bool r: index % 2 === 1
            readonly property bool b: index >= 2
            x: r ? root.width - root.c - 10 : -3; y: b ? root.height - root.c - 10 : -3
            width: root.c + 13; height: root.c + 13
            readonly property real e: root.c + 13
            lineWidth: 2.2; color: Theme.brassHi; round: false
            // an L that follows the cut: along one edge, across the corner, along the other
            lines: [r ? (b ? [e - 3, 0, e - 3, 10, 10, e - 3, 0, e - 3] : [0, 3, 10, 3, e - 3, e - 10, e - 3, e])
                      : (b ? [3, 0, 3, 10, e - 10, e - 3, e, e - 3] : [e, 3, e - 10, 3, 3, e - 10, 3, e])]
        }
    }
    Row {   // rank pips on the top edge, toward the right
        visible: root.dressed
        anchors { right: parent.right; rightMargin: root.c + 18 }
        y: -3.5; spacing: 5
        Repeater {
            model: 3
            Rectangle { width: 6; height: 6; rotation: 45; color: Theme.brassHi; border { width: 0.8; color: Theme.brassLo } }
        }
    }
}
