// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell
import qs.common

// Life on a screen, laid over its content. Now and then (the pack sets how often, each screen on its own
// clock) one short thing happens, by faction:
//   mechanicus    the picture dips twice like a lamp, or a scan wave rolls down it
//   ultramarines  a readiness pulse: one thin bright line crosses the display, once
//   necrons       a slow shimmer climbs the glass
//   khorne        the forge breathes: a dull red swell and fade
// Render-thread animations only, stopped while hidden, with reduced motion or in low power. Never more than
// one ambient effect at a time across the shell (Theme.fxClaim). MS_DEV_FAST_AMBIENT=1 makes it frequent for testing.
Item {
    id: root
    property real radius: 6
    property bool active: true
    readonly property bool fast: Quickshell.env("MS_DEV_FAST_AMBIENT") === "1"
    readonly property bool wanted: active && visible && Theme.fxOn("screenLife")
    readonly property string kit: Skin.screen
    function quiet() { flickAnim.stop(); waveAnim.stop(); pulseAnim.stop(); riseAnim.stop(); breathAnim.stop(); veil.opacity = 0; wave.y = -wave.height; line.opacity = 0; rise.opacity = 0 }
    onWantedChanged: if (!wanted) quiet()
    onKitChanged: quiet()
    clip: true

    Rectangle {   // the lamp dip (a veil of glass colour) or the forge's breath (a veil of ember)
        id: veil
        anchors.fill: parent
        radius: root.radius
        color: root.kit === "khorne" ? Theme.rust : Theme.glass
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
    Rectangle {   // the readiness pulse
        id: line
        width: 2; height: root.height; opacity: 0
        color: Theme.spark
        Rectangle { x: -14; width: 14; height: parent.height
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha(Theme.spark, 0.25) } } }
    }
    Rectangle {   // the shimmer
        id: rise
        width: root.width; height: Math.max(20, root.height * 0.4); opacity: 0
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(Theme.spark, 0.10) }
            GradientStop { position: 1; color: "transparent" }
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
    ParallelAnimation {
        id: pulseAnim
        XAnimator { target: line; from: 0; to: root.width; duration: 420; easing.type: Easing.InOutQuad }
        SequentialAnimation {
            OpacityAnimator { target: line; from: 0; to: 0.7; duration: 60 }
            PauseAnimation { duration: 280 }
            OpacityAnimator { target: line; from: 0.7; to: 0; duration: 80 }
        }
    }
    ParallelAnimation {
        id: riseAnim
        YAnimator { target: rise; from: root.height; to: -rise.height; duration: 1400; easing.type: Easing.InOutSine }
        SequentialAnimation {
            OpacityAnimator { target: rise; from: 0; to: 1; duration: 400 }
            PauseAnimation { duration: 600 }
            OpacityAnimator { target: rise; from: 1; to: 0; duration: 400 }
        }
    }
    SequentialAnimation {
        id: breathAnim
        OpacityAnimator { target: veil; from: 0; to: 0.10; duration: 700; easing.type: Easing.InOutSine }
        OpacityAnimator { target: veil; from: 0.10; to: 0; duration: 1100; easing.type: Easing.InOutSine }
    }
    function play() {
        if (kit === "ultramarines") pulseAnim.restart()
        else if (kit === "necrons") riseAnim.restart()
        else if (kit === "khorne") breathAnim.restart()
        else if (Math.random() < 0.34) waveAnim.restart(); else flickAnim.restart()
    }
    Timer {
        running: root.wanted
        repeat: true
        interval: root.fast ? 2500 : Theme.fxDelay("screenLife", 40, 120)
        onTriggered: {
            // if another ambient effect is playing somewhere, this screen simply waits its next turn
            if (Theme.fxClaim(root.kit === "necrons" || root.kit === "khorne" ? 1800 : 600)) root.play()
            interval = root.fast ? 1500 + Math.random() * 2000 : Theme.fxDelay("screenLife", 40, 120)
        }
    }
}
