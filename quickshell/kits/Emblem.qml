// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// The crest over the control desk. Every one is drawn here from scratch on a 58 px tall grid and scaled;
// none is, or may become, a copy of anyone's emblem.
//   mechanicus    the winged cog and skull (common/Crest.qml)
//   ultramarines  a laurel wreath open at the top round a star, on a short banner bar
//   necrons       a cartouche: a ring cut by a vertical bar, rayed, between two stepped wings of lines
//   khorne        a horned brass mask over crossed blades
Item {
    id: root
    height: 58
    width: height * 4.5
    readonly property real s: height / 58
    visible: Theme.ornaments > 1
    Loader {
        anchors.centerIn: parent
        width: 261; height: 58; scale: root.s
        sourceComponent: Theme.kit === "ultramarines" ? laurel : Theme.kit === "necrons" ? cartouche : Theme.kit === "khorne" ? mask : winged
    }
    Component { id: winged; Crest { height: 58 } }

    Component {
        id: laurel
        Item {
            id: l
            readonly property real cx: 130.5
            readonly property real cy: 28
            // the banner bar
            Rectangle { x: l.cx - 92; y: l.cy + 9; width: 184; height: 5; radius: 2.5
                gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } }
            Rectangle { x: l.cx - 78; y: l.cy + 16; width: 156; height: 1.5; color: Qt.alpha(Theme.brass, 0.6) }
            Repeater { model: 2; Rectangle { required property int index; x: index ? l.cx + 88 : l.cx - 96; y: l.cy + 5; width: 8; height: 13; radius: 2; color: Theme.brass; border { width: 0.6; color: Theme.brassLo } } }
            // the medallion
            Rectangle { x: l.cx - 25; y: l.cy - 25; width: 50; height: 50; radius: 25
                gradient: Gradient { GradientStop { position: 0; color: Theme.metalHi } GradientStop { position: 1; color: Theme.metalLo } }
                border { width: 1.5; color: Theme.brass } }
            Repeater {   // laurel leaves: two arcs of eight, open at the top
                model: 16
                Rectangle {
                    required property int index
                    readonly property int side: index < 8 ? -1 : 1
                    readonly property real t: (index % 8) / 7
                    readonly property real a: (Math.PI / 2) + side * (0.35 + t * 2.2)
                    width: 11; height: 4.6; radius: 2.3; antialiasing: true
                    x: l.cx + Math.cos(a) * 30 - width / 2; y: l.cy + Math.sin(a) * 30 - height / 2
                    rotation: a * 180 / Math.PI + side * 62
                    gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brass } }
                }
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath { fillColor: Theme.brassHi; strokeColor: Theme.brassLo; strokeWidth: 0.6
                    PathPolyline { path: { const p = []; for (let i = 0; i <= 10; i++) { const a = i / 10 * Math.PI * 2 - Math.PI / 2, r = i % 2 ? 6.2 : 15; p.push(Qt.point(l.cx + Math.cos(a) * r, l.cy + Math.sin(a) * r)) } return p } } }
            }
        }
    }

    Component {
        id: cartouche
        Item {
            id: c
            readonly property real cx: 130.5
            readonly property real cy: 29
            Repeater {   // stepped wings: bars that shorten as they climb
                model: 10
                Rectangle {
                    required property int index
                    readonly property int side: index < 5 ? -1 : 1
                    readonly property int k: index % 5
                    width: 74 - k * 13; height: 2.4; radius: 1.2
                    x: side < 0 ? c.cx - 30 - width : c.cx + 30; y: c.cy + 14 - k * 7
                    color: Qt.alpha(Theme.glowDim, 0.9 - k * 0.13)
                    Rectangle { x: parent.side < 0 ? -1 : parent.width - 3; y: -1.3; width: 5; height: 5; rotation: 45; color: Theme.metalLo; border { width: 0.8; color: Theme.glowDim } }
                }
            }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath { fillColor: Theme.metalLo; strokeColor: Theme.metalEdge; strokeWidth: 1
                    PathAngleArc { centerX: c.cx; centerY: c.cy; radiusX: 26; radiusY: 26; startAngle: 0; sweepAngle: 360 } }
                ShapePath { fillColor: "transparent"; strokeColor: Theme.glow; strokeWidth: 2.2; capStyle: ShapePath.FlatCap
                    PathAngleArc { centerX: c.cx; centerY: c.cy; radiusX: 17; radiusY: 17; startAngle: -60; sweepAngle: 300 } }
                ShapePath { fillColor: "transparent"; strokeColor: Theme.glow; strokeWidth: 2.2; capStyle: ShapePath.FlatCap
                    startX: c.cx; startY: c.cy - 22; PathLine { x: c.cx; y: c.cy + 22 } }
                ShapePath { fillColor: "transparent"; strokeColor: Qt.alpha(Theme.glow, 0.8); strokeWidth: 1.4
                    startX: c.cx - 9; startY: c.cy + 6; PathLine { x: c.cx + 9; y: c.cy + 6 }
                    PathMove { x: c.cx - 6; y: c.cy + 11 } PathLine { x: c.cx + 6; y: c.cy + 11 } }
            }
            Rectangle { x: c.cx - 3; y: c.cy - 9; width: 6; height: 6; rotation: 45; color: Theme.glow }
        }
    }

    Component {
        id: mask
        Item {
            id: m
            readonly property real cx: 130.5
            readonly property real cy: 29
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                // crossed blades behind
                ShapePath { fillGradient: LinearGradient { x1: 0; y1: 10; x2: 0; y2: 50; GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 1; color: Theme.metalLo } }
                    strokeColor: Qt.darker(Theme.metalLo, 1.4); strokeWidth: 0.6
                    startX: m.cx - 104; startY: m.cy + 14
                    PathLine { x: m.cx - 20; y: m.cy - 3 } PathLine { x: m.cx - 16; y: m.cy + 5 } PathLine { x: m.cx - 96; y: m.cy + 20 } PathLine { x: m.cx - 104; y: m.cy + 14 } }
                ShapePath { fillGradient: LinearGradient { x1: 0; y1: 10; x2: 0; y2: 50; GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 1; color: Theme.metalLo } }
                    strokeColor: Qt.darker(Theme.metalLo, 1.4); strokeWidth: 0.6
                    startX: m.cx + 104; startY: m.cy + 14
                    PathLine { x: m.cx + 20; y: m.cy - 3 } PathLine { x: m.cx + 16; y: m.cy + 5 } PathLine { x: m.cx + 96; y: m.cy + 20 } PathLine { x: m.cx + 104; y: m.cy + 14 } }
                // horns: two swept curves
                ShapePath { fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: 40; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
                    strokeColor: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.6
                    startX: m.cx - 15; startY: m.cy - 8
                    PathQuad { x: m.cx - 44; y: m.cy - 27; controlX: m.cx - 42; controlY: m.cy - 4 }
                    PathQuad { x: m.cx - 9; y: m.cy - 17; controlX: m.cx - 30; controlY: m.cy - 12 }
                    PathLine { x: m.cx - 15; y: m.cy - 8 } }
                ShapePath { fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: 40; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
                    strokeColor: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.6
                    startX: m.cx + 15; startY: m.cy - 8
                    PathQuad { x: m.cx + 44; y: m.cy - 27; controlX: m.cx + 42; controlY: m.cy - 4 }
                    PathQuad { x: m.cx + 9; y: m.cy - 17; controlX: m.cx + 30; controlY: m.cy - 12 }
                    PathLine { x: m.cx + 15; y: m.cy - 8 } }
                // the mask: broad brow, narrowing to a jaw
                ShapePath { fillGradient: LinearGradient { x1: 0; y1: 6; x2: 0; y2: 56; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 0.5; color: Theme.brass } GradientStop { position: 1; color: Theme.brassLo } }
                    strokeColor: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.8; joinStyle: ShapePath.RoundJoin
                    startX: m.cx - 19; startY: m.cy - 16
                    PathQuad { x: m.cx + 19; y: m.cy - 16; controlX: m.cx; controlY: m.cy - 25 }
                    PathQuad { x: m.cx + 14; y: m.cy + 8; controlX: m.cx + 23; controlY: m.cy - 2 }
                    PathLine { x: m.cx + 8; y: m.cy + 23 }
                    PathQuad { x: m.cx - 8; y: m.cy + 23; controlX: m.cx; controlY: m.cy + 28 }
                    PathLine { x: m.cx - 14; y: m.cy + 8 }
                    PathQuad { x: m.cx - 19; y: m.cy - 16; controlX: m.cx - 23; controlY: m.cy - 2 } }
                // eye slits, lit from within
                ShapePath { fillColor: Theme.spark; strokeColor: Theme.metalLo; strokeWidth: 0.8
                    startX: m.cx - 13; startY: m.cy - 5; PathLine { x: m.cx - 3; y: m.cy - 1 } PathLine { x: m.cx - 5; y: m.cy + 2 } PathLine { x: m.cx - 13; y: m.cy - 1 } PathLine { x: m.cx - 13; y: m.cy - 5 } }
                ShapePath { fillColor: Theme.spark; strokeColor: Theme.metalLo; strokeWidth: 0.8
                    startX: m.cx + 13; startY: m.cy - 5; PathLine { x: m.cx + 3; y: m.cy - 1 } PathLine { x: m.cx + 5; y: m.cy + 2 } PathLine { x: m.cx + 13; y: m.cy - 1 } PathLine { x: m.cx + 13; y: m.cy - 5 } }
                // jaw bars
                ShapePath { fillColor: "transparent"; strokeColor: Qt.alpha(Theme.metalLo, 0.85); strokeWidth: 1.2
                    startX: m.cx - 4; startY: m.cy + 12; PathLine { x: m.cx - 4; y: m.cy + 23 }
                    PathMove { x: m.cx; y: m.cy + 11 } PathLine { x: m.cx; y: m.cy + 25 }
                    PathMove { x: m.cx + 4; y: m.cy + 12 } PathLine { x: m.cx + 4; y: m.cy + 23 } }
            }
        }
    }
}
