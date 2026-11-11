// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Ultramarines: the armour band runs on between the sections, so the bar is one piece. Enamelled plates butt
// together under a gold strip, held by clamps with hex bolts. Now and then a readiness pulse runs the length of the strip, and a clamp's lamp answers.
Item {
    id: root
    property real portY: 17
    readonly property real railY: portY - 6
    readonly property int clamps: Math.max(2, Math.round(width / 150))
    function hasBare() { return width > 110 }
    function strike(quiet) { if (!pulse.running) pulse.restart() }
    function crackle() { lampAt = Math.floor(Math.random() * clamps); lamp.restart() }
    property int lampAt: 0

    // the band: the bar's armour runs on between the sections, a little shallower than them
    Rectangle { x: -1; y: 0; width: root.width + 2; height: 30; color: Theme.brassLo }
    Rectangle { x: -1; y: 0; width: root.width + 2; height: 28
        gradient: Gradient { GradientStop { position: 0; color: Qt.lighter(Theme.metal, 1.25) } GradientStop { position: 1; color: Qt.darker(Theme.metal, 1.35) } } }
    Rectangle { x: -1; y: 28; width: root.width + 2; height: 2
        gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brass } } }
    Rectangle { x: -1; y: root.railY + 1.5; width: root.width + 2; height: 1.5; color: Qt.alpha(Theme.brass, 0.85) }      // the gold strip
    Repeater {   // plate joints
        model: Math.max(0, Math.floor(root.width / 90) - 1)
        Rectangle { required property int index; x: (index + 1) * root.width / (Math.floor(root.width / 90)); y: 0; width: 1; height: 28; color: Qt.rgba(0, 0, 0, 0.4)
            Rectangle { x: 1; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.08) } }
    }
    Repeater {   // clamps over the strip, each with a hex bolt and a lamp that answers the pulse
        model: root.clamps
        Item {
            id: clamp
            required property int index
            x: (index + 0.5) * root.width / root.clamps - 9; y: root.railY - 5; width: 18; height: 15
            Poly { anchors.fill: parent; points: Skin.chamfer(width, height, 4); upper: Theme.brassHi; lower: Theme.brassLo; stroke: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.6 }
            Bolt { kit: "ultramarines"; size: 5; x: 3; y: 5 }
            Rectangle { id: bead; x: 11; y: 5.5; width: 4; height: 4; radius: 2
                color: root.lampAt === clamp.index && lamp.running ? Theme.spark : Qt.alpha(Theme.metalLo, 0.8) }
        }
    }
    Item {
        anchors.fill: parent; clip: true
    Rectangle {   // the readiness pulse along the strip
        id: glint
        y: root.railY + 0.5; width: 46; height: 3.5; radius: 2; opacity: 0
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.7; color: Theme.spark } GradientStop { position: 1; color: "#ffffff" } }
    }
    }
    ParallelAnimation {
        id: pulse
        XAnimator { target: glint; from: -46; to: root.width; duration: Math.max(380, root.width * 1.1); easing.type: Easing.InOutQuad }
        SequentialAnimation {
            OpacityAnimator { target: glint; from: 0; to: 0.9; duration: 80 }
            PauseAnimation { duration: Math.max(200, root.width * 1.1 - 180) }
            OpacityAnimator { target: glint; from: 0.9; to: 0; duration: 100 }
        }
    }
    Timer { id: lamp; interval: 420 }
}
