// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines bar section: part of one armour band across the screen, gold rim, blue enamel, tactical glass.
// the centre one is a deeper command post. Glass keeps 32 px for the housings (y 3..31), trim stays thin
Item {
    id: root
    required property Item host
    readonly property bool heart: host.part === "heart"
    readonly property real d: heart ? 41 : 35          // how far the plate reaches down
    readonly property real k: heart ? 10 : 5           // its lower corner cut
    readonly property real gb: heart ? 35.5 : 33       // the glass's foot
    readonly property real gk: heart ? 8 : 3.5         // the glass's corner cut
    readonly property real w: width
    function plate(m) { return [[m, 0], [w - m, 0], [w - m, d - k - m * 0.4], [w - k - m * 0.6, d - m], [k + m * 0.6, d - m], [m, d - k - m * 0.4]] }
    function glass(m) { return [[m, 0], [w - m, 0], [w - m, gb - gk], [w - m - gk, gb], [m + gk, gb], [m, gb - gk]] }
    Poly { width: root.w; height: root.d; points: root.plate(0); upper: Theme.brassHi; lower: Theme.brassLo }
    Poly { width: root.w; height: root.d; points: root.plate(1.2); upper: Qt.lighter(Theme.metal, 1.2); lower: Qt.darker(Theme.metal, 1.4) }
    Poly {   // the glass
        width: root.w; height: root.d
        points: root.glass(4)
        upper: Qt.tint(Theme.glass, Qt.alpha(Theme.metal, 0.35)); lower: Qt.darker(Theme.glass, 1.15)
        stroke: Qt.alpha(Theme.brassLo, 0.75); strokeWidth: 0.8
    }
    Image { x: 5; y: 0; width: root.w - 10; height: root.gb - 2; source: Qt.resolvedUrl("../../assets/grid.svg"); fillMode: Image.Tile; opacity: 0.05; smooth: false }
    Rectangle {   // the gold pinstripe at the glass's foot
        x: 4 + root.gk + 2; y: root.gb - 2.5; width: root.w - 2 * (4 + root.gk + 2); height: 1
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.12; color: Qt.alpha(Theme.brass, 0.75) }
            GradientStop { position: 0.88; color: Qt.alpha(Theme.brass, 0.75) } GradientStop { position: 1; color: "transparent" } }
    }
    Repeater {   // hex bolts at the foot of the glass
        model: 2
        Bolt { required property int index; kit: "ultramarines"; size: 4; x: index ? root.w - 4 - 1 : 0.5; y: root.d - root.k - 5 }
    }
    Row {   // the command post's pips
        visible: root.heart && Theme.ornaments > 0
        anchors.horizontalCenter: parent.horizontalCenter; y: root.gb + 1.2; spacing: 5
        Repeater { model: 3; Rectangle { width: 3; height: 3; rotation: 45; antialiasing: true; color: Theme.brassHi } }
    }
}
