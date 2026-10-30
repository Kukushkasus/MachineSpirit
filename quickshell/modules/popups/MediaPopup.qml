// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Services.Mpris
import qs.common
import qs.services

// Vox Receiver. The cover's colours bleed faintly through the glass; a record slides out from behind the
// cover and turns while music plays. Source and volume, title and artist (they change with a short
// roll when the track does), a live spectrum with its reflection, a seek bar that tells the time under
// the pointer, and the transport. Everything that moves runs only while the panel is open.
Item {
    id: root
    implicitWidth: 360; width: 360
    implicitHeight: col.implicitHeight; height: col.implicitHeight
    readonly property var player: Media.player
    property real pos: player?.position ?? 0
    readonly property real len: Math.max(1, player?.length ?? 1)
    readonly property real frac: Math.min(1, pos / len)
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { if (root.player) { root.player.positionChanged(); root.pos = root.player.position } } }
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    // what is shown lags the player by one roll, so a new track can slide in
    property string shownTitle: Media.title
    property string shownArtist: Media.artist
    property string shownArt: Media.art
    Connections {
        target: Media
        function onTitleChanged() { root.pos = root.player?.position ?? 0; Theme.lowPower ? root.swap() : roll.restart() }
        function onArtChanged() { if (!roll.running) root.shownArt = Media.art }
    }
    function swap() { shownTitle = Media.title; shownArtist = Media.artist; shownArt = Media.art }
    SequentialAnimation {
        id: roll
        ParallelAnimation {
            YAnimator { target: meta; from: 0; to: -10; duration: 120; easing.type: Easing.InCubic }
            OpacityAnimator { target: meta; from: 1; to: 0; duration: 120 }
            OpacityAnimator { target: coverBox; from: 1; to: 0.3; duration: 120 }
        }
        ScriptAction { script: root.swap() }
        ParallelAnimation {
            YAnimator { target: meta; from: 10; to: 0; duration: 220; easing.type: Easing.OutCubic }
            OpacityAnimator { target: meta; from: 0; to: 1; duration: 220 }
            OpacityAnimator { target: coverBox; from: 0.3; to: 1; duration: 260 }
        }
    }

    // ---- the cover, blurred, behind everything; a vignette keeps the text readable on any cover
    Item {
        anchors { fill: parent; margins: -11 }
        visible: root.shownArt !== ""
        opacity: 0.26
        layer.enabled: true
        Image { id: wash; anchors.fill: parent; source: root.shownArt; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(96, 96); visible: false; asynchronous: true }
        MultiEffect { anchors.fill: parent; source: wash; blurEnabled: true; blur: 1; blurMax: 48; saturation: 0.3 }
    }
    Rectangle {
        anchors { fill: parent; margins: -11 }
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.glass, 0.1) }
            GradientStop { position: 0.55; color: Qt.alpha(Theme.glass, 0.35) }
            GradientStop { position: 1; color: Qt.alpha(Theme.glass, 0.7) }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Item {   // cover with the record behind it, and the words
            width: parent.width; height: 108

            Item {   // the record
                id: record
                width: 100; height: 100; y: 4
                x: Media.playing ? 30 : 6
                Behavior on x { XAnimator { duration: 600; easing.type: Easing.OutCubic } }
                Item {
                    id: disc
                    anchors.fill: parent
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath { fillColor: "#0b0b0c"; strokeColor: Qt.alpha(Theme.glow, 0.25); strokeWidth: 1
                            PathAngleArc { centerX: 50; centerY: 50; radiusX: 49.5; radiusY: 49.5; startAngle: 0; sweepAngle: 360 } }
                        ShapePath { fillColor: "transparent"; strokeColor: Qt.rgba(1, 1, 1, 0.07); strokeWidth: 0.8
                            PathAngleArc { centerX: 50; centerY: 50; radiusX: 44; radiusY: 44; startAngle: 0; sweepAngle: 360 }
                            PathMove { x: 89; y: 50 }
                            PathAngleArc { centerX: 50; centerY: 50; radiusX: 39; radiusY: 39; startAngle: 0; sweepAngle: 360 }
                            PathMove { x: 84; y: 50 }
                            PathAngleArc { centerX: 50; centerY: 50; radiusX: 34; radiusY: 34; startAngle: 0; sweepAngle: 360 }
                            PathMove { x: 79; y: 50 }
                            PathAngleArc { centerX: 50; centerY: 50; radiusX: 29; radiusY: 29; startAngle: 0; sweepAngle: 360 } }
                        ShapePath { fillColor: "transparent"; strokeColor: Qt.rgba(1, 1, 1, 0.13); strokeWidth: 2   // light catching the grooves
                            PathAngleArc { centerX: 50; centerY: 50; radiusX: 37; radiusY: 37; startAngle: -60; sweepAngle: 40 } }
                    }
                    RoundedImage {   // label: the cover again
                        anchors.centerIn: parent; width: 36; height: 36; radius: 18
                        source: root.shownArt; fallback: Theme.glowDim
                    }
                    Rectangle { anchors.centerIn: parent; width: 5; height: 5; radius: 2.5; color: "#0b0b0c" }
                    RotationAnimator on rotation {
                        from: 0; to: 360; duration: 4000; loops: Animation.Infinite
                        running: Media.playing && !Theme.lowPower && root.visible
                    }
                }
            }

            Item {   // the cover
                id: coverBox
                width: 108; height: 108
                Rectangle { anchors { fill: parent; margins: -1 } radius: 11; color: "transparent"; border { width: 1; color: Qt.alpha(Theme.glow, 0.35) } }
                RoundedImage {
                    anchors.fill: parent
                    radius: 10; source: root.shownArt; fallback: Qt.alpha(Theme.glow, 0.08)
                    Gear { anchors.centerIn: parent; width: 44; height: 44; outline: true; spin: false; hole: Qt.darker(Theme.glass, 1.1); opacity: 0.5
                        visible: parent.status !== Image.Ready }
                }
            }

            Item {   // words
                id: meta
                x: 146; width: parent.width - 146; height: parent.height
                Item {   // source, and the player's own volume when it has one
                    width: parent.width; height: 16
                    Row {
                        spacing: 4
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: "graphic_eq"; size: 13; color: Theme.glowDim }
                        Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim
                            font { family: Theme.fontNum; pixelSize: 10; weight: Font.Medium; letterSpacing: 1; capitalization: Font.AllUppercase }
                            text: root.player?.identity ?? "" }
                    }
                    Item {
                        id: vol
                        visible: root.player?.volumeSupported ?? false
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 62; height: 16
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: (root.player?.volume ?? 0) > 0.5 ? "volume_up" : "volume_down"; size: 13; color: Theme.glowDim }
                        Rectangle { x: 16; anchors.verticalCenter: parent.verticalCenter; width: 46; height: 3; radius: 1.5; color: Qt.alpha(Theme.glow, 0.15)
                            Rectangle { width: parent.width * Math.min(1, root.player?.volume ?? 0); height: 3; radius: 1.5; color: Theme.glowDim } }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            function set(mx) { if (root.player) root.player.volume = Math.max(0, Math.min(1, (mx - 16) / 46)) }
                            onPressed: mouse => set(mouse.x)
                            onPositionChanged: mouse => { if (pressed) set(mouse.x) }
                            onWheel: wheel => { if (root.player) root.player.volume = Math.max(0, Math.min(1, root.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))) }
                        }
                    }
                }
                Column {
                    y: 22; width: parent.width
                    spacing: 3
                    Glow {
                        width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                        halo: 0.3
                        font { family: Theme.fontNum; pixelSize: 17; weight: Font.DemiBold }
                        text: root.shownTitle || "Unknown track"
                    }
                    Glow { width: parent.width; elide: Text.ElideRight; halo: 0; color: Theme.glowDim
                        font { family: Theme.fontNum; pixelSize: 13 } text: root.shownArtist || " " }
                }
                Item {   // live spectrum and its reflection
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 26
                    opacity: Media.playing ? 1 : 0.25
                    Behavior on opacity { OpacityAnimator { duration: 400 } }
                    Eq { y: 0; width: parent.width; height: 18; count: 22; barWidth: 3; tone: Qt.alpha(Theme.glow, 0.7) }
                    Eq { y: 18; width: parent.width; height: 8; count: 22; barWidth: 3; tone: Qt.alpha(Theme.glow, 0.18)
                        transform: Scale { origin.y: 4; yScale: -1 } }
                }
            }
        }

        Column {   // seek bar and times
            width: parent.width
            spacing: 3
            Item {
                id: bar
                width: parent.width; height: 14
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Qt.alpha(Theme.glow, 0.14) }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(4, parent.width * root.frac); height: 4; radius: 2
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.glowDim } GradientStop { position: 1; color: Theme.glow } }
                }
                Rectangle {   // the head and its glow
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * root.frac - width / 2
                    width: 18; height: 18; radius: 9; color: Qt.alpha(Theme.glow, seekArea.containsMouse ? 0.25 : 0.14)
                    Rectangle { anchors.centerIn: parent; width: seekArea.containsMouse || seekArea.pressed ? 11 : 8; height: width; radius: width / 2; color: Theme.glow
                        Behavior on width { NumberAnimation { duration: 120 } } }
                }
                Tile {   // time under the pointer
                    visible: seekArea.containsMouse && root.len > 1
                    x: Math.max(0, Math.min(bar.width - width, seekArea.mouseX - width / 2)); y: -26
                    width: hoverTime.implicitWidth + 14; height: 20; radius: 5; padding: 0; lit: true
                    Glow { id: hoverTime; anchors.centerIn: parent; halo: 0; font { family: Theme.fontNum; pixelSize: 11; features: { "tnum": 1 } }
                        text: root.fmt(Math.max(0, Math.min(1, seekArea.mouseX / bar.width)) * root.len) }
                }
                MouseArea {
                    id: seekArea
                    anchors { fill: parent; topMargin: -6; bottomMargin: -6 }
                    hoverEnabled: true
                    enabled: root.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    function seek(mx) { const t = Math.max(0, Math.min(1, mx / bar.width)) * root.len; root.player.position = t; root.pos = t }
                    onPressed: mouse => seek(mouse.x)
                    onPositionChanged: mouse => { if (pressed) seek(mouse.x) }
                }
            }
            Item {
                width: parent.width; height: 14
                Glow { halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11; features: { "tnum": 1 } } text: root.fmt(root.pos) }
                Glow { anchors.right: parent.right; halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11; features: { "tnum": 1 } }
                    text: "-" + root.fmt(root.len - root.pos) }
            }
        }

        Row {   // transport
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            Ctl { icon: "shuffle"; small: true; visible: root.player?.shuffleSupported ?? false; on: root.player?.shuffle ?? false
                onHit: root.player.shuffle = !root.player.shuffle }
            Ctl { icon: "skip_previous"; nudge: -3; onHit: Media.player?.previous() }
            Ctl { icon: Media.playing ? "pause" : "play_arrow"; big: true; onHit: Media.player?.togglePlaying() }
            Ctl { icon: "skip_next"; nudge: 3; onHit: Media.player?.next() }
            Ctl { icon: (root.player?.loopState ?? 0) === MprisLoopState.Track ? "repeat_one" : "repeat"; small: true
                visible: root.player?.loopSupported ?? false; on: (root.player?.loopState ?? 0) !== MprisLoopState.None
                onHit: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None }
        }
    }

    // phosphor buttons: bare glyphs that kick toward where they go; play is a lit disc in a thin ring
    component Ctl: Item {
        id: c
        property string icon: ""
        property bool big: false
        property bool small: false
        property bool on: false
        property real nudge: 0
        signal hit()
        anchors.verticalCenter: parent.verticalCenter
        width: big ? 50 : 32; height: width
        Rectangle {   // ring around play
            visible: c.big
            anchors.centerIn: parent; width: parent.width + 8; height: width; radius: width / 2
            color: "transparent"; border { width: 1; color: Qt.alpha(Theme.glow, 0.35) }
        }
        Rectangle {
            id: face
            anchors.centerIn: parent; width: parent.width; height: width; radius: width / 2
            scale: cm.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }
            color: c.big ? (cm.containsMouse ? Theme.glow : Qt.alpha(Theme.glow, 0.88)) : (cm.containsMouse ? Qt.alpha(Theme.glow, 0.14) : "transparent")
            Icon {
                id: glyph
                x: (face.width - width) / 2; y: (face.height - height) / 2
                name: c.icon; size: c.big ? 28 : (c.small ? 17 : 23); fill: true
                color: c.big ? Theme.glass : (c.small && !c.on ? Theme.glowFaint : Theme.glow)
            }
            SequentialAnimation {   // paused: play breathes slowly
                running: c.big && !Media.playing && !Theme.lowPower && root.visible
                loops: Animation.Infinite
                onRunningChanged: if (!running) face.opacity = 1
                OpacityAnimator { target: face; from: 1; to: 0.7; duration: 1400; easing.type: Easing.InOutSine }
                OpacityAnimator { target: face; from: 0.7; to: 1; duration: 1400; easing.type: Easing.InOutSine }
            }
        }
        SequentialAnimation {
            id: kick
            XAnimator { target: glyph; from: (face.width - glyph.width) / 2; to: (face.width - glyph.width) / 2 + c.nudge; duration: 70 }
            XAnimator { target: glyph; from: (face.width - glyph.width) / 2 + c.nudge; to: (face.width - glyph.width) / 2; duration: 160; easing.type: Easing.OutBack }
        }
        Rectangle { visible: c.small && c.on; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } width: 4; height: 4; radius: 2; color: Theme.glow }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { if (c.nudge !== 0 && !Theme.lowPower) kick.restart(); c.hit() } }
    }
}
