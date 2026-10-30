// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell.Services.Pipewire
import QtQuick
import qs.common

// Volume: speaker glyph and level. Wheel changes it, click mutes.
BarButton {
    id: root
    interactive: true
    implicitWidth: row.implicitWidth + 8
    readonly property var audio: Pipewire.defaultAudioSink?.audio
    readonly property real vol: audio?.volume ?? 0
    readonly property bool muted: audio?.muted ?? false
    tip: muted ? "Sound off, click to turn on" : "Volume, scroll to change, click to mute"
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    // the speaker kicks when the level or mute changes
    onVolChanged: if (Theme.motionEnabled) kick.restart()
    onMutedChanged: if (Theme.motionEnabled) kick.restart()
    SequentialAnimation { id: kick
        ScaleAnimator { target: spk; from: 1; to: 1.22; duration: 70 }
        ScaleAnimator { target: spk; from: 1.22; to: 1; duration: 160; easing.type: Easing.OutBack } }
    onClicked: if (audio) audio.muted = !audio.muted
    onWheel: event => { if (audio) audio.volume = Math.max(0, Math.min(1, vol + (event.angleDelta.y > 0 ? 0.03 : -0.03))) }
    Row {
        id: row
        anchors.centerIn: parent; spacing: 3
        Icon { id: spk; anchors.verticalCenter: parent.verticalCenter; size: 17; color: root.muted ? Theme.rustText : (root.hovered ? Theme.glow : Theme.glowDim)
            name: root.muted ? "volume_off" : (root.vol > 0.5 ? "volume_up" : (root.vol > 0 ? "volume_down" : "volume_mute")) }
        Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; font { family: Theme.fontNum; pixelSize: 12; weight: Font.Medium }
            color: root.muted ? Theme.rustText : Theme.glowDim; text: Math.round(root.vol * 100) + "%" }
    }
}
