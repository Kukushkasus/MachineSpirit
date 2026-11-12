// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Necrons: two energy conduits between the mounts, joined at nodes. The channels hold a low steady light.
// Now and then a charge travels one of them, and where it passes a node a thin arc may jump to the other channel.
Item {
    id: root
    property real portY: 17
    readonly property real y0: portY - 5
    readonly property real y1: portY + 4
    readonly property int nodes: Math.max(1, Math.round(width / 170))
    function nodeX(i) { return (i + 0.5) * width / nodes }
    function hasBare() { return width > 110 }
    property bool upper: true
    property int arcAt: -1
    property var arcPts: []
    function strike(quiet) {
        if (charge.running) return
        upper = Math.random() < 0.5
        charge.restart()
        if (!quiet && Math.random() < 0.6) { arcAt = Math.floor(Math.random() * nodes); arcDelay.interval = Math.max(60, charge.duration * (nodeX(arcAt) / Math.max(1, width)) - 40); arcDelay.restart() }
    }
    function crackle() { glintAt = Math.floor(Math.random() * nodes); glint.restart() }
    property int glintAt: -1

    Repeater {   // the channels: a dark tube with a lit core
        model: 2
        Item {
            required property int index
            x: -6; y: (index ? root.y1 : root.y0) - 2; width: root.width + 12; height: 4
            Rectangle { anchors.fill: parent; radius: 2; color: Theme.metalLo; border { width: 0.5; color: Qt.alpha(Theme.metalEdge, 0.5) } }
            Rectangle { x: 0; y: 1.5; width: parent.width; height: 1; color: Qt.alpha(Theme.glowDim, index ? 0.35 : 0.55) }
        }
    }
    Repeater {   // nodes: a link between the channels with a lit lozenge
        model: root.nodes
        Item {
            id: node
            required property int index
            x: root.nodeX(index) - 5; y: root.y0 - 3; width: 10; height: root.y1 - root.y0 + 6
            Rectangle { x: 4; y: 2; width: 2; height: parent.height - 4; color: Theme.metal }
            Rectangle { anchors.centerIn: parent; width: 7; height: 7; rotation: 45; color: Theme.metalLo; border { width: 0.8; color: Qt.alpha(Theme.glowDim, 0.9) }
                Rectangle { anchors.centerIn: parent; width: 3; height: 3; color: Theme.glow; opacity: root.glintAt === node.index && glint.running ? 1 : 0.45
                    Behavior on opacity { NumberAnimation { duration: 180 } } } }
        }
    }
    Item {   // the channels are alive: faint motes of energy drift along them all the time, in opposite directions.
        // They step 15 times a second, not every frame: the drift is slow, and the bar is redrawn four times less often.
        anchors.fill: parent; clip: true
        visible: flow.running
        Repeater {
            id: motes
            model: 4
            Rectangle {
                required property int index
                readonly property bool low: index % 2 === 1
                readonly property real speed: 1000 / (9 + index * 2.5)        // px per second
                property real pos: (index * 0.27 + 0.1) * root.width
                x: low ? root.width - pos : pos - width
                y: (low ? root.y1 : root.y0) - 1; width: 26; height: 2; radius: 1
                opacity: 0.55
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Theme.glow } GradientStop { position: 1; color: "transparent" } }
                function step(dt) { pos = (pos + speed * dt) % (root.width + 26) }
            }
        }
        Timer {
            interval: 66; repeat: true; running: flow.running
            onTriggered: { for (let i = 0; i < motes.count; i++) motes.itemAt(i).step(0.066) }
        }
    }
    // runs while effects are on; stops with reduced motion, low power or effects off
    QtObject { id: flow; readonly property bool running: Theme.fxOn("discharge") && root.width > 110 && root.visible }
    Item {   // the charge travels inside the span only, never over the mounts
        anchors.fill: parent; clip: true
    Rectangle {   // the travelling charge
        id: bolt
        y: (root.upper ? root.y0 : root.y1) - 1.5; width: 64; height: 3; radius: 1.5; opacity: 0
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.8; color: Theme.spark } GradientStop { position: 1; color: "#f2fff8" } }
    }
    }
    ParallelAnimation {
        id: charge
        readonly property int duration: Math.max(500, root.width * 1.6)
        XAnimator { target: bolt; from: -64; to: root.width; duration: charge.duration; easing.type: Easing.InOutSine }
        SequentialAnimation {
            OpacityAnimator { target: bolt; from: 0; to: 1; duration: 120 }
            PauseAnimation { duration: Math.max(100, charge.duration - 300) }
            OpacityAnimator { target: bolt; from: 1; to: 0; duration: 180 }
        }
    }
    Timer { id: arcDelay; onTriggered: {
        const x = root.nodeX(root.arcAt), p = []
        for (let i = 0; i <= 5; i++) p.push(Qt.point(x + (i === 0 || i === 5 ? 0 : (Math.random() - 0.5) * 9), root.y0 + (root.y1 - root.y0) * i / 5))
        root.arcPts = p; arc.restart()
    } }
    Shape {
        id: arcShape
        anchors.fill: parent; opacity: 0; visible: arc.running
        preferredRendererType: Shape.CurveRenderer
        ShapePath { strokeColor: Theme.spark; strokeWidth: 1.4; fillColor: "transparent"; joinStyle: ShapePath.RoundJoin; PathPolyline { path: root.arcPts } }
    }
    SequentialAnimation {
        id: arc
        OpacityAnimator { target: arcShape; from: 0; to: 1; duration: 30 }
        OpacityAnimator { target: arcShape; from: 1; to: 0.3; duration: 50 }
        OpacityAnimator { target: arcShape; from: 0.3; to: 0.9; duration: 30 }
        OpacityAnimator { target: arcShape; from: 0.9; to: 0; duration: 140 }
    }
    Timer { id: glint; interval: 500 }
}
