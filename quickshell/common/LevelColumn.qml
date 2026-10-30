// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// A vertical level gauge on the panel: value in nixie digits on top, a column of segments that fill from
// the bottom, a glyph at the foot. Drag or roll to set.
Item {
    id: root
    property real value: 0          // 0..1
    property string icon: ""
    property bool dim: false
    property int segments: 14
    signal moved(real v)
    width: 34
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Nixie { id: num; anchors.horizontalCenter: parent.horizontalCenter; y: 0; size: 13; text: String(Math.round(root.value * 100)).padStart(2, "0") }
    Item {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        y: 22; width: 18; height: root.height - 22 - 26
        Rectangle { anchors { fill: parent; margins: -3 } radius: 5; color: Qt.darker(Theme.glass, 1.3); border { width: 1; color: Qt.alpha(Theme.glow, 0.22) } }
        Column {
            anchors.fill: parent
            spacing: 2
            Repeater {
                model: root.segments
                Rectangle {
                    required property int index
                    readonly property real level: (root.segments - index) / root.segments
                    width: col.width; height: (col.height - (root.segments - 1) * 2) / root.segments; radius: 1.5
                    color: root.shown >= level - 0.5 / root.segments
                        ? (root.dim ? Qt.alpha(Theme.glow, 0.35) : (level > 0.92 ? Theme.rustText : Theme.glow))
                        : Qt.alpha(Theme.glow, 0.08)
                }
            }
        }
        MouseArea {
            anchors { fill: parent; margins: -6 }
            cursorShape: Qt.PointingHandCursor
            function at(my) { root.moved(Math.max(0, Math.min(1, 1 - (my - 6) / col.height))) }
            onPressed: mouse => at(mouse.y)
            onPositionChanged: mouse => { if (pressed) at(mouse.y) }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
    Icon { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } name: root.icon; size: 18; color: root.dim ? Theme.glowFaint : Theme.glowDim }
}
