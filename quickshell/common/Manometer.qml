// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Pressure gauge: brass bezel, glass face with ticks and a red zone, needle with inertia.
// value 0..1 sweeps 270 degrees.
Item {
    id: root
    property real value: 0
    property real redline: 0.85
    property string label: ""
    property bool ticks: true
    implicitWidth: 40; implicitHeight: 40
    readonly property real r: Math.min(width, height) / 2
    readonly property real start: 135       // degrees, Qt angle (clockwise from 3 o'clock)

    property real shown: 0
    Component.onCompleted: shown = Qt.binding(() => root.value)
    Behavior on shown { SpringAnimation { spring: 3.5; damping: 0.28; epsilon: 0.002 } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {   // bezel
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: root.width; y2: root.height
                GradientStop { position: 0; color: Theme.brassHi }
                GradientStop { position: 0.5; color: Theme.brass }
                GradientStop { position: 1; color: Theme.brassLo }
            }
            PathAngleArc { centerX: root.r; centerY: root.r; radiusX: root.r; radiusY: root.r; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {   // face
            strokeColor: Qt.alpha("black", 0.5); strokeWidth: 0.8
            fillColor: Theme.glass
            PathAngleArc { centerX: root.r; centerY: root.r; radiusX: root.r * 0.82; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {   // red zone
            strokeColor: Theme.rustText; strokeWidth: Math.max(1.5, root.r * 0.10)
            fillColor: "transparent"
            PathAngleArc { centerX: root.r; centerY: root.r; radiusX: root.r * 0.66; radiusY: radiusX; startAngle: root.start + 270 * root.redline; sweepAngle: 270 * (1 - root.redline) }
        }
    }
    Repeater {   // ticks
        model: root.ticks ? 11 : 0
        Rectangle {
            required property int index
            readonly property real a: (root.start + index * 27) * Math.PI / 180
            readonly property bool major: index % 5 === 0
            width: major ? 1.4 : 1; height: root.r * (major ? 0.18 : 0.11)
            color: Qt.alpha(Theme.glow, major ? 0.9 : 0.55)
            x: root.r + Math.cos(a) * root.r * 0.70 - width / 2
            y: root.r + Math.sin(a) * root.r * 0.70 - height / 2
            rotation: (root.start + index * 27) + 90
        }
    }
    property string tag: ""          // tiny inscription for small gauges ("CPU")
    Text {
        visible: root.tag !== ""
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: root.r * 0.16 }
        text: root.tag
        color: Theme.glow
        font { family: Theme.fontNum; pixelSize: Math.max(7, root.r * 0.36); weight: Font.Bold }
        renderType: Text.NativeRendering
    }
    Text {
        visible: root.label !== "" && root.r > 22
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: root.r * 0.36 }
        text: root.label
        color: Theme.glowDim
        font { family: Theme.fontNum; pixelSize: Math.max(8, root.r * 0.22); weight: Font.Medium }
        renderType: Text.NativeRendering
    }
    Item {   // needle
        anchors.fill: parent
        rotation: root.start + 270 * Math.max(0, Math.min(1.04, root.shown)) + 90
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillColor: root.shown > root.redline ? Theme.rustText : Theme.glow
                startX: root.r - root.r * 0.07; startY: root.r
                PathLine { x: root.r; y: root.r * 0.26 }
                PathLine { x: root.r + root.r * 0.07; y: root.r }
                PathLine { x: root.r; y: root.r * 1.18 }
                PathLine { x: root.r - root.r * 0.07; y: root.r }
            }
        }
    }
    Bolt { anchors.centerIn: parent; anchors.verticalCenterOffset: -root.r * 0.08; size: Math.max(3.5, root.r * 0.22) }
}
