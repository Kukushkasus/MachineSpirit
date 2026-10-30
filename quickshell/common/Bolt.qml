// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Round-headed bolt with a slot.
Item {
    id: root
    property real size: 6
    property real angle: 30
    width: size; height: size
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.darker(Theme.brassLo, 1.4); strokeWidth: 0.6
            fillGradient: RadialGradient {
                centerX: root.size * 0.35; centerY: root.size * 0.3; centerRadius: root.size * 0.7
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: Theme.brassHi }
                GradientStop { position: 1; color: Theme.brassLo }
            }
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size / 2 - 0.4; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: root.size * 0.62; height: Math.max(0.8, root.size * 0.12)
        rotation: root.angle
        color: Qt.alpha(Theme.metalLo, 0.85)
    }
}
