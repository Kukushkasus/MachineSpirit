// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import qs.common
import qs.services
import qs.kits

// Sanctum: the control desk on the right. Under the crest: the machine and its vigil, the vox bus (output,
// input and brightness faders, the playing track), six circuit modules, and the vox log of
// messages. One state mark per control, one reading per module. Slides in from the edge; a click elsewhere or Esc closes it.
// Created on first use.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        property bool ready: false
        Component.onCompleted: Qt.callLater(() => ready = true)
        readonly property bool mine: ready && Sanctum.open && (Settings.primary()?.name ?? modelData.name) === modelData.name
        onMineChanged: if (mine) { Brightness.probe(); Notifs.markRead(); glass.powerOn(); keys.forceActiveFocus(); plateSurge.restart() }
        // the plates take a charge just as the panel seats itself
        Timer { id: plateSurge; interval: Theme.dLong * 0.7; onTriggered: { voxFrame.energise(); logFrame.energise() } }

        visible: mine || panel.slide < 1
        WlrLayershell.namespace: "machinespirit-sanctum"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea { anchors.fill: parent; onClicked: Sanctum.close() }
        Item { id: keys; focus: true; Keys.onEscapePressed: Sanctum.close() }

        readonly property var sink: Pipewire.defaultAudioSink?.audio
        readonly property var mic: Pipewire.defaultAudioSource?.audio
        readonly property var bt: Bluetooth.defaultAdapter
        readonly property var paired: Bluetooth.devices.values.filter(d => d.connected)
        PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
        property string host: ""
        FileView { path: "/etc/hostname"; onLoaded: win.host = text().trim() }
        readonly property string face: Quickshell.env("HOME") + "/.face"
        property bool hasFace: false
        Process { running: true; command: ["test", "-f", win.face]; onExited: code => win.hasFace = code === 0 }
        // short screens get a denser desk: three modules a row, no subtitles
        readonly property bool compact: height < 760 || Theme.compact

        Item {
            id: panel
            width: 460
            y: 70; height: win.height - y - 12
            enabled: win.mine
            property real slide: win.mine ? 0 : 1
            // How the desk arrives, by faction. Mechanicus: a latch lets go and the panel runs out to its stop with a small
            // kick. Ultramarines: straight to its place, no overshoot. Necrons: it does not travel, it phases in.
            // Khorne: slower, and it lands with weight. The panel takes input from the first frame in every case.
            readonly property string kit: Theme.kit
            Behavior on slide { NumberAnimation {
                duration: win.mine ? Math.round(Theme.dLong * (panel.kit === "mechanicus" ? 1.25 : 1)) : Theme.dClose
                easing.type: !win.mine ? Easing.InCubic : panel.kit === "mechanicus" || panel.kit === "khorne" ? Easing.OutBack : Theme.easeEnter
                easing.overshoot: panel.kit === "khorne" ? 0.35 : 0.6 } }
            x: win.width - width - 10 + slide * (panel.kit === "necrons" ? 26 : width + 20)
            opacity: panel.kit === "necrons" ? 1 - Math.min(1, Math.max(0, slide)) : 1 - Math.max(0, slide) * 0.6
            MouseArea { anchors.fill: parent }

            Bezel { anchors.fill: parent; radius: 14; inset: 0; boltSize: 5; role: "window" }
            CrtScreen { id: glass; anchors { fill: parent; margins: 7 } radius: 9; padding: 0; bootOnLoad: false; ambient: false }
            Flicker { anchors { fill: parent; margins: 7 } radius: 9; active: win.mine; z: 20 }

            // ---------------- the crest: the winged cog and skull over the title
            Emblem { id: emblem; anchors.horizontalCenter: parent.horizontalCenter; y: -22; height: win.compact ? 44 : 58 }
            Item {
                id: crest
                x: 22; y: emblem.y + emblem.height + 2; width: parent.width - 44; height: win.compact ? 22 : 26
                Title { anchors.fill: parent; text: Theme.lex("panelTitle", "SANCTUM"); pixelSize: win.compact ? 15 : 17 }
            }

            Column {
                id: stack
                x: 16; y: crest.y + crest.height + (win.compact ? 4 : 8)
                width: parent.width - 32
                spacing: win.compact ? 8 : 14

                // ---------------- the board: who keeps the vigil, and the desk's own keys
                Item {
                    width: parent.width; height: win.compact ? 42 : 50
                    Item {   // avatar in a phosphor ring
                        id: avatar
                        x: 4; anchors.verticalCenter: parent.verticalCenter
                        width: win.compact ? 40 : 46; height: width
                        Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.glass; border { width: 1.5; color: Theme.glow } }
                        RoundedImage { id: faceImg; anchors { fill: parent; margins: 3 } radius: width / 2; source: win.hasFace ? "file://" + win.face : ""; fallback: Theme.glass }
                        Heart { anchors.centerIn: parent; width: parent.width * 0.62; height: width; spin: false; visible: faceImg.status !== Image.Ready }
                    }
                                        Column {
                        x: avatar.x + avatar.width + 14; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                        width: keysRow.x - x - 10
                        Glow { width: parent.width; elide: Text.ElideRight; halo: 0.25; font { family: Theme.fontMono; pixelSize: 15; weight: Font.Bold } text: Quickshell.env("USER") + "@" + win.host }
                        Row {
                            spacing: 7
                            Text { anchors.verticalCenter: parent.verticalCenter; text: Theme.lex("uptime", "VIGIL"); color: Theme.glowDim; renderType: Text.NativeRendering
                                font { family: Theme.fontNum; pixelSize: 11; weight: Font.Bold; letterSpacing: 2.5 } }
                            Nixie { anchors.verticalCenter: parent.verticalCenter; size: 14; text: Sys.uptime }
                        }
                    }
                    Row {
                        id: keysRow
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        HeadBtn { icon: "edit"; tip: "Settings"; onHit: { Settings.toggle(false); Sanctum.close() } }
                        HeadBtn { icon: "restart_alt"; tip: "Reload Hyprland and the shell"; onHit: Quickshell.execDetached(["ms-session", "restart"]) }
                        HeadBtn { icon: "imagesmode"; tip: "Pict Archive"; onHit: { Sanctum.close(); Walls.toggle() } }
                        HeadBtn { icon: "power_settings_new"; tip: "Session"; danger: true; onHit: { Sanctum.close(); Power.toggle() } }
                    }
                }

                // ---------------- the vox bus
                SectionFrame {
                    id: voxFrame
                    width: parent.width
                    height: frameTop + voxCol.implicitHeight + 28
                    tab: Theme.lex("busTitle", "Vox"); tabIcon: "graphic_eq"
                    plate: Text {   // the output device
                        width: Math.min(implicitWidth, voxFrame.width - 170); elide: Text.ElideRight
                        text: (Pipewire.defaultAudioSink?.description || "no output").toUpperCase()
                        color: Theme.glowDim; renderType: Text.NativeRendering
                        font { family: Theme.fontNum; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1.6 }
                    }
                    Column {
                        id: voxCol
                        x: 12; y: 17; width: parent.width - 24
                        spacing: 8
                        Fader {
                            icon: muted ? "volume_off" : "volume_up"
                            level: win.sink?.volume ?? 0; muted: win.sink?.muted ?? true; available: !!win.sink
                            tip: muted ? "Sound muted: click to unmute" : "Click to mute"
                            onToggleMute: if (win.sink) win.sink.muted = !win.sink.muted
                            onAdjust: v => { if (win.sink) { win.sink.volume = v; if (win.sink.muted && v > 0) win.sink.muted = false } }
                        }
                        Fader {
                            icon: muted ? "mic_off" : "mic"
                            level: win.mic?.volume ?? 0; muted: win.mic?.muted ?? true; available: !!win.mic
                            tip: (Pipewire.defaultAudioSource?.description || "microphone") + (muted ? " · muted, click to open" : " · click to mute")
                            onToggleMute: if (win.mic) win.mic.muted = !win.mic.muted
                            onAdjust: v => { if (win.mic) { win.mic.volume = v; if (win.mic.muted && v > 0) win.mic.muted = false } }
                        }
                        Fader {
                            visible: Brightness.available
                            icon: "brightness_6"; canMute: false; muted: false
                            level: Brightness.value
                            onAdjust: v => Brightness.set(v)
                        }
                        // the playing track
                        Item {
                            id: vox
                            visible: Media.available
                            width: parent.width; height: visible ? 40 : 0
                            SectionFrame { anchors.fill: parent; radius: 5; fill: Qt.alpha(Theme.glow, 0.05); rim: Qt.alpha(Theme.glow, 0.16) }
                            Eq { x: 10; y: 11; width: 34; height: 18; count: 8; barWidth: 3; tone: Theme.glow; visible: win.mine && Media.playing }
                            Rectangle { x: 10; y: 20; width: 34; height: 1; color: Qt.alpha(Theme.glow, 0.3); visible: !(win.mine && Media.playing) }
                            Item {
                                x: 54; y: 5; width: parent.width - 54 - 96; height: 18; clip: true
                                Glow {
                                    id: voxTitle
                                    halo: 0; font { family: Theme.fontNum; pixelSize: 13; weight: Font.DemiBold }
                                    text: (Media.title || "Unknown track") + (Media.artist ? "  ·  " + Media.artist : "")
                                    readonly property bool runs: implicitWidth > parent.width
                                    onTextChanged: x = 0
                                    SequentialAnimation on x {
                                        running: voxTitle.runs && win.mine && Media.playing && Theme.motionEnabled; loops: Animation.Infinite
                                        PauseAnimation { duration: 1500 }
                                        NumberAnimation { to: -(voxTitle.implicitWidth - voxTitle.parent.width); duration: Math.max(2000, voxTitle.implicitWidth * 25) }
                                        PauseAnimation { duration: 1200 }
                                        NumberAnimation { to: 0; duration: 400 }
                                    }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Sanctum.close(); Popups.toggle("media", win.width - 220, win.modelData.name) } }
                            }
                            Item {   // progress
                                x: 54; y: 27; width: parent.width - 54 - 96; height: 6
                                property real pos: Media.player?.position ?? 0
                                Timer { interval: 1000; repeat: true; running: win.mine && Media.playing; onTriggered: { Media.player.positionChanged(); parent.pos = Media.player.position } }
                                Rectangle { y: 2; width: parent.width; height: 2; color: Qt.alpha(Theme.glow, 0.15) }
                                Rectangle { y: 2; width: parent.width * Math.min(1, parent.pos / Math.max(1, Media.player?.length ?? 1)); height: 2; color: Theme.glow }
                            }
                            Row {
                                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                                MiniBtn { icon: "skip_previous"; onHit: Media.player?.previous() }
                                MiniBtn { icon: Media.playing ? "pause" : "play_arrow"; on: Media.playing; onHit: Media.player?.togglePlaying() }
                                MiniBtn { icon: "skip_next"; onHit: Media.player?.next() }
                            }
                        }
                    }
                }

                // ---------------- the circuits
                Grid {
                    id: grid
                    width: parent.width
                    columns: win.compact ? 3 : 2
                    spacing: win.compact ? 8 : 10
                    readonly property real cell: (width - (columns - 1) * spacing) / columns
                    Card {
                        width: grid.cell; order: 0
                        label: "Network"; shortLabel: "Net"; icon: Net.online ? "lan" : "signal_disconnected"; lit: Net.online
                        reading: Net.online ? (Net.connection || Net.iface) : "Offline"
                        tip: Net.online ? "Click: networking off" : "Click: networking on"
                        moreTip: "Vox-caster: addresses and traffic"
                        onFlip: Quickshell.execDetached(["nmcli", "networking", Net.online ? "off" : "on"])
                        onMore: { Sanctum.close(); Popups.toggle("network", win.width - 260, win.modelData.name) }
                    }
                    Card {
                        width: grid.cell; order: 1
                        label: "Bluetooth"; shortLabel: "BT"; lit: win.bt?.enabled ?? false; available: !!win.bt
                        icon: !win.bt || !win.bt.enabled ? "bluetooth_disabled" : win.paired.length ? "bluetooth_connected" : "bluetooth"
                        reading: !win.bt ? "No adapter" : !win.bt.enabled ? "Off" : win.paired.length ? win.paired.map(d => d.name).join(", ") : "No device"
                        tip: !win.bt ? "" : win.bt.enabled ? "Click: bluetooth off" : "Click: bluetooth on"
                        moreTip: "Devices"
                        onFlip: if (win.bt) win.bt.enabled = !win.bt.enabled
                        onMore: { Sanctum.close(); Quickshell.execDetached(["blueman-manager"]) }
                    }
                    Card {
                        width: grid.cell; order: 2
                        label: "Quiet"; icon: Notifs.dnd ? "notifications_paused" : "notifications_active"; lit: Notifs.dnd
                        reading: Notifs.dnd ? "Popups held" : "Popups on"
                        tip: "Quiet: messages go to the vox log without popups"
                        onFlip: Notifs.dnd = !Notifs.dnd
                    }
                    Card {
                        width: grid.cell; order: 3
                        label: "Awake"; icon: Sanctum.keepAwake ? "visibility" : "visibility_off"; lit: Sanctum.keepAwake
                        reading: Sanctum.keepAwake ? "Sleep held off" : "May sleep"
                        tip: "Awake: no idle lock or sleep while on"
                        onFlip: Sanctum.keepAwake = !Sanctum.keepAwake
                    }
                    Card {
                        width: grid.cell; order: 4
                        label: "Game"; icon: Sanctum.gameMode ? "sports_esports" : "videogame_asset_off"; lit: Sanctum.gameMode
                        reading: Sanctum.gameMode ? "Effects stripped" : "Full effects"
                        tip: "Game: no animations, blur, shadows or gaps"
                        onFlip: Sanctum.gameMode = !Sanctum.gameMode
                    }
                    Card {
                        width: grid.cell; order: 5
                        label: "Night"; icon: NightLight.active ? "bedtime" : "bedtime_off"; lit: NightLight.active; available: NightLight.available
                        reading: !NightLight.available ? "hyprsunset missing" : NightLight.active ? NightLight.temperature + " K" : "Off · " + NightLight.temperature + " K"
                        tip: "Night light: click to switch, roll to warm or cool"
                        onFlip: NightLight.toggle()
                        onRoll: up => NightLight.nudge(up ? -1 : 1)
                    }
                }
            }

            // ---------------- the vox log
            SectionFrame {
                id: logFrame
                x: 16; width: parent.width - 32
                y: stack.y + stack.height + (win.compact ? 8 : 12)
                height: parent.height - y - 16
                tab: Theme.lex("logTitle", "Vox log"); tabIcon: "forum"
                plate: [
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 5
                        Nixie { anchors.verticalCenter: parent.verticalCenter; size: 14; text: String(Notifs.all.length).padStart(2, "0") }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Theme.lex("counter", "MSG"); color: Theme.glowDim; renderType: Text.NativeRendering
                            font { family: Theme.fontNum; pixelSize: 10; weight: Font.Bold; letterSpacing: 2 } }
                    },
                    Plate {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notifs.all.length > 0
                        height: 20; flat: true
                        label: "Purge"; danger: true; hold: true
                        onHit: { Notifs.clearAll(); Notifs.say(Theme.lex("logCleared", "")) }
                    }
                ]
                Item {
                    id: log
                    x: 10; y: 22; width: parent.width - 20; height: parent.height - y - 12
                    clip: true
                    Column {   // nothing on the vox
                        anchors.centerIn: parent
                        visible: Notifs.all.length === 0
                        spacing: 8
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 46; height: 1; color: Qt.alpha(Theme.glow, 0.3) }
                            Text { text: Notifs.line !== "" ? Notifs.line : "NO MESSAGES"; textFormat: Text.PlainText; color: Theme.glowDim; renderType: Text.NativeRendering
                                font { family: Theme.fontNum; pixelSize: 12; weight: Font.Bold; letterSpacing: 3 } }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 46; height: 1; color: Qt.alpha(Theme.glow, 0.3) }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Notifs.dnd ? "Quiet rite engaged: new messages wait here" : "Messages from your machines will gather here"
                            color: Qt.alpha(Theme.glowDim, 0.75); renderType: Text.NativeRendering
                            font { family: Theme.fontUi; pixelSize: 12; italic: true }
                        }
                    }
                    ListView {
                        id: groups
                        anchors.fill: parent
                        spacing: 8
                        model: Notifs.groups
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Missive { required property var modelData; group: modelData; width: groups.width }
                        add: Transition { enabled: Theme.motionEnabled
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dMedium }
                            NumberAnimation { property: "x"; from: 24; to: 0; duration: Theme.dMedium; easing.type: Easing.OutCubic } }
                        remove: Transition { enabled: Theme.motionEnabled
                            NumberAnimation { property: "opacity"; to: 0; duration: Theme.dClose }
                            NumberAnimation { property: "x"; to: 40; duration: Theme.dClose; easing.type: Easing.InCubic } }
                        displaced: Transition { enabled: Theme.motionEnabled; NumberAnimation { property: "y"; duration: Theme.dMedium; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // lamps warm up one by one when the panel opens
        property int warm: 0
        Connections { target: win; function onMineChanged() { win.warm = win.mine && Theme.motionEnabled ? 0 : (win.mine ? 9 : 0); if (win.mine && Theme.motionEnabled) warmer.restart(); else warmer.stop() } }
        Timer { id: warmer; interval: 45; repeat: true; onTriggered: { win.warm += 1; if (win.warm > 8) stop() } }

        // =============== parts
        component HeadBtn: Item {
            id: hb
            property string icon: ""
            property string tip: ""
            property bool danger: false
            signal hit()
            width: 36; height: 36
            Face { anchors.fill: parent; radius: 8; tone: hb.danger ? Theme.rustText : Theme.glow; danger: hb.danger; level: hm.pressed ? 0.24 : hm.containsMouse ? 0.14 : 0
                hovered: hm.containsMouse; pressed: hm.pressed }
            Icon { anchors.centerIn: parent; name: hb.icon; size: 21; color: hb.danger ? Theme.rustText : Theme.glow }
            MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hb.hit() }
            Tip { shown: hm.containsMouse; text: hb.tip }
        }
        component MiniBtn: Item {
            id: mb
            property string icon: ""
            property bool on: false
            signal hit()
            width: 30; height: 30
            Face { anchors.fill: parent; round: true; level: mbm.containsMouse ? 0.16 : (mb.on ? 0.12 : 0); hovered: mbm.containsMouse; pressed: mbm.pressed; on: mb.on }
            Icon { anchors.centerIn: parent; name: mb.icon; size: 18; color: mb.on ? Theme.glow : Theme.glowDim }
            MouseArea { id: mbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mb.hit() }
        }
        component Tip: Rectangle {
            property bool shown: false
            property string text: ""
            visible: shown && text !== ""
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 6 }
            width: tt.implicitWidth + 16; height: 22; radius: 5; z: 99
            color: Theme.glass; border { width: 1; color: Qt.alpha(Theme.glow, 0.4) }
            Text { id: tt; anchors.centerIn: parent; text: parent.text; color: Theme.glow; renderType: Text.NativeRendering; font { family: Theme.fontNum; pixelSize: 12 } }
        }

        // a fader on the vox bus: a mute key with the channel's glyph, a thick segment strip in a dark well and
        // the reading. Click, drag or roll along the strip; moving a muted channel opens it again.
        component Fader: Item {
            id: fd
            property string icon: ""
            property string tip: ""
            property real level: 0
            property bool muted: false
            property bool canMute: true
            property bool available: true
            signal adjust(real v)
            signal toggleMute()
            width: parent ? parent.width : 0; height: 34
            opacity: available ? 1 : 0.5
            property real shown: win.mine ? level : 0
            Behavior on shown { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.OutCubic } }
            readonly property bool off: muted && canMute
            readonly property color tone: off ? Theme.rustText : Theme.glow

            Item {
                id: muteKey
                width: 40; height: parent.height
                Face { anchors.fill: parent; radius: 7; tone: fd.tone; danger: fd.off; level: mk.pressed ? 0.22 : mk.containsMouse ? 0.14 : fd.off ? 0.1 : 0
                    edge: fd.off ? 0.55 : mk.containsMouse ? 0.3 : 0; hovered: mk.containsMouse; pressed: mk.pressed; on: fd.off }
                Icon { anchors.centerIn: parent; name: fd.icon; size: 22; color: fd.tone }
                MouseArea { id: mk; anchors.fill: parent; enabled: fd.canMute && fd.available; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: fd.toggleMute() }
                Tip { shown: mk.containsMouse; text: fd.tip }
            }
            Item {
                id: fstrip
                x: 52; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - 52; height: 16
                Track { anchors.fill: parent; level: fd.shown; off: fd.off; hovered: fsm.containsMouse || fsm.pressed }
                MouseArea {
                    id: fsm
                    anchors { fill: parent; topMargin: -9; bottomMargin: -9 }
                    enabled: fd.available; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    function at(mx) { fd.adjust(Math.max(0, Math.min(1, mx / fstrip.width))) }
                    onPressed: mouse => at(mouse.x)
                    onPositionChanged: mouse => { if (pressed) at(mouse.x) }
                    onWheel: wheel => fd.adjust(Math.max(0, Math.min(1, fd.level + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
                }
            }
            Nixie { anchors { right: parent.right; rightMargin: 2; verticalCenter: parent.verticalCenter } size: 18
                text: fd.off ? "--" : String(Math.round(fd.level * 100)).padStart(2, "0") }
        }

        // a circuit module: the glyph sits in a round glass well, beside it the name and one live reading.
        // An engaged module glows along its rim, well and name; that is its only state mark. The whole module
        // is the switch; `moreTip` adds a key for details (a right click does the same); `roll` takes the wheel.
        component Card: Item {
            id: cd
            property int order: 0
            property string label: ""
            property string shortLabel: label   // for the dense desk on short screens
            property string reading: ""
            property string icon: ""
            property string tip: ""
            property string moreTip: ""
            property bool lit: false
            property bool available: true
            signal flip()
            signal more()
            signal roll(bool up)
            readonly property bool on: lit && win.warm > order
            height: win.compact ? 52 : 66
            opacity: available ? 1 : 0.5

            SectionFrame { anchors.fill: parent; radius: 10; glow: cd.on
                fill: cd.on ? Qt.tint(Qt.alpha(Theme.glass, 0.85), Qt.alpha(Theme.glow, 0.06)) : Qt.alpha(Theme.glass, 0.8) }
            Face {   // hover wash
                anchors { fill: parent; margins: 1 } radius: 9
                level: ma.pressed ? Theme.pressLayer : ma.containsMouse ? Theme.hoverLayer : 0
                hovered: ma.containsMouse && !mkk.containsMouse; pressed: ma.pressed
                visible: Skin.control === "mechanicus" || hovered || pressed
            }
            MouseArea {
                id: ma
                anchors.fill: parent; enabled: cd.available; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => (mouse.button === Qt.RightButton && cd.moreTip !== "") ? cd.more() : cd.flip()
                onWheel: wheel => cd.roll(wheel.angleDelta.y > 0)
            }
            Tip { shown: ma.containsMouse && !mkk.containsMouse; text: cd.tip }

            Well {   // the glyph in its well; the well lights with the module
                id: well
                x: win.compact ? 8 : 12; anchors.verticalCenter: parent.verticalCenter
                width: win.compact ? 32 : 40; height: width
                lit: cd.on
                Icon { anchors.centerIn: parent; name: cd.icon; size: win.compact ? 18 : 21; color: cd.on ? Theme.glow : Theme.glowDim }
            }
            Column {
                x: well.x + well.width + 12; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - (cd.moreTip !== "" ? 34 : 10)
                spacing: 3
                Glow {
                    width: parent.width; elide: Text.ElideRight; halo: cd.on ? 0.45 : 0
                    color: cd.on ? Theme.glow : Theme.surfaceVariantOn
                    text: (win.compact ? cd.shortLabel : cd.label).toUpperCase()
                    font { family: Theme.fontNum; pixelSize: 13; weight: Font.Bold; letterSpacing: 2 }
                }
                Text { width: parent.width; elide: Text.ElideRight; text: cd.reading; color: Theme.glowDim; renderType: Text.NativeRendering
                    font { family: Theme.fontUi; pixelSize: 12 } }
            }
            Item {
                visible: cd.moreTip !== ""
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: 28; height: 28
                Face { anchors.fill: parent; radius: 6; level: mkk.pressed ? 0.2 : mkk.containsMouse ? 0.12 : 0; hovered: mkk.containsMouse; pressed: mkk.pressed }
                Icon { anchors.centerIn: parent; name: "chevron_right"; size: 20; color: mkk.containsMouse ? Theme.glow : Theme.glowDim }
                MouseArea { id: mkk; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cd.more() }
                Tip { shown: mkk.containsMouse; text: cd.moreTip }
            }
        }

        // an engraved plate button; `hold`: press and keep it down to confirm (a bar fills)
        component Plate: Item {
            id: pl
            property string label: ""
            property bool on: false
            property bool danger: false
            property bool hold: false
            property bool flat: false      // no frame of its own: it sits inside a plate
            property real charge: 0
            signal hit()
            readonly property color tone: danger ? Theme.rustText : Theme.glow
            width: plt.implicitWidth + 34; height: 28
            Face { anchors.fill: parent; radius: 5; tone: pl.tone; danger: pl.danger; level: pl.on ? 0.22 : (plm.containsMouse ? 0.14 : pl.flat ? 0 : 0.05); edge: pl.flat ? (plm.containsMouse ? 0.4 : 0) : pl.on ? 0.7 : 0.35
                hovered: plm.containsMouse; pressed: plm.pressed; on: pl.on || pl.charge > 0 }
            Rectangle { anchors { left: parent.left; bottom: parent.bottom; margins: 1 } height: 2; width: (parent.width - 2) * pl.charge; color: pl.tone; visible: pl.hold }
            Lamp { x: 4; anchors.verticalCenter: parent.verticalCenter; lit: pl.on || pl.charge > 0; size: 6; tone: pl.tone }
            Text { id: plt; x: 22; anchors.verticalCenter: parent.verticalCenter; text: "[" + pl.label.toUpperCase() + "]"; color: pl.tone; renderType: Text.NativeRendering
                font { family: Theme.fontMono; pixelSize: 11; weight: Font.Bold } }
            NumberAnimation { id: chargeAnim; target: pl; property: "charge"; from: 0; to: 1; duration: 600; onFinished: { pl.hit(); pl.charge = 0 } }
            MouseArea { id: plm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onPressed: if (pl.hold) chargeAnim.restart()
                onReleased: if (pl.hold && chargeAnim.running) { chargeAnim.stop(); pl.charge = 0 }
                onClicked: if (!pl.hold) pl.hit() }
            Tip { shown: plm.containsMouse && pl.hold; text: "Hold to purge the log" }
        }

        // one application's messages: a header with its icon, name, count and time, then its newest messages.
        // More than two fold away behind "n more"; the header's keys unfold and dismiss the whole group.
        component Missive: Item {
            id: ms
            property var group
            property bool unfolded: false
            readonly property var items: group?.items ?? []
            readonly property bool critical: items.some(n => n.urgency === 2)
            height: mcol.implicitHeight + 18

            SectionFrame {
                anchors.fill: parent; radius: 6
                fill: Qt.alpha(ms.critical ? Theme.rustText : Theme.glow, 0.05)
                rim: Qt.alpha(ms.critical ? Theme.rustText : Theme.glow, ms.critical ? 0.4 : 0.16)
            }
            Rectangle { x: 0; y: 8; width: 2; height: parent.height - 16; radius: 1; color: ms.critical ? Theme.rustText : Theme.glow; opacity: 0.8 }
            Column {
                id: mcol
                x: 12; y: 9; width: parent.width - 22
                spacing: 8
                Item {   // header
                    width: parent.width; height: 24
                    Item {
                        id: appIcon
                        width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter
                        PrivateImage {
                            id: appImg
                            anchors.fill: parent
                            requestSource: ms.group?.icon ? Quickshell.iconPath(ms.group.icon, true) : ""
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }
                        Icon { anchors.centerIn: parent; visible: appImg.status !== Image.Ready; name: "campaign"; size: 18; color: ms.critical ? Theme.rustText : Theme.glow }
                    }
                    Text {
                        id: appName
                        x: 30; anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, headKeys.x - x - countText.width - 60)
                        elide: Text.ElideRight
                        text: (ms.group?.app ?? "").toUpperCase(); color: ms.critical ? Theme.rustText : Theme.glow; renderType: Text.NativeRendering
                        font { family: Theme.fontNum; pixelSize: 12; weight: Font.Bold; letterSpacing: 1.6 }
                    }
                    Text { id: countText; anchors { left: appName.right; leftMargin: 8; verticalCenter: parent.verticalCenter } visible: ms.items.length > 1
                        text: "×" + ms.items.length; color: Theme.glowDim; renderType: Text.NativeRendering; font { family: Theme.fontNum; pixelSize: 11; weight: Font.Bold } }
                    Row {
                        id: headKeys
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        Text { anchors.verticalCenter: parent.verticalCenter; rightPadding: 6; text: ms.items.length ? Notifs.when(ms.items[0]) : ""; color: Theme.glowDim; renderType: Text.NativeRendering
                            font { family: Theme.fontNum; pixelSize: 11; features: { "tnum": 1 } } }
                        KeyBtn { visible: ms.items.length > 2; icon: ms.unfolded ? "unfold_less" : "unfold_more"; tip: ms.unfolded ? "Fold" : "Show all"; onHit: ms.unfolded = !ms.unfolded }
                        KeyBtn { icon: "close"; tip: "Dismiss all from " + (ms.group?.app ?? ""); onHit: Notifs.dismissGroup(ms.group) }
                    }
                }
                Repeater {
                    model: ms.unfolded ? ms.items : ms.items.slice(0, 2)
                    Message { required property var modelData; notif: modelData; width: mcol.width }
                }
                Text {
                    visible: !ms.unfolded && ms.items.length > 2
                    text: "+ " + (ms.items.length - 2) + " more"
                    color: moreMa.containsMouse ? Theme.glow : Theme.glowDim; renderType: Text.NativeRendering
                    font { family: Theme.fontNum; pixelSize: 11; weight: Font.Bold; letterSpacing: 1 }
                    MouseArea { id: moreMa; anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ms.unfolded = true }
                }
            }
        }

        // one message: its summary and time, the body, and its commands; copy and dismiss on hover
        component Message: Item {
            id: msg
            property var notif
            readonly property bool critical: notif?.urgency === 2
            height: msgCol.implicitHeight
            MouseArea { id: msgHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
            Column {
                id: msgCol
                width: parent.width
                spacing: 3
                Item {
                    width: parent.width; height: Math.max(summary.implicitHeight, 22)
                    PuritySeal { id: seal; visible: msg.critical; x: 0; y: 1; size: 18; text: "!" }
                    Text {
                        id: summary
                        x: msg.critical ? 24 : 0; width: parent.width - x - (msgHover.containsMouse ? 60 : 44)
                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                        text: msg.notif?.summary ?? ""; color: msg.critical ? Theme.rustText : Theme.glow; renderType: Text.NativeRendering
                        font { family: Theme.fontUi; pixelSize: 13; weight: Font.DemiBold }
                    }
                    Text { anchors { right: parent.right; top: parent.top; topMargin: 2 } visible: !msgHover.containsMouse
                        text: msg.notif ? Notifs.when(msg.notif) : ""; color: Qt.alpha(Theme.glowDim, 0.8); renderType: Text.NativeRendering
                        font { family: Theme.fontNum; pixelSize: 10; features: { "tnum": 1 } } }
                    Row {
                        anchors { right: parent.right; top: parent.top; topMargin: -2 }
                        visible: msgHover.containsMouse
                        KeyBtn { icon: "content_copy"; tip: "Copy"; onHit: Notifs.copy(msg.notif) }
                        KeyBtn { icon: "close"; tip: "Dismiss"; onHit: Notifs.dismiss(msg.notif) }
                    }
                }
                Text {
                    visible: text !== ""
                    width: parent.width; leftPadding: msg.critical ? 24 : 0; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight
                    text: msg.notif?.body ?? ""; color: Theme.glowDim; renderType: Text.NativeRendering
                    font { family: Theme.fontUi; pixelSize: 12 }
                }
                Flow {
                    visible: (msg.notif?.actions?.length ?? 0) > 0
                    width: parent.width; spacing: 6; topPadding: 3
                    Repeater {
                        model: msg.notif?.actions ?? []
                        Rectangle {
                            required property var modelData
                            width: actText.implicitWidth + 20; height: 24; color: "transparent"
                            Face { anchors.fill: parent; radius: 5; level: actMa.pressed ? 0.22 : actMa.containsMouse ? 0.14 : 0.06; edge: 0.35; hovered: actMa.containsMouse; pressed: actMa.pressed; on: Skin.control !== "mechanicus" }
                            Text { id: actText; anchors.centerIn: parent; text: modelData.text; color: Theme.glow; renderType: Text.NativeRendering
                                font { family: Theme.fontNum; pixelSize: 12; weight: Font.DemiBold } }
                            MouseArea { id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                        }
                    }
                }
            }
        }

        component KeyBtn: Item {
            id: kb
            property string icon: ""
            property string tip: ""
            signal hit()
            width: 26; height: 26
            Face { anchors.fill: parent; radius: 6; level: kbm.pressed ? 0.2 : kbm.containsMouse ? 0.12 : 0; hovered: kbm.containsMouse; pressed: kbm.pressed }
            Icon { anchors.centerIn: parent; name: kb.icon; size: 16; color: kbm.containsMouse ? Theme.glow : Theme.glowDim }
            MouseArea { id: kbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: kb.hit() }
            Tip { shown: kbm.containsMouse; text: kb.tip }
        }
    }
}
