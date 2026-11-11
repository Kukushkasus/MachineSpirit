// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// The living mark of the machine: on the bar (small, opens the console) and as the wheel of the power menu
// (large, `spin: false`, turned by `rotation` from outside). It shows the real processor load and nothing else.
//   mechanicus    the cog, ticking like a worn escapement (common/Gear.qml)
//   ultramarines  a readiness dial: a ring of twelve marks lit clockwise by load, steady, a star at the centre
//   necrons       two broken rings turning slowly against each other round a lit core
//   khorne        a heavy saw-toothed wheel that turns in slow, weighty steps
Item {
    id: root
    property bool spin: true
    property bool large: false                 // the power menu's wheel
    property color hole: Theme.glass
    readonly property bool hot: Sys.cpu > 0.85
    readonly property color line: hot ? Theme.rustText : Theme.glow
    implicitWidth: 24; implicitHeight: 24
    Loader {
        anchors.fill: parent
        sourceComponent: Theme.kit === "ultramarines" ? dial : Theme.kit === "necrons" ? rings : Theme.kit === "khorne" ? saw : cog
    }
    Component { id: cog; Gear { spin: root.spin; outline: true; filled: false; teeth: root.large ? 12 : 10; hole: root.hole } }

    Component {
        id: dial
        Item {
            id: d
            readonly property real c: width / 2
            readonly property int lit: Math.max(1, Math.round(Sys.cpu * 12))
            Repeater {
                model: 12
                Rectangle {
                    required property int index
                    readonly property real a: index / 12 * Math.PI * 2 - Math.PI / 2
                    width: Math.max(1.6, d.width * 0.075); height: d.width * 0.17; radius: width / 2; antialiasing: true
                    x: d.c + Math.cos(a) * d.width * 0.40 - width / 2; y: d.c + Math.sin(a) * d.width * 0.40 - height / 2
                    rotation: index * 30
                    // the power menu's wheel is not a gauge: all its marks are lit
                    color: root.large || index < d.lit ? root.line : Qt.alpha(root.line, 0.22)
                    Behavior on color { ColorAnimation { duration: Theme.dMedium } }
                }
            }
            Shape {   // five-pointed star
                anchors.fill: parent; visible: !root.large
                preferredRendererType: Shape.CurveRenderer
                ShapePath { fillColor: Theme.brassHi; strokeColor: "transparent"
                    PathPolyline { path: { const p = []; for (let i = 0; i <= 10; i++) { const a = i / 10 * Math.PI * 2 - Math.PI / 2, r = d.width * (i % 2 ? 0.105 : 0.25); p.push(Qt.point(d.c + Math.cos(a) * r, d.c + Math.sin(a) * r)) } return p } } }
            }
            Rectangle { visible: root.large; anchors.centerIn: parent; width: parent.width * 0.86; height: width; radius: width / 2; color: "transparent"; border { width: Math.max(1.3, parent.width / 105); color: Qt.alpha(root.line, 0.6) } }
        }
    }

    Component {
        id: rings
        Item {
            id: r
            Repeater {
                id: ringRep
                model: 2
                Shape {
                    id: ring
                    required property int index
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    readonly property real rad: r.width * (index ? 0.28 : 0.44)
                    ShapePath { strokeColor: Qt.alpha(root.line, ring.index ? 0.7 : 1); strokeWidth: Math.max(1.4, r.width / (root.large ? 90 : 14)); fillColor: "transparent"; capStyle: ShapePath.FlatCap
                        PathAngleArc { centerX: r.width / 2; centerY: r.height / 2; radiusX: ring.rad; radiusY: ring.rad; startAngle: 20; sweepAngle: 130 }
                        PathAngleArc { centerX: r.width / 2; centerY: r.height / 2; radiusX: ring.rad; radiusY: ring.rad; startAngle: 200; sweepAngle: ring.index ? 70 : 130 } }
                    // a slow drift in steps: a continuous turn would repaint the bar every frame
                    Behavior on rotation { enabled: Theme.motionEnabled; NumberAnimation { duration: 1400; easing.type: Easing.InOutSine } }
                }
            }
            // every few seconds the rings slide past each other a little; more often under real load
            Timer {
                interval: 4000; repeat: true; running: root.spin && Theme.motionEnabled && r.visible
                onTriggered: {
                    interval = Math.round(6000 - Math.min(1, Sys.cpu) * 4000)
                    const outer = ringRep.itemAt(0), inner = ringRep.itemAt(1)
                    if (outer) outer.rotation += 14
                    if (inner) inner.rotation -= 22
                }
            }
            Rectangle { anchors.centerIn: parent; width: parent.width * (root.large ? 0.05 : 0.2); height: width; rotation: 45; color: root.line }
        }
    }

    Component {
        id: saw
        Item {
            id: w
            property real at: 0
            Shape {
                id: blade
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Qt.alpha(root.line, 0.06); strokeColor: root.line; strokeWidth: Math.max(1.3, w.width / (root.large ? 105 : 18)); joinStyle: ShapePath.MiterJoin
                    PathPolyline { path: {
                        // hooked teeth, all leaning the way the wheel turns
                        const c = w.width / 2, n = root.large ? 12 : 8, ro = c - 0.8, ri = c * 0.72, p = []
                        for (let i = 0; i <= n; i++) {
                            const a = i / n * Math.PI * 2 - Math.PI / 2, s = Math.PI * 2 / n
                            p.push(Qt.point(c + Math.cos(a) * ri, c + Math.sin(a) * ri))
                            p.push(Qt.point(c + Math.cos(a + s * 0.62) * ro, c + Math.sin(a + s * 0.62) * ro))
                            p.push(Qt.point(c + Math.cos(a + s * 0.80) * ri, c + Math.sin(a + s * 0.80) * ri))
                        }
                        return p } }
                }
                ShapePath { fillColor: root.hole; strokeColor: Qt.alpha(root.line, 0.6); strokeWidth: Math.max(1, w.width / 140)
                    PathAngleArc { centerX: w.width / 2; centerY: w.height / 2; radiusX: w.width * 0.25; radiusY: radiusX; startAngle: 0; sweepAngle: 360 } }
                ShapePath { fillColor: root.line; strokeColor: "transparent"
                    PathAngleArc { centerX: w.width / 2; centerY: w.height / 2; radiusX: w.width * 0.08; radiusY: radiusX; startAngle: 0; sweepAngle: 360 } }
            }
            // a slow heave and a settle: weight, not speed. More often under real load.
            SequentialAnimation {
                id: heave
                RotationAnimator { id: h1; target: blade; duration: 520; easing.type: Easing.InQuad }
                RotationAnimator { id: h2; target: blade; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
            Timer {
                interval: 2600; repeat: true; running: root.spin && Theme.motionEnabled && w.visible
                onTriggered: {
                    interval = Math.round(3600 - Math.min(1, Sys.cpu) * 2600)
                    const step = 360 / (root.large ? 12 : 8)
                    h1.from = w.at; h1.to = w.at + step * 0.8; h2.from = w.at + step * 0.8; h2.to = w.at + step
                    w.at += step; heave.restart()
                }
            }
        }
    }
}
