// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron bar section: a shard floating just clear of the screen edge, pointed at both ends, dark metal with a
// lit edge and phase glass inside. The centre shard carries a pendant: a lit diamond hanging on a thread of
// light under the sectors.
Item {
    id: root
    required property Item host
    readonly property bool heart: host.part === "heart"
    readonly property real y0: 2
    readonly property real h: 34
    readonly property real k: 11
    readonly property real w: width
    function shard(m) { return [[m * 1.6, y0 + h / 2], [k + m, y0 + m], [w - k - m, y0 + m], [w - m * 1.6, y0 + h / 2], [w - k - m, y0 + h - m], [k + m, y0 + h - m]] }
    Poly { width: root.w; height: 40; points: root.shard(0); upper: Qt.lighter(Theme.metal, 1.1); lower: Qt.darker(Theme.metal, 1.8); stroke: Qt.alpha(Theme.glowDim, 0.7); strokeWidth: 1 }
    Poly { width: root.w; height: 40; points: root.shard(3); upper: Qt.darker(Theme.glass, 1.3); lower: Qt.tint(Theme.glass, Qt.alpha(Theme.glowFaint, 0.25)); stroke: Qt.alpha(Theme.glowDim, 0.3); strokeWidth: 1 }
    Rectangle {   // light along the upper edge
        x: root.k + 4; y: root.y0; width: root.w - 2 * root.k - 8; height: 1
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Qt.alpha(Theme.glow, 0.8) } GradientStop { position: 1; color: "transparent" } }
    }
    Repeater {   // a node at each point
        model: 2
        Rectangle { required property int index; width: 3; height: 3; radius: 1.5; color: Theme.glow; x: index ? root.w - 4.5 : 1.5; y: root.y0 + root.h / 2 - 1.5 }
    }
    Item {   // the pendant
        visible: root.heart && Theme.ornaments > 0
        anchors.horizontalCenter: parent.horizontalCenter; y: root.y0 + root.h; width: 12; height: 14
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 5; color: Qt.alpha(Theme.glow, 0.7) }
        Poly { y: 4; width: 12; height: 10; points: [[6, 0], [12, 5], [6, 10], [0, 5]]; upper: Theme.glow; lower: Theme.glowDim }
    }
}
