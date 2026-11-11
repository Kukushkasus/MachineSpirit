// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines bar section: part of one armour band that runs the width of the screen. A gold rim, blue
// enamel, tactical glass set in it with a gold pinstripe at its foot and hex bolts at its corners. The centre
// section stands deeper as a command post, with three gold pips under the sectors.
Item {
    id: root
    required property Item host
    readonly property bool heart: host.part === "heart"
    readonly property real d: heart ? 44 : 36          // how far the plate reaches down
    readonly property real k: heart ? 14 : 6           // its lower corner cut
    readonly property real w: width
    function plate(m) { return [[m, 0], [w - m, 0], [w - m, d - k - m * 0.4], [w - k - m * 0.6, d - m], [k + m * 0.6, d - m], [m, d - k - m * 0.4]] }
    Poly { width: root.w; height: root.d; points: root.plate(0); upper: Theme.brassHi; lower: Theme.brassLo }
    Poly { width: root.w; height: root.d; points: root.plate(2); upper: Qt.lighter(Theme.metal, 1.25); lower: Qt.darker(Theme.metal, 1.35) }
    Poly {   // the glass
        width: root.w; height: root.d
        points: [[7, 0], [root.w - 7, 0], [root.w - 7, 31], [root.w - 10, 34], [10, 34], [7, 31]]
        upper: Qt.tint(Theme.glass, Qt.alpha(Theme.metal, 0.4)); lower: Qt.darker(Theme.glass, 1.2)
        stroke: Qt.alpha(Theme.brassLo, 0.9); strokeWidth: 1
    }
    Image { x: 8; y: 0; width: root.w - 16; height: 33; source: Qt.resolvedUrl("../../assets/grid.svg"); fillMode: Image.Tile; opacity: 0.06; smooth: false }
    Rectangle { x: 12; y: 36; width: root.w - 24; height: 1; color: Qt.alpha(Theme.brass, 0.8); visible: root.heart }
    Repeater {   // hex bolts at the foot of the glass
        model: 2
        Bolt { required property int index; kit: "ultramarines"; size: 5; x: index ? root.w - 7.5 : 2.5; y: root.d - root.k - 7 }
    }
    Row {   // the command post's pips
        visible: root.heart && Theme.ornaments > 0
        anchors.horizontalCenter: parent.horizontalCenter; y: 38.5; spacing: 6
        Repeater { model: 3; Rectangle { width: 4; height: 4; rotation: 45; color: Theme.brassHi } }
    }
}
