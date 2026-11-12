// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Vox receiver, small: the cover turns in a brass ring while music plays, title over artist, play and next.
// Fixed width; what does not fit ends in an ellipsis. Click opens the full receiver below it, wheel skips tracks.
Row {
    id: root
    visible: Media.available
    spacing: 2
    property int maxWidth: 220
    property bool compact: false       // only the cover (narrow screens)

    BarButton {
        id: body
        popup: "media"
        tip: (Media.artist ? Media.artist + " - " : "") + (Media.title || "Music")
        implicitWidth: compact ? 28 : root.maxWidth - 56   // fixed: long titles end in an ellipsis
        onWheel: event => { if (event.angleDelta.y > 0) Media.player?.previous(); else Media.player?.next() }
        Item {
            id: disc
            x: 2; anchors.verticalCenter: parent.verticalCenter; width: 22; height: 22
            Rectangle { anchors.fill: parent; radius: 11
                gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } }
            RoundedImage {
                anchors.centerIn: parent; width: 18; height: 18; radius: 9
                source: Media.art; fallback: Theme.glass
                Icon { anchors.centerIn: parent; name: "music_note"; size: 12; color: Theme.glow; visible: parent.status !== Image.Ready }
                id: cover
                // turns in ratchet clicks like the cog, not continuously: a moving cover would redraw the bar every frame
                RotationAnimator { id: click; target: cover; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 }
                Timer { interval: 2400; repeat: true; running: Media.playing && Theme.motionEnabled && root.visible
                    onTriggered: { click.from = cover.rotation; click.to = cover.rotation + 30; click.restart() } }
            }
            Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Theme.glass; border { width: 1; color: Theme.brass } }
        }
        Item {
            visible: !root.compact
            x: 30; y: -1; width: parent.width - 32; height: 28; clip: true
            Glow {
                id: title
                y: 1
                halo: 0
                font { family: Theme.fontNum; pixelSize: 12; weight: Font.DemiBold }
                text: Media.title || "Unknown track"
                width: parent.width; elide: Text.ElideRight
            }
            Glow { id: artist; y: 13; width: parent.width; elide: Text.ElideRight; halo: 0; color: Theme.glowDim
                font { family: Theme.fontNum; pixelSize: 11 } text: Media.artist }
        }
    }
    GlyphButton { visible: !root.compact; icon: Media.playing ? "pause" : "play_arrow"; tip: Media.playing ? "Pause" : "Play"; onClicked: Media.player?.togglePlaying() }
    GlyphButton { visible: !root.compact; icon: "skip_next"; tip: "Next"; onClicked: Media.player?.next() }
}
