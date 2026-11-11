// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Servo-skull holding a panel by its side: a bone skull with a brass crown plate, one red optic,
// a small suspensor glowing under it and a brass clamp arm reaching to the panel (`mirror` for the right).
// `active` lets it hover and blink; `arrive()` flies it in from the side.
Item {
    id: root
    property bool active: false
    property bool mirror: false
    width: 46; height: 44
    readonly property color bone: Qt.lighter(Theme.metalEdge, 1.35)
    readonly property color boneDark: Theme.metalEdge

    function arrive() {
        if (!Theme.motionEnabled) return
        flyIn.restart()
    }
    ParallelAnimation {
        id: flyIn
        XAnimator { target: body; from: root.mirror ? 30 : -30; to: 0; duration: 260; easing.type: Easing.OutCubic }
        OpacityAnimator { target: body; from: 0; to: 1; duration: 200 }
    }

    Item {
        id: body
        width: parent.width; height: parent.height
        transform: Scale { origin.x: 23; xScale: root.mirror ? -1 : 1 }
        // hover
        SequentialAnimation {
            running: root.active && Theme.motionEnabled; loops: Animation.Infinite
            YAnimator { target: body; from: 0; to: -1; duration: 1600 + (root.mirror ? 500 : 0); easing.type: Easing.InOutSine }
            YAnimator { target: body; from: -1; to: 0; duration: 1600 + (root.mirror ? 500 : 0); easing.type: Easing.InOutSine }
        }

        Rectangle {   // clamp arm to the panel
            x: 30; y: 20; width: 16; height: 4; radius: 1
            gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
        }
        Rectangle { x: 42; y: 15; width: 4; height: 14; radius: 1; color: Theme.brass; border { width: 1; color: Qt.darker(Theme.brassLo, 1.3) } }

        Rectangle {   // suspensor glow
            x: 7; y: 34; width: 24; height: 7; radius: 3.5
            color: Qt.alpha(Theme.spark, 0.35)
        }
        Rectangle { x: 10; y: 32; width: 18; height: 4; radius: 2; color: Theme.brassLo; border { width: 1; color: Qt.darker(Theme.brassLo, 1.4) } }

        Shape {       // the skull
            x: 4; y: 4; width: 30; height: 30
            preferredRendererType: Shape.CurveRenderer
            ShapePath {   // cranium and jaw
                strokeColor: Qt.darker(root.boneDark, 1.6); strokeWidth: 1
                fillGradient: LinearGradient { x1: 0; y1: 0; x2: 30; y2: 30
                    GradientStop { position: 0; color: root.bone } GradientStop { position: 1; color: root.boneDark } }
                startX: 15; startY: 1
                PathCubic { x: 29; y: 14; control1X: 24; control1Y: 1; control2X: 29; control2Y: 7 }
                PathLine { x: 26; y: 21 }
                PathLine { x: 23; y: 28 }
                PathLine { x: 7; y: 28 }
                PathLine { x: 4; y: 21 }
                PathLine { x: 1; y: 14 }
                PathCubic { x: 15; y: 1; control1X: 1; control1Y: 7; control2X: 6; control2Y: 1 }
            }
            ShapePath {   // sockets and nose
                strokeColor: "transparent"; fillColor: Qt.darker(Theme.metalLo, 1.5)
                PathAngleArc { centerX: 9.5; centerY: 15; radiusX: 4; radiusY: 3.6; startAngle: 0; sweepAngle: 360 }
                PathMove { x: 25; y: 15 }
                PathAngleArc { centerX: 20.5; centerY: 15; radiusX: 4; radiusY: 3.6; startAngle: 0; sweepAngle: 360 }
                PathMove { x: 15; y: 18 }
                PathLine { x: 13; y: 22 }
                PathLine { x: 17; y: 22 }
                PathLine { x: 15; y: 18 }
            }
            ShapePath {   // teeth
                strokeColor: Qt.darker(root.boneDark, 1.8); strokeWidth: 0.8; fillColor: "transparent"
                startX: 9; startY: 25; PathLine { x: 21; y: 25 }
                PathMove { x: 12; y: 23.5 } PathLine { x: 12; y: 27.5 }
                PathMove { x: 15; y: 23.5 } PathLine { x: 15; y: 27.5 }
                PathMove { x: 18; y: 23.5 } PathLine { x: 18; y: 27.5 }
            }
        }
        Rectangle {   // brass crown plate
            x: 10; y: 3; width: 18; height: 5; radius: 2
            gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
            Bolt { size: 3; x: 1; y: 1 }
            Bolt { size: 3; x: parent.width - 4; y: 1 }
        }
        Rectangle {   // the optic
            id: optic
            x: 21; y: 15.5; width: 7; height: 7; radius: 3.5
            color: "#ff3b2a"
            border { width: 1.2; color: Theme.brass }
            Rectangle { anchors.centerIn: parent; width: 13; height: 13; radius: 6.5; color: Qt.alpha("#ff3b2a", 0.22); z: -1 }
            SequentialAnimation {
                running: root.active && Theme.motionEnabled; loops: Animation.Infinite
                PauseAnimation { duration: 2600 + (root.mirror ? 900 : 0) }
                OpacityAnimator { target: optic; from: 1; to: 0.25; duration: 80 }
                OpacityAnimator { target: optic; from: 0.25; to: 1; duration: 140 }
            }
        }
    }
}
