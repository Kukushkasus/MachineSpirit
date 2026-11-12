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
    readonly property real railY: 9
    readonly property int clamps: Math.max(2, Math.round(width / 190))
    function hasBare() { return width > 110 }
    function strike(quiet) { if (!pulse.running) pulse.restart() }
    function crackle() { lampAt = Math.floor(Math.random() * clamps); lamp.restart() }
    property int lampAt: 0

    // the band: the bar's armour runs on between the sections as a slim rail, well shallower than them
    readonly property real band: 18
    Rectangle { x: -1; y: 0; width: root.width + 2; height: root.band + 1; color: Theme.brassLo }
    Rectangle { x: -1; y: 0; width: root.width + 2; height: root.band
        gradient: Gradient { GradientStop { position: 0; color: Qt.lighter(Theme.metal, 1.15) } GradientStop { position: 1; color: Qt.darker(Theme.metal, 1.45) } } }
    Rectangle { x: -1; y: root.band; width: root.width + 2; height: 1; color: Theme.brassHi; opacity: 0.85 }
    Rectangle { x: -1; y: root.railY; width: root.width + 2; height: 1; color: Qt.alpha(Theme.brass, 0.7) }      // the gold strip
    Repeater {   // plate joints
        model: Math.max(0, Math.floor(root.width / 120) - 1)
        Rectangle { required property int index; x: (index + 1) * root.width / (Math.floor(root.width / 120)); y: 0; width: 1; height: root.band; color: Qt.rgba(0, 0, 0, 0.35)
            Rectangle { x: 1; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.07) } }
    }
    Repeater {   // clamps over the strip, each with a hex bolt and a lamp that answers the pulse
        model: root.clamps
        Item {
            id: clamp
            required property int index
            x: (index + 0.5) * root.width / root.clamps - 7; y: root.railY - 4.5; width: 14; height: 10
            Poly { anchors.fill: parent; points: Skin.chamfer(width, height, 3); upper: Theme.brassHi; lower: Theme.brassLo; stroke: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.6 }
            Bolt { kit: "ultramarines"; size: 4; x: 2; y: 3 }
            Rectangle { id: bead; x: 8.5; y: 3.5; width: 3; height: 3; radius: 1.5
                color: root.lampAt === clamp.index && lamp.running ? Theme.spark : Qt.alpha(Theme.metalLo, 0.8) }
        }
    }
    Item {
        anchors.fill: parent; clip: true
    Rectangle {   // the readiness pulse along the strip
        id: glint
        y: root.railY - 1; width: 46; height: 3; radius: 2; opacity: 0
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
