// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell
import qs.common

// Life on a cogitator screen, laid over its content: now and then (40-120 s, each screen on its own
// clock) the picture dips twice like a lamp, or a scan wave rolls down it. Render-thread animations only,
// stopped while hidden or in low power. MS_DEV_FAST_AMBIENT=1 makes it frequent for testing.
Item {
    id: root
    property real radius: 6
    property bool active: true
    readonly property bool fast: Quickshell.env("MS_DEV_FAST_AMBIENT") === "1"
    readonly property bool wanted: active && visible && Theme.motionEnabled
    onWantedChanged: if (!wanted) { flickAnim.stop(); waveAnim.stop(); veil.opacity = 0; wave.y = -wave.height }
    clip: true

    Rectangle {   // the lamp dip: a veil of glass colour over the picture
        id: veil
        anchors.fill: parent
        radius: root.radius
        color: Theme.glass
        opacity: 0
    }
    Rectangle {   // the rolling scan wave
        id: wave
        width: root.width; height: Math.max(8, root.height * 0.22); y: -height
        visible: waveAnim.running
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.75; color: Qt.alpha(Theme.glow, 0.08) }
            GradientStop { position: 1; color: Qt.alpha(Theme.glow, 0.2) }
        }
    }
    SequentialAnimation {
        id: flickAnim
        OpacityAnimator { target: veil; from: 0; to: 0.45; duration: 40 }
        OpacityAnimator { target: veil; from: 0.45; to: 0; duration: 60 }
        OpacityAnimator { target: veil; from: 0; to: 0.25; duration: 30 }
        OpacityAnimator { target: veil; from: 0.25; to: 0; duration: 90 }
    }
    YAnimator { id: waveAnim; target: wave; from: -wave.height; to: root.height; duration: 560; easing.type: Easing.InOutSine }
    Timer {
        running: root.wanted
        repeat: true
        interval: root.fast ? 2500 : 40000 + Math.random() * 80000
        onTriggered: {
            if (Math.random() < 0.34) waveAnim.restart(); else flickAnim.restart()
            interval = root.fast ? 1500 + Math.random() * 2000 : 40000 + Math.random() * 80000
        }
    }
}
