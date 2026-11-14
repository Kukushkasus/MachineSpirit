// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Khorne: a chain between the mounts, two dashed strokes on one catenary (flat links and edge-on ones).
// rarely a single dark drop gathers under a link and falls
Item {
    id: root
    property real portY: 17
    readonly property real span: Math.max(1, width)
    readonly property real sag: Math.max(4, Math.min(11, span * 0.03))
    function hang(t, deep) {
        const k = 1.4, c = Math.cosh((2 * t - 1) * k), ck = Math.cosh(k)
        return portY + (deep ? 4 + sag * 2.1 : sag) * (1 - c / ck) / (1 - 1 / ck)
    }
    function catenary(deep) {
        const out = [], n = Math.max(8, Math.round(span / 6))
        for (let i = 0; i <= n; i++) out.push(Qt.point(i / n * span, hang(i / n, deep)))
        return out
    }
    readonly property var line: catenary(false)
    // a second, heavier chain hangs lower behind the first: two chains, so the span reads as weight
    readonly property var low: catenary(true)
    function hasBare() { return width > 110 }
    property real dropT: 0.5
    function strike(quiet) {
        if (drip.running) return
        dropT = 0.25 + Math.random() * 0.5
        drop.x = dropT * span - 2; dripY.from = hang(dropT) + 3; dripY.to = hang(dropT) + 40
        drip.restart()
    }
    function crackle() { if (!swing.running) swing.restart() }

    Item {
        id: chain
        anchors.fill: parent
        transform: Scale { id: sway; origin.y: root.portY; yScale: 1 }
        Shape {
            anchors.fill: parent; opacity: 0.85
            preferredRendererType: Shape.CurveRenderer
            ShapePath {   // shadow under the chain
                strokeColor: Qt.rgba(0, 0, 0, 0.5); strokeWidth: 7 * 1.3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathPolyline { path: root.low.map(p => Qt.point(p.x, p.y + 1.5)) }
            }
            ShapePath {   // links seen edge-on
                strokeColor: Theme.metalHi; strokeWidth: 7 * 0.46; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine; dashPattern: [2.0, 3.25]; dashOffset: 3.08
                PathPolyline { path: root.low }
            }
            ShapePath {   // flat links
                strokeColor: Theme.metalEdge; strokeWidth: 7; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine; dashPattern: [0.5, 1.92]
                PathPolyline { path: root.low }
            }
            ShapePath {   // the eye of each flat link
                strokeColor: Theme.metalLo; strokeWidth: 7 * 0.35; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine; dashPattern: [0.9, 6.1]; dashOffset: 6.72
                PathPolyline { path: root.low }
            }
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {   // shadow under the chain
                strokeColor: Qt.rgba(0, 0, 0, 0.5); strokeWidth: 8.6 * 1.3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathPolyline { path:root.line.map(p => Qt.point(p.x, p.y + 1.5)) }
            }
            ShapePath {   // links seen edge-on
                strokeColor: Theme.metalHi; strokeWidth: 8.6 * 0.46; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine; dashPattern: [2.0, 3.25]; dashOffset: 3.08
                PathPolyline { path:root.line }
            }
            ShapePath {   // flat links
                strokeColor: Theme.metalEdge; strokeWidth: 8.6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine; dashPattern: [0.5, 1.92]
                PathPolyline { path:root.line }
            }
            ShapePath {   // the eye of each flat link
                strokeColor: Theme.metalLo; strokeWidth: 8.6 * 0.35; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine; dashPattern: [0.9, 6.1]; dashOffset: 6.72
                PathPolyline { path:root.line }
            }
        }
    }
    SequentialAnimation {   // the chain settles after a tug
        id: swing
        NumberAnimation { target: sway; property: "yScale"; to: 1.12; duration: 260; easing.type: Easing.OutQuad }
        NumberAnimation { target: sway; property: "yScale"; to: 0.97; duration: 380; easing.type: Easing.InOutSine }
        NumberAnimation { target: sway; property: "yScale"; to: 1; duration: 420; easing.type: Easing.InOutSine }
    }
    Rectangle { id: drop; width: 4; height: 5.5; radius: 2; color: Qt.darker(Theme.rust, 1.15); opacity: 0; visible: drip.running }
    SequentialAnimation {
        id: drip
        ParallelAnimation {   // it gathers
            OpacityAnimator { target: drop; from: 0; to: 0.95; duration: 500 }
            ScaleAnimator { target: drop; from: 0.3; to: 1; duration: 700; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {   // and falls
            YAnimator { id: dripY; target: drop; duration: 380; easing.type: Easing.InQuad }
            SequentialAnimation { PauseAnimation { duration: 260 } OpacityAnimator { target: drop; from: 0.95; to: 0; duration: 120 } }
        }
    }
    onDropTChanged: drop.y = hang(dropT) + 3
}
