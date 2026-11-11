// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// The cog (brass vector art, or a phosphor drawing with `outline`). It ticks round like a worn escapement:
// the harder the machine works, the faster it ticks, and now and then it catches, slips back and judders,
// or its picture flickers. Heats to rust under strain.
Item {
    id: root
    property bool spin: true
    readonly property bool hot: Sys.cpu > 0.85
    readonly property int tickEvery: Math.round(2200 - Math.min(1, Sys.cpu) * 1900)   // ms between ticks
    implicitWidth: 24; implicitHeight: 24
    // `outline`: a flat phosphor glyph for cogitator screens (solid cog with a bore), instead of the brass art
    property bool outline: false
    property int teeth: 8
    property bool filled: true            // false: just the outline (for large drawings)
    property color hole: Theme.glass     // what shows through the bore
    readonly property color line: hot ? Theme.rustText : Theme.glow

    Item {
        id: rotor
        anchors.fill: parent
        Shape {
            visible: root.outline
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real c: width / 2
            ShapePath {   // solid cog: chunky teeth, softened corners
                fillColor: root.filled ? root.line : Qt.alpha(root.line, 0.05); strokeColor: root.line; strokeWidth: root.filled ? 1.2 : Math.max(1.3, root.width / 105); joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    path: {
                        const c = root.width / 2, ro = c - 0.8, ri = c * 0.74, n = root.teeth, pts = []
                        for (let i = 0; i < n; i++) {
                            const a = i / n * Math.PI * 2 - Math.PI / 2, w = Math.PI / n
                            for (const [ang, r] of [[a - w * 0.62, ri], [a - w * 0.38, ro], [a + w * 0.38, ro], [a + w * 0.62, ri]])
                                pts.push(Qt.point(c + Math.cos(ang) * r, c + Math.sin(ang) * r))
                        }
                        pts.push(pts[0])
                        return pts
                    }
                }
            }
            ShapePath {   // the bore, cut through to the screen behind
                fillColor: root.hole; strokeColor: root.filled ? "transparent" : Qt.alpha(root.line, 0.6); strokeWidth: Math.max(1, root.width / 140)
                PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.width * 0.24; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {   // axle
                fillColor: root.line; strokeColor: "transparent"
                PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.width * 0.09; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
            }
        }
        Image {
            visible: !root.outline
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/gear.svg")
            sourceSize: Qt.size(width * 3, height * 3)
            smooth: true; mipmap: true
        }
        Image {
            visible: !root.outline
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/gear-hot.svg")
            sourceSize: Qt.size(width * 3, height * 3)
            smooth: true; mipmap: true
            opacity: root.hot ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dMedium } }
        }
    }
    // a tick: half a tooth with a little overshoot. Sometimes it catches and slips back first, sometimes
    // it judders; once in a while the drawing flickers like a failing tube.
    readonly property real step: 180 / teeth
    property real at: 0
    SequentialAnimation {
        id: tick
        RotationAnimator { id: t1; target: rotor; duration: 130; easing.type: Easing.OutQuad }
        RotationAnimator { id: t2; target: rotor; duration: 110; easing.type: Easing.OutBack; easing.overshoot: 2.6 }
        RotationAnimator { id: t3; target: rotor; duration: 60 }
    }
    SequentialAnimation {
        id: flick
        OpacityAnimator { target: rotor; from: 1; to: 0.35; duration: 40 }
        OpacityAnimator { target: rotor; from: 0.35; to: 1; duration: 50 }
        OpacityAnimator { target: rotor; from: 1; to: 0.6; duration: 30 }
        OpacityAnimator { target: rotor; from: 0.6; to: 1; duration: 70 }
    }
    Timer {
        // the interval is set after each tick, not bound: a binding would restart the timer on every CPU sample
        interval: 1200; repeat: true
        running: root.spin && Theme.motionEnabled && root.visible
        onTriggered: {
            interval = root.tickEvery
            const a = root.at, s = root.step, r = Math.random()
            if (r < 0.18) {        // catches, slips back, then goes
                t1.from = a; t1.to = a + s * 0.6
                t2.from = a + s * 0.6; t2.to = a + s * 0.25
                t3.from = a + s * 0.25; t3.to = a + s
            } else if (r < 0.3) {  // judders past and settles
                t1.from = a; t1.to = a + s * 1.3
                t2.from = a + s * 1.3; t2.to = a + s * 0.85
                t3.from = a + s * 0.85; t3.to = a + s
            } else {               // a clean tick
                t1.from = a; t1.to = a + s * 0.7
                t2.from = a + s * 0.7; t2.to = a + s
                t3.from = a + s; t3.to = a + s
            }
            root.at = a + s
            tick.restart()
            if (root.outline && Math.random() < 0.12) flick.restart()
        }
    }
}
