// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne glass: dark iron-red with cut corners, ember light at the foot, a few scores, one dried mark on large
// windows. Lands heavily with a red flash
Item {
    id: root
    required property Item host
    required property bool over
    readonly property real c: Math.max(2, host.radius * 0.55)
    readonly property bool big: width > 90 && height > 60
    function h(i) { return Skin.hash(width, height, i) }

    Poly {   // the glass
        visible: !root.over
        anchors.fill: parent
        points: Skin.iron(width, height, root.c, 0)
        upper: Qt.alpha(Qt.darker(Theme.glass, 1.2), Theme.panelOpacity)
        lower: Qt.alpha(Qt.tint(Theme.glass, Qt.alpha(Theme.rust, 0.2)), Theme.panelOpacity)
        stroke: Qt.alpha(Theme.brassLo, 0.8); strokeWidth: 1
    }
    Rectangle {   // the shadow under the lip
        visible: root.over
        x: 1; y: 1; width: root.width - 2; height: Math.min(16, root.height * 0.25)
        gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.45) } GradientStop { position: 1; color: "transparent" } }
    }
    Rectangle {   // the ember light at the foot
        visible: root.over
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
        height: parent.height * 0.45
        gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha(Theme.rust, 0.22) } }
    }
    Repeater {   // old scores in the glass
        model: root.over && root.big && root.host.scanlines ? (root.width > 300 ? 4 : 2) : 0
        Rectangle {
            required property int index
            x: 12 + root.h(index) * (root.width - 70); y: 10 + root.h(index + 5) * (root.height - 20)
            width: 16 + root.h(index + 9) * 34; height: 1; rotation: -28 + root.h(index + 3) * 18
            color: Qt.alpha(Theme.brassHi, 0.09); antialiasing: true
        }
    }
    Poly {   // one dried mark, low in a corner of a large window: never more than one, never on text
        visible: root.over && Theme.ornaments > 1 && root.width > 320 && root.height > 320
        x: root.width - 46; y: root.height - 30; width: 40; height: 26
        points: [[30, 0], [36, 6], [33, 15], [24, 22], [12, 24], [4, 20], [9, 16], [18, 15], [24, 9], [26, 3]]
        upper: Qt.alpha(Theme.wax, 0.0); lower: Qt.alpha(Theme.wax, 0.42)
    }
    Rectangle {   // the forge flares as the plate lands
        visible: root.over && root.host.boot < 1
        anchors { fill: parent; margins: 1 }
        color: Theme.rust; opacity: (1 - root.host.boot) * 0.35
    }
}
