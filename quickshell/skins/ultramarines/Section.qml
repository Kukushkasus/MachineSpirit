// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines section: a tactical panel. Its upper left and lower right corners are cut, its rim is a fine
// gold line (blue light when engaged), with square ticks in the two whole corners. The title is a gold ribbon
// with a pointed end, set in Roman capitals; readings sit on a dark plate with a gold edge.
Item {
    id: root
    required property Item host
    readonly property real ft: host.frameTop
    readonly property real bh: height - ft
    readonly property real c: Math.min(9, bh / 3)
    readonly property color edge: host.glow ? Qt.alpha(Theme.glow, 0.85) : Qt.alpha(Theme.brass, 0.42)

    Poly {   // a soft halo when engaged
        visible: root.host.glow
        x: -2; y: root.ft - 2; width: root.width + 4; height: root.bh + 4
        points: Skin.bevel2(width, height, root.c + 1)
        stroke: Qt.alpha(Theme.glow, 0.18); strokeWidth: 3
    }
    Poly {   // the panel
        y: root.ft; width: root.width; height: root.bh
        points: Skin.bevel2(width, height, root.c)
        upper: Qt.tint(root.host.fill, Qt.alpha(Theme.metal, 0.28)); lower: root.host.fill
        stroke: root.edge; strokeWidth: root.host.glow ? 1.5 : 1
    }
    Repeater {   // square ticks in the whole corners
        model: root.width > 60 && root.bh > 30 ? 2 : 0
        Item {
            required property int index
            readonly property bool r: index === 0
            x: r ? root.width - 9 : 3; y: r ? root.ft + 3 : root.height - 9; width: 6; height: 6
            Rectangle { y: parent.r ? 0 : 5; width: 6; height: 1; color: Qt.alpha(Theme.brassHi, 0.7) }
            Rectangle { x: parent.r ? 5 : 0; width: 1; height: 6; color: Qt.alpha(Theme.brassHi, 0.7) }
        }
    }
    Item {   // the ribbon
        visible: root.host.tab !== ""
        x: 10; width: tabRow.implicitWidth + 34; height: root.host.tabHeight
        Poly {
            anchors.fill: parent
            points: [[0, 0], [width - 10, 0], [width, height / 2], [width - 10, height], [0, height]]
            upper: Qt.tint(Theme.brassHi, Qt.alpha(Theme.spark, root.host.surge * 0.6)); lower: Theme.brass
            stroke: Theme.brassLo; strokeWidth: 1
        }
        Rectangle { x: 3; y: 3; width: 1; height: parent.height - 6; color: Qt.alpha(Theme.brassLo, 0.8) }
        Row {
            id: tabRow
            x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 7
            Icon { visible: root.host.tabIcon !== ""; anchors.verticalCenter: parent.verticalCenter; name: root.host.tabIcon; size: 15; color: Qt.darker(Theme.brassLo, 1.7) }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.host.tab; renderType: Text.NativeRendering
                color: Qt.darker(Theme.brassLo, 1.9)
                font { family: Skin.display(root.host.tab); pixelSize: 13; weight: Font.Bold; letterSpacing: 2.5; capitalization: Font.AllUppercase }
            }
        }
    }
    Poly {   // the plate behind the readings: its left end pointed like the ribbon's right
        visible: root.host.plateBox.visible
        x: root.host.plateBox.x - 8; y: root.host.plateBox.y; width: root.host.plateBox.width + 8; height: root.host.plateBox.height
        points: [[8, 0], [width, 0], [width, height], [8, height], [0, height / 2]]
        upper: Qt.lighter(Theme.metal, 1.15); lower: Qt.darker(Theme.metal, 1.4)
        stroke: Qt.tint(Qt.alpha(Theme.brass, 0.9), Qt.alpha(Theme.spark, root.host.surge)); strokeWidth: 1
    }
}
