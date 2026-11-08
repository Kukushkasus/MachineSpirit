// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import qs.common
import qs.services

// Command console: the query terminal at the top centre, the strip of ten sectors under it.
// Typing searches machines (apps) and filters the sectors; Enter invokes. Ctrl+arrows walk the sectors.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        // created lazily: `ready` flips right after creation so the opening animation still runs
        property bool ready: false
        Component.onCompleted: Qt.callLater(() => ready = true)
        readonly property bool mine: ready && Launcher.open && (Settings.primary()?.name ?? modelData.name) === modelData.name
        property string query: ""
        property var results: []
        property int selected: 0
        property var usage: ({})
        property int pick: Hyprland.focusedWorkspace?.id ?? 1
        readonly property bool typing: query.trim() !== ""
        readonly property var numerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

        // the surface stays mapped, so opening only flips properties instead of creating a window;
        // while closed it takes no input and draws nothing. (Hyprland 0.57.0 paints such surfaces black;
        // The virtio workaround lives in the Hyprland configuration.)
        readonly property bool showing: mine || shell.opacity > 0.01
        visible: true
        mask: showing ? null : noInput
        Region { id: noInput }
        WlrLayershell.namespace: "machinespirit-console"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        Connections {
            target: DesktopEntries.applications
            function onValuesChanged() { if (win.mine) win.refresh() }
        }
        onMineChanged: {
            if (mine) {
                field.text = Launcher.preset; Launcher.preset = ""; query = field.text; selected = 0
                pick = Hyprland.focusedWorkspace?.id ?? 1
                field.forceActiveFocus()
                screen.powerOn(); skL.arrive(); skR.arrive(); skSL.arrive(); skSR.arrive()
                Qt.callLater(() => { refresh(); Hyprland.refreshToplevels() })   // after the first frame is out
            }
        }

        // ---------------- usage statistics
        readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/machinespirit"
        FileView { path: win.stateDir + "/launcher.json"; printErrors: false; onLoaded: { try { win.usage = JSON.parse(text()) } catch (e) {} } }
        function bump(id) {
            const u = Object.assign({}, usage); u[id] = (u[id] || 0) + 1; usage = u
            saveUsage.restart()
        }

        Timer { id: saveUsage; interval: 200; onTriggered: { if (usageWriter.running) restart(); else usageWriter.running = true } }
        Process {
            id: usageWriter
            command: ["python3", Quickshell.shellPath("scripts/save-json.py"), win.stateDir + "/launcher.json"]
            stdinEnabled: true
            onStarted: { write(JSON.stringify(win.usage) + "\n"); stdinEnabled = false }
            onExited: stdinEnabled = true
        }

        // ---------------- search
        function fuzzy(q, s) { let i = 0; for (const c of s) { if (c === q[i]) i++; if (i === q.length) return true } return false }
        function scoreOf(e, q) {
            const n = (e.name || "").toLowerCase()
            let s = 0
            if (n.startsWith(q)) s = 100 - n.length * 0.1
            else if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 80
            else if (n.includes(q)) s = 60
            else if (fuzzy(q, n)) s = 40
            else if (((e.genericName || "") + " " + (e.comment || "") + " " + (e.keywords || []).join(" ")).toLowerCase().includes(q)) s = 25
            if (s > 0) s += Math.min(20, (usage[e.id] || 0) * 2)
            return s
        }
        function calc(text) {
            if (!/^[0-9+\-*\/().%^,\s]+$/.test(text) || !/[0-9]/.test(text) || !/[+\-*\/%^]/.test(text.replace(/^\s*-/, ""))) return null
            try { const v = Function('"use strict"; return (' + text.replace(/\^/g, "**").replace(/,/g, ".") + ")")(); return (typeof v === "number" && isFinite(v)) ? String(Math.round(v * 1e10) / 1e10) : null }
            catch (e) { return null }
        }
        // highlight the letters of q inside name (rich text)
        function marked(name, q) {
            const esc = c => c.replace(/&/g, "&amp;").replace(/</g, "&lt;")
            q = q.toLowerCase()
            if (q === "") return esc(name)
            let out = "", j = 0
            for (const c of name) {
                if (j < q.length && c.toLowerCase() === q[j]) { out += "<u>" + esc(c) + "</u>"; j++ }
                else out += esc(c)
            }
            return out
        }
        function refresh() {
            const raw = query.trim(), q = raw.toLowerCase()
            const out = []
            if (q.startsWith(">")) {
                const cmd = raw.slice(1).trim()
                if (cmd) out.push({ kind: "cmd", title: cmd, sub: "Run in a terminal", section: "Command" })
            } else {
                const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
                let list = q === "" ? apps.map(e => ({ e: e, s: (usage[e.id] || 0) * 2 + 1 })) : apps.map(e => ({ e: e, s: scoreOf(e, q) })).filter(x => x.s > 0)
                list.sort((a, b) => b.s - a.s || (a.e.name || "").localeCompare(b.e.name || ""))
                for (const x of list.slice(0, q === "" ? 6 : 6)) out.push({ kind: "app", entry: x.e, title: x.e.name, sub: x.e.comment || x.e.genericName || "" })
                if (q !== "") {
                    const c = calc(raw)
                    if (c !== null) out.push({ kind: "calc", title: c, sub: "Copy the result", section: "Calculation", value: c })
                    out.push({ kind: "cmd", title: raw, sub: "Run in a terminal", section: "Command" })
                    out.push({ kind: "web", title: raw, sub: "Search the web", section: "Web search" })
                }
            }
            results = out
            selected = 0
        }
        function launch(r) {
            if (!r) return
            if (r.kind === "app") { bump(r.entry.id); r.entry.execute() }
            else if (r.kind === "calc") Quickshell.execDetached(["wl-copy", r.value])
            else if (r.kind === "cmd") Quickshell.execDetached(["kitty", "sh", "-c", r.title + "; echo; read -p 'Press Enter to close ' _"])
            else if (r.kind === "web") Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(r.title)])
            Launcher.close()
        }

        // ---------------- sectors
        function addrOf(t) { const a = t.lastIpcObject?.address; if (a) return a; return t.address.startsWith("0x") ? t.address : "0x" + t.address }
        function winMatch(t) { const q = query.trim().toLowerCase(); return q === "" || q.startsWith(">") || ((t.title ?? "") + " " + (t.lastIpcObject?.class ?? "")).toLowerCase().includes(q) }
        function windowsOn(ws) { return Hyprland.toplevels.values.filter(t => (t.workspace?.id ?? -1) === ws && (t.lastIpcObject?.mapped ?? true)) }
        function jump(addr) { Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })'); Launcher.close() }
        function goWs(n) { Hyprland.dispatch('hl.dsp.focus({ workspace = ' + n + ' })'); Launcher.close() }
        function moveTo(addr, ws) { Hyprland.dispatch('hl.dsp.window.move({ workspace = ' + ws + ', follow = false, window = "address:' + addr + '" })'); refreshT.restart() }
        Timer { id: refreshT; interval: 180; onTriggered: Hyprland.refreshToplevels() }
        Connections { target: Hyprland; enabled: win.mine; function onRawEvent(e) { if (["openwindow", "closewindow", "movewindowv2", "windowtitlev2"].includes(e.name)) refreshT.restart() } }

        // ---------------- keys
        function keys(event) {
            const k = event.key, ctrl = event.modifiers & Qt.ControlModifier
            const sectorsKeys = ctrl || (Launcher.sectorsFirst && !win.typing)
            if (k === Qt.Key_Escape) Launcher.close()
            else if (sectorsKeys && k === Qt.Key_Right) pick = pick % 10 + 1
            else if (sectorsKeys && k === Qt.Key_Left) pick = (pick + 8) % 10 + 1
            else if (sectorsKeys && (k === Qt.Key_Down || k === Qt.Key_Up)) pick = (pick + 4) % 10 + 1
            else if (sectorsKeys && (k === Qt.Key_Return || k === Qt.Key_Enter)) goWs(pick)
            else if (k === Qt.Key_Down || (k === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) selected = Math.min(results.length - 1, selected + 1)
            else if (k === Qt.Key_Up || k === Qt.Key_Backtab) selected = Math.max(0, selected - 1)
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) launch(results[selected])
            else return false
            return true
        }

        // ---------------- visuals
        Rectangle { anchors.fill: parent; visible: win.showing; color: Theme.glass; opacity: win.mine ? 0.7 : 0; Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
            MouseArea { anchors.fill: parent; onClicked: Launcher.close() } }

        Item {
            id: shell
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: win.mine ? 1 : 0
            scale: win.mine ? 1 : 0.98
            enabled: win.mine
            Behavior on scale { NumberAnimation { duration: win.mine ? Theme.dLong : Theme.dClose; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.dShort } }

            // ---- the query terminal
            Item {   // floats on its servo-skulls; moved on the render thread so the hover stays smooth
                id: floatCard
                width: shell.width; height: shell.height; z: 10
                SequentialAnimation {
                    running: win.mine && Theme.motionEnabled; loops: Animation.Infinite
                    YAnimator { target: floatCard; from: 0; to: 2.5; duration: 2000; easing.type: Easing.InOutSine }
                    YAnimator { target: floatCard; from: 2.5; to: -2.5; duration: 4000; easing.type: Easing.InOutSine }
                    YAnimator { target: floatCard; from: -2.5; to: 0; duration: 2000; easing.type: Easing.InOutSine }
                }
            Item {
                id: card
                z: 10
                width: Math.min(680, win.width - 60)
                height: 76 + (win.typing ? list.height + 12 : 0)
                x: (win.width - width) / 2
                y: 70 + (win.mine ? 0 : 14)
                Behavior on y { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Theme.dShort; easing.type: Easing.OutCubic } }
                MouseArea { anchors.fill: parent }

                // carried on two suspensors instead of hanging from a pipe
                // held by two servo-skulls at its sides
                ServoSkull { id: skL; x: -44; y: 12; active: win.mine }
                ServoSkull { id: skR; x: parent.width - 2; y: 12; mirror: true; active: win.mine }

                Bezel { anchors.fill: parent; radius: 12; inset: 0; boltSize: 6 }
                CrtScreen {
                    id: screen
                    anchors { fill: parent; margins: 12 }
                    radius: 6; padding: 12
                    Item {
                        anchors.fill: parent
                        Row {
                            width: parent.width; height: 28; spacing: 8
                            Glow { anchors.verticalCenter: parent.verticalCenter; font { family: Theme.fontMono; pixelSize: 16; weight: Font.Bold } text: "++>" }
                            TextInput {
                                id: field
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 52
                                color: Theme.glow; selectionColor: Theme.glowFaint; selectedTextColor: Theme.glow
                                cursorVisible: false
                                font { family: Theme.fontMono; pixelSize: 16 }
                                clip: true; focus: true
                                onTextChanged: { win.query = text; win.refresh() }
                                Keys.onPressed: event => { event.accepted = win.keys(event) }
                                Rectangle {
                                    x: field.cursorRectangle.x; y: 3; width: 9; height: parent.height - 6; color: Theme.glow
                                    SequentialAnimation on opacity { loops: Animation.Infinite; running: win.mine && Theme.motionEnabled
                                        NumberAnimation { to: 1; duration: 1 } PauseAnimation { duration: 520 } NumberAnimation { to: 0; duration: 1 } PauseAnimation { duration: 420 } }
                                }
                                Text { anchors.fill: parent; leftPadding: 14; verticalAlignment: Text.AlignVCenter; visible: field.text === ""
                                    elide: Text.ElideRight; rightPadding: 14   // the long form is cut mid-word on a narrow console, so offer a short one
                                    text: field.width > 740 ? "name a machine, sum a number, search the web or > run a rite" : "name a machine, sum a number or > run a rite"; color: Theme.glowFaint; font: field.font }
                            }
                        }
                        ListView {
                            id: list
                            visible: win.typing
                            y: 40
                            width: parent.width
                            height: contentHeight
                            interactive: false
                            model: win.results
                            delegate: Column {
                                id: row
                                required property var modelData
                                required property int index
                                readonly property bool chosen: index === win.selected
                                readonly property bool newSection: modelData.section !== undefined && (index === 0 || win.results[index - 1].section !== modelData.section)
                                width: list.width
                                Rectangle { visible: row.newSection; width: parent.width; height: 1; color: Qt.alpha(Theme.glowDim, 0.3) }
                                Item {
                                    width: parent.width; height: row.modelData.section ? 44 : 46
                                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.glow; opacity: row.chosen ? 0.14 : (rm.containsMouse ? 0.06 : 0) }
                                    Glow { x: 6; anchors.verticalCenter: parent.verticalCenter; visible: row.chosen; font { family: Theme.fontMono; pixelSize: 14; weight: Font.Bold } text: ">" }
                                    Item {
                                        x: 24; anchors.verticalCenter: parent.verticalCenter; width: 28; height: 28
                                        Image { anchors.fill: parent; visible: row.modelData.kind === "app" && status === Image.Ready
                                            source: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.entry.icon, true) : ""; sourceSize: Qt.size(56, 56); fillMode: Image.PreserveAspectFit }
                                        Icon { anchors.centerIn: parent; visible: row.modelData.kind !== "app"; size: 24; color: Theme.glow
                                            name: ({ calc: "calculate", cmd: "terminal", web: "travel_explore" })[row.modelData.kind] ?? "terminal" }
                                    }
                                    Column {
                                        anchors { left: parent.left; leftMargin: 62; right: tagBox.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                        Glow { visible: row.modelData.section !== undefined; halo: 0; color: Theme.glowDim; font { family: Theme.fontMono; pixelSize: 10 } text: (row.modelData.section ?? "").toLowerCase() }
                                        Glow { width: parent.width; elide: Text.ElideRight; halo: row.chosen ? 0.7 : 0; textFormat: Text.StyledText
                                            font { family: row.modelData.kind === "app" ? Theme.fontNum : Theme.fontMono; pixelSize: 15; weight: Font.Medium }
                                            text: row.modelData.kind === "app" ? win.marked(row.modelData.title, win.query.trim()) : row.modelData.title }
                                        Glow { visible: row.modelData.kind === "app" && text !== ""; width: parent.width; elide: Text.ElideRight; halo: 0; color: Theme.glowDim
                                            font { family: Theme.fontUi; pixelSize: 12 } text: row.modelData.sub }
                                    }
                                    Plaque { id: tagBox; visible: row.chosen; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } size: 11
                                        text: ({ app: "Open", calc: "Copy", cmd: "Run", web: "Search" })[row.modelData.kind] }
                                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onEntered: win.selected = row.index; onClicked: win.launch(row.modelData) }
                                }
                            }
                        }
                    }
                }
            }
            }

            // ---- the sector strip
            Item {   // floats on its servo-skulls; moved on the render thread so the hover stays smooth
                id: floatStrip
                width: shell.width; height: shell.height; z: 0
                SequentialAnimation {
                    running: win.mine && Theme.motionEnabled; loops: Animation.Infinite
                    YAnimator { target: floatStrip; from: 0; to: -2; duration: 2200; easing.type: Easing.InOutSine }
                    YAnimator { target: floatStrip; from: -2; to: 2; duration: 4400; easing.type: Easing.InOutSine }
                    YAnimator { target: floatStrip; from: 2; to: 0; duration: 2200; easing.type: Easing.InOutSine }
                }
            Item {
                id: strip
                readonly property int cols: 5
                readonly property real gap: 10
                readonly property real pad: 14
                width: Math.min(win.width - 60, 1820)
                readonly property real cellW: (width - pad * 2 - gap * (cols - 1)) / cols
                readonly property real cellH: cellW * win.modelData.height / win.modelData.width
                readonly property real sc: cellW / win.modelData.width
                height: pad * 2 + cellH * 2 + gap + 30
                x: (win.width - width) / 2
                y: 70 + 76 + 22 + (win.mine ? 0 : 20)
                // while typing the catalogue steps aside and the results have the room
                opacity: win.typing ? 0 : 1
                visible: opacity > 0.01
                enabled: !win.typing
                Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
                Behavior on y { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.OutCubic } }
                MouseArea { anchors.fill: parent }

                property string dragAddr: ""
                property var dragSrc: null
                property int dropWs: 0
                function cellAt(p) {
                    const c = Math.floor((p.x - pad) / (cellW + gap)), r = Math.floor((p.y - pad) / (cellH + gap))
                    return (c >= 0 && c < cols && r >= 0 && r < 2) ? r * cols + c + 1 : 0
                }

                Bezel { anchors.fill: parent; radius: 14; inset: 0; boltSize: 7 }
                Grid {
                    x: strip.pad; y: strip.pad
                    columns: strip.cols; spacing: strip.gap
                    Repeater {
                        model: 10
                        Item {
                            id: cell
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool current: (Hyprland.focusedWorkspace?.id ?? 0) === wsId
                            readonly property var wins: win.windowsOn(wsId)
                            readonly property bool lit: current || win.pick === wsId || strip.dropWs === wsId
                            width: strip.cellW; height: strip.cellH
                            Rectangle {
                                anchors { fill: parent; margins: -3 }
                                radius: 7
                                color: "transparent"
                                border { width: cell.lit ? 2 : 1; color: strip.dropWs === cell.wsId ? Theme.glow : (cell.current ? Theme.brassHi : (win.pick === cell.wsId ? Theme.brass : Theme.metalLo)) }
                            }
                            CrtScreen {
                                anchors.fill: parent; radius: 5; padding: 0
                                Image {
                                    anchors.fill: parent
                                    source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : ""
                                    sourceSize: Qt.size(width, height); fillMode: Image.PreserveAspectCrop
                                    opacity: cell.wins.length > 0 ? 0.28 : 0.06
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: cell.wins.length === 0
                                    text: win.numerals[cell.index]
                                    color: Qt.alpha(Theme.glow, cell.lit ? 0.35 : 0.16)
                                    font { family: Theme.fontNum; pixelSize: cell.height * 0.42; weight: Font.Bold }
                                }
                                Repeater {
                                    model: cell.wins
                                    Item {
                                        id: th
                                        required property var modelData
                                        readonly property var ipc: modelData.lastIpcObject
                                        readonly property string addr: win.addrOf(modelData)
                                        x: ((ipc?.at?.[0] ?? 0) - win.modelData.x) * strip.sc
                                        y: ((ipc?.at?.[1] ?? 0) - win.modelData.y) * strip.sc
                                        width: Math.max(8, (ipc?.size?.[0] ?? 0) * strip.sc)
                                        height: Math.max(8, (ipc?.size?.[1] ?? 0) * strip.sc)
                                        opacity: win.winMatch(modelData) ? (strip.dragAddr === addr ? 0.3 : 1) : 0.15
                                        Item {
                                            anchors.fill: parent
                                            layer.enabled: true
                                            layer.effect: MultiEffect { maskEnabled: true; maskSource: msk }
                                            ScreencopyView {
                                                anchors.fill: parent
                                                // Wait for the first delivered frame instead of capturing
                                                // before the recording context is ready. Reset on close
                                                // so the next opening gets a fresh, non-live snapshot.
                                                captureSource: win.mine ? th.modelData.wayland : null
                                                live: win.mine && !hasContent
                                            }
                                        }
                                        Item { id: msk; anchors.fill: parent; visible: false; layer.enabled: true; Rectangle { anchors.fill: parent; radius: 4 } }
                                        Rectangle { anchors.fill: parent; radius: 4; color: "transparent"; border { width: tm.containsMouse ? 2 : 1; color: tm.containsMouse ? Theme.glow : Qt.alpha(Theme.glowDim, 0.4) } }
                                        Image {
                                            anchors.centerIn: parent
                                            width: Math.min(36, parent.width * 0.4); height: width
                                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(th.ipc?.class ?? "")?.icon ?? (th.ipc?.class ?? "").toLowerCase(), true)
                                            sourceSize: Qt.size(72, 72)
                                        }
                                        MouseArea {
                                            id: tm
                                            anchors.fill: parent; hoverEnabled: true; preventStealing: true
                                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                            cursorShape: moved ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                            property bool moved: false
                                            property real px: 0; property real py: 0
                                            onEntered: win.pick = cell.wsId
                                            onPressed: mouse => { moved = false; px = mouse.x; py = mouse.y }
                                            onPositionChanged: mouse => {
                                                if (!(pressedButtons & Qt.LeftButton)) return
                                                if (!moved && Math.hypot(mouse.x - px, mouse.y - py) > 10) {
                                                    moved = true; strip.dragAddr = th.addr; strip.dragSrc = th.modelData.wayland
                                                    ghost.width = th.width; ghost.height = th.height
                                                }
                                                if (moved) {
                                                    const p = tm.mapToItem(strip, mouse.x, mouse.y)
                                                    ghost.x = p.x - ghost.width / 2; ghost.y = p.y - ghost.height / 2
                                                    strip.dropWs = strip.cellAt(p)
                                                }
                                            }
                                            onReleased: {
                                                if (moved && strip.dropWs > 0 && strip.dropWs !== cell.wsId) win.moveTo(th.addr, strip.dropWs)
                                                strip.dragAddr = ""; strip.dropWs = 0
                                            }
                                            onClicked: mouse => {
                                                if (moved) { moved = false; return }
                                                if (mouse.button === Qt.MiddleButton) { Hyprland.dispatch('hl.dsp.window.close({ window = "address:' + th.addr + '" })'); refreshT.restart() }
                                                else win.jump(th.addr)
                                            }
                                        }
                                    }
                                }
                            }
                            Plaque {   // sector number plate
                                anchors { left: parent.left; top: parent.top; margins: 6 }
                                text: win.numerals[cell.index]; size: 11
                                opacity: cell.lit || cell.wins.length > 0 ? 1 : 0.55
                            }
                            MouseArea {   // empty area: go there
                                anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: win.pick = cell.wsId
                                onClicked: win.goWs(cell.wsId)
                            }
                        }
                    }
                }
                Item {   // dragged window follows the pointer
                    id: ghost
                    visible: strip.dragAddr !== ""
                    z: 100
                    ScreencopyView { anchors.fill: parent; captureSource: strip.dragSrc; live: true; opacity: 0.9 }
                    Rectangle { anchors.fill: parent; radius: 4; color: "transparent"; border { width: 2; color: Theme.glow } }
                }
                ServoSkull { id: skSL; x: -44; y: parent.height / 2 - 22; active: win.mine }
                ServoSkull { id: skSR; x: parent.width - 2; y: parent.height / 2 - 22; mirror: true; active: win.mine }
                // blast doors: two forged halves part from the middle when the console opens
                property real doors: 1
                Connections { target: win; function onMineChanged() { if (win.mine && Theme.motionEnabled) { strip.doors = 1; doorAnim.restart() } } }
                NumberAnimation { id: doorAnim; target: strip; property: "doors"; from: 1; to: 0; duration: Theme.dLong; easing.type: Easing.InOutCubic }
                Item {
                    anchors.fill: parent; clip: true; z: 200
                    visible: strip.doors > 0.01
                    Bezel { x: -strip.width / 2 * (1 - strip.doors); width: strip.width / 2; height: parent.height; radius: 14; inset: 0; boltSize: 7 }
                    Bezel { x: strip.width / 2 + strip.width / 2 * (1 - strip.doors); width: strip.width / 2; height: parent.height; radius: 14; inset: 0; boltSize: 7 }
                    // each door carries hazard stripes on its inner edge
                    Hazard { x: strip.width / 2 - 8 - strip.width / 2 * (1 - strip.doors); width: 8; height: parent.height; stripe: 6 }
                    Hazard { x: strip.width / 2 + strip.width / 2 * (1 - strip.doors); width: 8; height: parent.height; stripe: 6 }
                }
                Glow {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                    halo: 0; color: Theme.glowDim
                    font { family: Theme.fontUi; pixelSize: 12 }
                    text: "Click a window to go to it, drag it to another sector to move it, middle-click closes it.  Ctrl+arrows walk the sectors"
                }
            }
            }
        }
    }
}
