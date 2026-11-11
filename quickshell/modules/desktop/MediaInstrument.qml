// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services
Instrument {
    id: root
    housing: "receiver"
    title: Theme.kit === "mechanicus" ? "Vox receiver" : Theme.lex("media", "Player"); serial: "04 / AUDIO"; corner: 18
    readonly property var player: Media.player
    readonly property bool spectrum: Media.playing && !Theme.lowPower && visible
    property bool retained: false
    property real pos: player?.position ?? 0
    function syncSpectrum() { if (spectrum && !retained) { Cava.retain(); retained = true } else if (!spectrum && retained) { Cava.release(); retained = false } }
    onSpectrumChanged: syncSpectrum()
    Component.onCompleted: syncSpectrum()
    Component.onDestruction: if (retained) Cava.release()
    Connections { target: Media; function onTitleChanged() { root.pos = root.player?.position ?? 0 } }
    Timer { interval: 1000; running: Media.playing; repeat: true; onTriggered: { if (root.player) { root.player.positionChanged(); root.pos = root.player.position } } }
    Rectangle { width: 74; height: 74; radius: 6; color: Theme.glassHi; border.color: Theme.glowFaint
        Icon { anchors.centerIn: parent; name: "graphic_eq"; size: 36; color: Theme.glowFaint }
        Image { anchors { fill: parent; margins: 3 } source: Media.art; visible: status === Image.Ready; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(140,140) }
    }
    Text { textFormat: Text.PlainText; x: 88; width: parent.width - 88; text: Media.available ? Media.title || "Untitled track" : "No transmission"; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 17; weight: Font.Medium } }
    Text { textFormat: Text.PlainText; x: 88; y: 49; width: parent.width - 88; text: Media.available ? Media.artist : "Start a player to connect"; elide: Text.ElideRight; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
    Row { x: 89; y: 71; spacing: 3; height: 12
        Repeater { model: 28
            Rectangle { required property int index; width: 5; height: root.spectrum ? Math.max(2, (Cava.bars[index] || 0) * 12) : 2; y: 12 - height; color: root.spectrum ? Theme.glowDim : Theme.glowFaint }
        }
    }
    Item { y: 96; width: parent.width; height: 20
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 3; color: Theme.glowFaint
            Rectangle { width: parent.width * Math.max(0, Math.min(1, root.pos / Math.max(1, root.player?.length ?? 1))); height: 3; color: Theme.glow }
        }
        MouseArea { anchors.fill: parent; enabled: root.player?.canSeek ?? false; cursorShape: Qt.PointingHandCursor
            function seek(x) { root.player.position = Math.max(0, Math.min(1, x / width)) * root.player.length; root.pos = root.player.position }
            onPressed: m => seek(m.x); onPositionChanged: m => { if (pressed) seek(m.x) }
        }
    }
    Row { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } spacing: 14
        BrassMini { icon: "skip_previous"; enabled: root.player?.canGoPrevious ?? false; opacity: enabled ? 1 : 0.35; onClicked: root.player.previous() }
        BrassMini { icon: Media.playing ? "pause" : "play_arrow"; label: Media.playing ? "Pause" : "Play"; enabled: root.player?.canTogglePlaying ?? false; opacity: enabled ? 1 : 0.35; onClicked: root.player.togglePlaying() }
        BrassMini { icon: "skip_next"; enabled: root.player?.canGoNext ?? false; opacity: enabled ? 1 : 0.35; onClicked: root.player.next() }
    }
}
