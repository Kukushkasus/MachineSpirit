// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Round brass push button with an engraved glyph and an optional indicator lamp.
BarButton {
    id: root
    property string icon: ""
    property bool lamp: false          // show the lamp at all
    property bool lit: false           // lamp on
    property color lampColor: Theme.glow
    interactive: true
    implicitWidth: 30; implicitHeight: 32

    Shape {
        x: 3; y: 4; width: 24; height: 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.8
            fillGradient: RadialGradient {
                centerX: root.pressed ? 12 : 9; centerY: root.pressed ? 13 : 8; centerRadius: 16
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: root.pressed ? Theme.brass : Theme.brassHi }
                GradientStop { position: 1; color: Theme.brassLo }
            }
            PathAngleArc { centerX: 12; centerY: 12; radiusX: 11.5; radiusY: 11.5; startAngle: 0; sweepAngle: 360 }
        }
    }
    Icon { x: 3; y: 4; width: 24; height: 24; horizontalAlignment: Text.AlignHCenter; name: root.icon; size: 15; color: Qt.darker(Theme.brassLo, 1.5) }
    Rectangle {
        id: lampDot
        visible: root.lamp
        x: 22; y: 2; width: 7; height: 7; radius: 3.5
        color: root.lit ? root.lampColor : Theme.metalLo
        Behavior on color { ColorAnimation { duration: Theme.dShort } }
        border { width: 1; color: Theme.metalLo }
        Rectangle { anchors.centerIn: parent; width: 11; height: 11; radius: 5.5; color: root.lampColor; opacity: root.lit ? 0.25 : 0; z: -1 }
    }
}
