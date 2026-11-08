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
import QtQuick.Effects
import qs.common
import qs.services

// Sanctum: the control desk on the right. A board with the machine and its vigil, a row of knife switches
// with lamps, link indicators, two level columns (brightness or mic, and volume) around the vox strip and
// the teletype log of messages. Slides in from the edge; a click elsewhere or Esc closes it. Created on
// first use.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        property bool ready: false
        Component.onCompleted: Qt.callLater(() => ready = true)
        readonly property bool mine: ready && Sanctum.open && (Settings.primary()?.name ?? modelData.name) === modelData.name
        onMineChanged: if (mine) { Brightness.probe(); Notifs.markRead(); glass.powerOn(); keys.forceActiveFocus() }

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
        PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
        property string host: ""
        FileView { path: "/etc/hostname"; onLoaded: win.host = text().trim() }
        readonly property string face: Quickshell.env("HOME") + "/.face"
        property bool hasFace: false
        Process { running: true; command: ["test", "-f", win.face]; onExited: code => win.hasFace = code === 0 }

        // the newest message types itself out when it arrives while the panel is open
        property int typedId: -1
        property int typed: 999
        Connections {
            target: Notifs
            function onAllChanged() {
                const n = Notifs.all[Notifs.all.length - 1]
                if (!win.mine || !n || n.id === win.typedId || !Theme.motionEnabled) return
                win.typedId = n.id; win.typed = 0; typer.restart()
            }
        }
        Timer { id: typer; interval: 16; repeat: true; onTriggered: { win.typed += 3; if (win.typed > 120) stop() } }

        Item {
            id: panel
            width: 440
            y: 50; height: win.height - y - 10
            enabled: win.mine
            property real slide: win.mine ? 0 : 1
            Behavior on slide { NumberAnimation { duration: win.mine ? Theme.dLong : Theme.dClose; easing.type: win.mine ? Easing.OutCubic : Easing.InCubic } }
            x: win.width - width - 10 + slide * (width + 20)
            opacity: 1 - slide * 0.6
            MouseArea { anchors.fill: parent }

            Bezel { anchors.fill: parent; radius: 14; inset: 0; boltSize: 5 }
            CrtScreen { id: glass; anchors { fill: parent; margins: 7 } radius: 9; padding: 0; bootOnLoad: false; ambient: false }
            Flicker { anchors { fill: parent; margins: 7 } radius: 9; active: win.mine; z: 20 }

            // ---------------- the board
            Item {
                id: board
                x: 19; y: 17; width: parent.width - 38; height: 84
                ScreenTitle { x: 0; y: 2; text: "Sanctum" }
                SystemClock { id: clock; precision: SystemClock.Minutes }
                Nixie { anchors { right: parent.right; top: parent.top } size: 18; text: Qt.formatTime(clock.date, "HH:mm") }
                Item {   // avatar in a phosphor ring
                    y: 32; width: 46; height: 46
                    Rectangle { anchors.fill: parent; radius: 23; color: Theme.glass; border { width: 1.5; color: Theme.glow } }
                    RoundedImage { id: faceImg; anchors { fill: parent; margins: 3 } radius: 20; source: win.hasFace ? "file://" + win.face : ""; fallback: Theme.glass }
                    Gear { anchors.centerIn: parent; width: 28; height: 28; outline: true; filled: false; teeth: 10; spin: false; visible: faceImg.status !== Image.Ready }
                }
                Column {
                    x: 56; y: 34; spacing: 3
                    Glow { halo: 0.2; font { family: Theme.fontMono; pixelSize: 14; weight: Font.Bold } text: Quickshell.env("USER") + "@" + win.host }
                    Row {
                        spacing: 6
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "VIGIL"; color: Theme.glowDim; renderType: Text.NativeRendering
                            font { family: Theme.fontNum; pixelSize: 10; weight: Font.Bold; letterSpacing: 2 } }
                        Nixie { anchors.verticalCenter: parent.verticalCenter; size: 13; text: Sys.uptime }
                    }
                }
                Row {
                    anchors { right: parent.right; bottom: parent.bottom; bottomMargin: 2 }
                    spacing: 0
                    HeadBtn { icon: "edit"; tip: "Settings"; onHit: { Settings.toggle(false); Sanctum.close() } }
                    HeadBtn { icon: "restart_alt"; tip: "Reload Hyprland and the shell"; onHit: Quickshell.execDetached(["ms-session", "restart"]) }
                    HeadBtn { icon: "imagesmode"; tip: "Pict Archive"; onHit: { Sanctum.close(); Walls.toggle() } }
                    HeadBtn { icon: "power_settings_new"; tip: "Session"; danger: true; onHit: { Sanctum.close(); Power.toggle() } }
                }
            }
            Rule { y: board.y + board.height + 8 }

            // ---------------- the switches
            Item {
                id: switches
                x: 19; width: parent.width - 38; height: 92
                y: board.y + board.height + 18
                Row {
                    id: levers
                    spacing: 2
                    ToggleSwitch { label: "Awake"; tip: "Keep the machine awake"; on: Sanctum.keepAwake && win.warm > 0; onToggled: Sanctum.keepAwake = !Sanctum.keepAwake }
                    ToggleSwitch { label: "Game"; tip: "Game mode: no animations, blur or gaps"; on: Sanctum.gameMode && win.warm > 1; onToggled: Sanctum.gameMode = !Sanctum.gameMode }
                    ToggleSwitch { label: "Mic"; tip: "Microphone"; on: !(win.mic?.muted ?? true) && win.warm > 2; onToggled: if (win.mic) win.mic.muted = !win.mic.muted }
                    ToggleSwitch { label: "Sound"; tip: "Sound"; on: !(win.sink?.muted ?? true) && win.warm > 3; onToggled: if (win.sink) win.sink.muted = !win.sink.muted }
                    ToggleSwitch { label: "Alerts"; tip: Notifs.dnd ? "Quiet: messages kept, no popups" : "Popups on"; on: !Notifs.dnd && win.warm > 4; onToggled: Notifs.dnd = !Notifs.dnd }
                    ToggleSwitch { label: "Shot"; tip: "Screenshot of an area"; momentary: true
                        onToggled: { Sanctum.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec ms-screenshot region"]) } }
                }
                Column {   // links
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Link {
                        label: "Net"; lit: Net.online && win.warm > 5
                        detail: Net.online ? (Net.connection || Net.iface) : "offline"
                        tip: "Left: networking on/off. Right: the Vox-caster"
                        onHit: Quickshell.execDetached(["nmcli", "networking", Net.online ? "off" : "on"])
                        onMore: { Sanctum.close(); Popups.toggle("network", win.width - 260, win.modelData.name) }
                    }
                    Link {
                        label: "Bt"; lit: (win.bt?.enabled ?? false) && win.warm > 5
                        detail: !win.bt ? "no adapter" : !win.bt.enabled ? "off" : (Bluetooth.devices.values.filter(d => d.connected).map(d => d.name)[0] ?? "idle")
                        tip: "Left: on/off. Right: devices"
                        onHit: if (win.bt) win.bt.enabled = !win.bt.enabled
                        onMore: { Sanctum.close(); Quickshell.execDetached(["blueman-manager"]) }
                    }
                }
            }
            Rule { y: switches.y + switches.height + 6 }

            // ---------------- the bay: two level columns with the vox strip and the log between them
            Item {
                id: bay
                x: 19; width: parent.width - 38
                y: switches.y + switches.height + 16
                height: footer.y - y - 10
                LevelColumn {
                    id: leftCol
                    height: parent.height
                    readonly property bool bright: Brightness.available
                    icon: bright ? "brightness_6" : ((win.mic?.muted ?? false) ? "mic_off" : "mic")
                    value: win.mine ? (bright ? Brightness.value : (win.mic?.volume ?? 0)) : 0
                    dim: !bright && (win.mic?.muted ?? false)
                    onMoved: v => { if (bright) Brightness.set(v); else if (win.mic) win.mic.volume = v }
                }
                LevelColumn {
                    anchors.right: parent.right
                    height: parent.height
                    icon: (win.sink?.muted ?? false) ? "volume_off" : "volume_up"
                    value: win.mine ? (win.sink?.volume ?? 0) : 0
                    dim: win.sink?.muted ?? false
                    onMoved: v => { if (win.sink) win.sink.volume = v }
                }
                Item {
                    id: mid
                    x: 44; width: parent.width - 88; height: parent.height

                    // vox strip
                    Item {
                        id: vox
                        visible: Media.available
                        width: parent.width; height: visible ? 52 : 0
                        Rectangle { anchors.fill: parent; radius: 6; color: Qt.alpha(Theme.glow, 0.05); border { width: 1; color: Qt.alpha(Theme.glow, 0.18) } }
                        Eq { x: 8; y: 9; width: 34; height: 18; count: 8; barWidth: 3; tone: Theme.glow; visible: win.mine && Media.playing }
                        Rectangle { x: 8; y: 25; width: 34; height: 1; color: Qt.alpha(Theme.glow, 0.3); visible: !(win.mine && Media.playing) }
                        Item {
                            x: 50; y: 6; width: parent.width - 50 - 92; height: 18; clip: true
                            Glow {
                                id: voxTitle
                                halo: 0; font { family: Theme.fontMono; pixelSize: 13; weight: Font.Bold }
                                text: (Media.title || "Unknown track") + (Media.artist ? "  //  " + Media.artist : "")
                                readonly property bool runs: implicitWidth > parent.width
                                onTextChanged: x = 0
                                SequentialAnimation on x {
                                    running: voxTitle.runs && win.mine && Media.playing && !Theme.lowPower; loops: Animation.Infinite
                                    PauseAnimation { duration: 1500 }
                                    NumberAnimation { to: -(voxTitle.implicitWidth - voxTitle.parent.width); duration: Math.max(2000, voxTitle.implicitWidth * 25) }
                                    PauseAnimation { duration: 1200 }
                                    NumberAnimation { to: 0; duration: 400 }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Sanctum.close(); Popups.toggle("media", win.width - 220, win.modelData.name) } }
                        }
                        Item {   // progress
                            x: 50; y: 34; width: parent.width - 50 - 92; height: 6
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

                    // the teletype log
                    Item {
                        id: log
                        y: vox.height + (vox.visible ? 10 : 0)
                        width: parent.width; height: parent.height - y
                        clip: true
                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 30 }
                            visible: Notifs.all.length === 0
                            text: "++ VOX LOG CLEAR ++" + (cursorBlink.on ? " _" : "  ")
                            color: Theme.glowDim; renderType: Text.NativeRendering
                            font { family: Theme.fontMono; pixelSize: 12; weight: Font.Bold }
                            Timer { id: cursorBlink; property bool on: true; interval: 530; repeat: true; running: win.mine && Notifs.all.length === 0; onTriggered: on = !on }
                        }
                        ListView {
                            id: groups
                            anchors.fill: parent
                            spacing: 6
                            model: Notifs.groups
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Group { required property var modelData; group: modelData; width: groups.width }
                            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.dMedium; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ---------------- footer: quiet, count, purge
            Item {
                id: footer
                x: 19; width: parent.width - 38; height: 34
                y: parent.height - height - 17
                Rule { y: -6; x: -19 }
                Plate {
                    anchors.verticalCenter: parent.verticalCenter
                    label: "Quiet"; on: Notifs.dnd
                    onHit: Notifs.dnd = !Notifs.dnd
                }
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Nixie { anchors.verticalCenter: parent.verticalCenter; size: 16; text: String(Notifs.all.length).padStart(2, "0") }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "MSG"; color: Theme.glowDim; renderType: Text.NativeRendering
                        font { family: Theme.fontNum; pixelSize: 10; weight: Font.Bold; letterSpacing: 2 } }
                }
                Plate {
                    id: purge
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    label: "Purge"; danger: true; hold: true
                    onHit: Notifs.clearAll()
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
            width: 32; height: 32
            Rectangle { anchors.fill: parent; radius: 16; color: Qt.alpha(hb.danger ? Theme.rustText : Theme.glow, hm.containsMouse ? 0.2 : 0) }
            Icon { anchors.centerIn: parent; name: hb.icon; size: 19; color: hb.danger ? Theme.rustText : Theme.glow }
            MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hb.hit() }
            Tip { shown: hm.containsMouse; text: hb.tip }
        }
        component MiniBtn: Item {
            id: mb
            property string icon: ""
            property bool on: false
            signal hit()
            width: 28; height: 28
            Rectangle { anchors.fill: parent; radius: 14; color: Qt.alpha(Theme.glow, mbm.containsMouse ? 0.16 : (mb.on ? 0.12 : 0)) }
            Icon { anchors.centerIn: parent; name: mb.icon; size: 17; color: mb.on ? Theme.glow : Theme.glowDim }
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
        // an engraved rule across the panel
        component Rule: Rectangle { x: 19; width: panel.width - 38; height: 1; color: Qt.alpha(Theme.glow, 0.16) }

        // a link indicator: lamp, label and what it is connected to; click switches, right click opens its settings
        component Link: Item {
            id: lk
            property string label: ""
            property string detail: ""
            property string tip: ""
            property bool lit: false
            signal hit()
            signal more()
            width: 88; height: 38
            Rectangle { anchors.fill: parent; radius: 6; color: Qt.alpha(Theme.glow, lkm.containsMouse ? 0.1 : 0.04); border { width: 1; color: Qt.alpha(Theme.glow, lk.lit ? 0.4 : 0.18) } }
            Lamp { x: 4; anchors.verticalCenter: parent.verticalCenter; lit: lk.lit; size: 7 }
            Column {
                x: 22; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 26
                Text { text: lk.label.toUpperCase(); color: lk.lit ? Theme.glow : Theme.glowDim; renderType: Text.NativeRendering
                    font { family: Theme.fontNum; pixelSize: 11; weight: Font.Bold; letterSpacing: 1.5 } }
                Text { width: parent.width; elide: Text.ElideRight; text: lk.detail; color: Theme.glowDim; renderType: Text.NativeRendering; font { family: Theme.fontMono; pixelSize: 9 } }
            }
            MouseArea { id: lkm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? lk.more() : lk.hit() }
            Tip { shown: lkm.containsMouse; text: lk.tip }
        }

        // an engraved plate button; `hold`: press and keep it down to confirm (a bar fills)
        component Plate: Item {
            id: pl
            property string label: ""
            property bool on: false
            property bool danger: false
            property bool hold: false
            property real charge: 0
            signal hit()
            readonly property color tone: danger ? Theme.rustText : Theme.glow
            width: plt.implicitWidth + 34; height: 28
            Rectangle { anchors.fill: parent; radius: 5; color: Qt.alpha(pl.tone, pl.on ? 0.22 : (plm.containsMouse ? 0.12 : 0.05)); border { width: 1; color: Qt.alpha(pl.tone, pl.on ? 0.7 : 0.35) } }
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

        // one application's messages on the teletype: a header line, then a line per message; unfolded,
        // each message prints in full with its commands
        component Group: Item {
            id: gr
            property var group
            property bool unfolded: false
            readonly property var items: group?.items ?? []
            height: col.implicitHeight + 4
            Column {
                id: col
                width: parent.width
                spacing: 2
                Item {
                    width: parent.width; height: 20
                    Rectangle { anchors.fill: parent; radius: 3; color: Qt.alpha(Theme.glow, hm2.containsMouse ? 0.1 : 0.05) }
                    Text {
                        x: 4; anchors.verticalCenter: parent.verticalCenter
                        text: (gr.unfolded ? "▾ " : "▸ ") + (gr.group?.app ?? "").toUpperCase() + "  ×" + gr.items.length
                        color: Theme.glow; renderType: Text.NativeRendering
                        font { family: Theme.fontMono; pixelSize: 11; weight: Font.Bold; letterSpacing: 1 }
                    }
                    Text { anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                        text: gr.items.length ? Notifs.when(gr.items[0]) : ""; color: Theme.glowFaint; renderType: Text.NativeRendering; font { family: Theme.fontMono; pixelSize: 10 } }
                    MouseArea { id: hm2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gr.unfolded = !gr.unfolded }
                    Text { anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                        text: "×"; color: xm.containsMouse ? Theme.rustText : Theme.glowDim; renderType: Text.NativeRendering; font { family: Theme.fontMono; pixelSize: 13; weight: Font.Bold }
                        MouseArea { id: xm; anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dismissGroup(gr.group) } }
                }
                Repeater {
                    model: gr.unfolded ? gr.items : gr.items.slice(0, 3)
                    Item {
                        id: entry
                        required property var modelData
                        readonly property string line: modelData.summary + (modelData.body ? " — " + modelData.body.replace(/\n/g, " ") : "")
                        readonly property bool typing: modelData.id === win.typedId && win.typed < line.length
                        width: col.width
                        height: gr.unfolded ? full.implicitHeight + 6 : 17
                        Text {   // folded: one teletype line
                            visible: !gr.unfolded
                            x: 4; width: parent.width - 8; elide: Text.ElideRight
                            text: "<font color='" + Theme.glowFaint + "'>" + Notifs.when(entry.modelData) + "</font>  "
                                + (entry.typing ? entry.line.slice(0, win.typed) + "▌" : entry.line).replace(/&/g, "&amp;").replace(/</g, "&lt;")
                            textFormat: Text.StyledText
                            color: Theme.glowDim; renderType: Text.NativeRendering
                            font { family: Theme.fontMono; pixelSize: 11 }
                        }
                        Column {   // unfolded: the whole message and its commands
                            id: full
                            visible: gr.unfolded
                            x: 4; y: 3; width: parent.width - 8; spacing: 3
                            Text { width: parent.width; wrapMode: Text.Wrap; color: Theme.glow; renderType: Text.NativeRendering
                                font { family: Theme.fontMono; pixelSize: 11; weight: Font.Bold } text: Notifs.when(entry.modelData) + "  " + entry.modelData.summary }
                            Text { width: parent.width; visible: text !== ""; wrapMode: Text.Wrap; maximumLineCount: 8; elide: Text.ElideRight; color: Theme.glowDim
                                renderType: Text.NativeRendering; font { family: Theme.fontMono; pixelSize: 11 } text: entry.modelData.body }
                            Row {
                                spacing: 10
                                Repeater {
                                    model: entry.modelData.actions
                                    Cmd { required property var modelData; label: modelData.text; onHit: modelData.invoke() }
                                }
                                Cmd { label: "copy"; onHit: Notifs.copy(entry.modelData) }
                                Cmd { label: "x"; danger: true; onHit: Notifs.dismiss(entry.modelData) }
                            }
                        }
                    }
                }
            }
        }
        // a teletype command: [label]
        component Cmd: Text {
            id: cmd
            property string label: ""
            property bool danger: false
            signal hit()
            text: "[" + label.toUpperCase() + "]"
            color: cmm.containsMouse ? (danger ? Theme.rustText : Theme.glow) : Theme.glowDim
            renderType: Text.NativeRendering
            font { family: Theme.fontMono; pixelSize: 10; weight: Font.Bold }
            MouseArea { id: cmm; anchors { fill: parent; margins: -3 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cmd.hit() }
        }
    }
}
