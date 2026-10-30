// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Tiny dial: a glowing arc around an engraved glyph. Turns rust past 85%.
Item {
    id: root
    property real value: 0
    property string icon: ""
    implicitWidth: 22; implicitHeight: 22
    // quantised to 2% so noise does not redraw the arc; a short ease when it really moves
    readonly property real step: Math.round(Math.min(1, value) * 50) / 50
    property real shown: step
    Behavior on shown { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    readonly property color tone: value > 0.85 ? Theme.rustText : Theme.glow
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"; strokeColor: Theme.glowFaint; strokeWidth: 2.2; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 11; centerY: 11; radiusX: 9.4; radiusY: 9.4; startAngle: 135; sweepAngle: 270 }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.tone; strokeWidth: 2.2; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 11; centerY: 11; radiusX: 9.4; radiusY: 9.4; startAngle: 135; sweepAngle: Math.max(1, 270 * root.shown) }
        }
    }
    Icon { anchors.centerIn: parent; name: root.icon; size: 11; color: Theme.glowDim }
}
