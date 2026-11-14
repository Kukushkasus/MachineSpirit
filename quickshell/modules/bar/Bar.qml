// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import qs.common
import qs.services
import qs.kits

// the bar: three groups on mounts at the top edge. Cog, time and gauges on the left, sectors alone in the
// middle so music never moves them, player and controls on the right
Variants {
    // every screen, or only the one that hosts the panels (Settings > Bar & panels)
    model: Settings.data.barAllScreens === false ? Quickshell.screens.filter(s => s === Settings.primary()) : Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "machinespirit-bar"
        anchors { top: true; left: true; right: true }
        margins { left: Theme.barMargin; right: Theme.barMargin }
        // the window is taller than the bar so sparks can fall; only the bar itself reserves space and takes input
        implicitHeight: 80
        exclusiveZone: 44
        mask: Region { item: inputArea }
        color: "transparent"
        Item { id: inputArea; width: parent.width; height: 40 }

        // couplings inside each row, cables across the two long spans
        // a mount plate behind each group, clamped to the edge
        Mount { part: "left"; x: left.x - 10; width: left.width + 20; height: 40 }
        Mount { part: "heart"; x: heart.x - 10; width: heart.width + 20; height: 40 }
        Mount { part: "right"; x: right.x - 10; width: right.width + 20; height: 40 }
        BarSpan { id: spanL; portY: 17; x: win.leftEnd + 10; width: Math.max(0, heart.x - win.leftEnd - 20); height: parent.height }
        BarSpan { id: spanR; portY: 17; x: heart.x + heart.width + 10; width: Math.max(0, right.x - 10 - x); height: parent.height }

        readonly property real leftEnd: left.x + left.width
        readonly property real centreStart: heart.x
        readonly property real centreEnd: heart.x + heart.width

        // a new livery comes online with its own signal running the spans (cables arc, gold pulses, conduits flow, chains jolt)
        Connections { target: Theme; function onKitChanged() { if (Theme.motionEnabled) switchSignal.restart() } }
        Timer { id: switchSignal; interval: 260; onTriggered: { for (const c of [spanL, spanR]) if (c.hasBare()) c.strike(false) } }
        // `quickshell ipc -c machinespirit call spirit discharge` sets it off by hand
        IpcHandler { target: "spirit"; function discharge(): void { const s = [spanL, spanR].filter(c => c.hasBare()); for (const c of s) c.strike(false) } }
        // the spirit discharges now and then; between strikes the bare copper crackles faintly
        Timer {
            running: Theme.fxOn("discharge"); repeat: false; interval: 1800
            onTriggered: { const s = [spanL, spanR].filter(c => c.hasBare()); if (s.length && Theme.fxClaim(700)) s[Math.floor(Math.random() * s.length)].strike(false); interval = Theme.fxDelay("discharge", 3.5, 8.5); restart() }
        }
        Timer {
            running: Theme.fxOn("discharge"); repeat: false; interval: 1500
            onTriggered: { const s = [spanL, spanR].filter(c => c.hasBare()); if (s.length) s[Math.floor(Math.random() * s.length)].crackle(); interval = Theme.fxDelay("discharge", 1.5, 4.5); restart() }
        }

        // ---- which modules sit on the bar and in what order (Settings > Bar & panels). Cog and controls are fixed.
        // re-seating a housing moves it to the end of its row, so seating them in order gives the order
        readonly property var leftOrder: Settings.data.barLeft ?? ["clock", "instruments", "caption"]
        readonly property var rightOrder: Settings.data.barRight ?? ["media", "tray"]
        function seat() {
            const l = {clock: hClock, instruments: hInstruments, caption: hCaption}, r = {media: hMedia, tray: hTray}
            for (const k of ["clock", "instruments", "caption"].sort((a, b) => (leftOrder.indexOf(a) + 9) % 9 - (leftOrder.indexOf(b) + 9) % 9)) { l[k].parent = null; l[k].parent = left }
            for (const k of ["media", "tray"].sort((a, b) => (rightOrder.indexOf(a) + 9) % 9 - (rightOrder.indexOf(b) + 9) % 9)) { r[k].parent = null; r[k].parent = right }
            hControls.parent = null; hControls.parent = right
        }
        onLeftOrderChanged: seat()
        onRightOrderChanged: seat()
        Component.onCompleted: seat()

        // Narrow screens: drop secondary things one by one until nothing overlaps.
        // 1 caption and player narrower, 2 player text, 3 weather, 4 network rate, 5 caption
        property int squeeze: 0
        function slack() { return Math.min(centreStart - leftEnd, right.x - centreEnd) }
        Timer {
            interval: 250; running: true; repeat: true; triggeredOnStart: true
            property int calm: 0
            onTriggered: {
                const s = win.slack()
                if (s < 10 && win.squeeze < 5) { win.squeeze++; calm = 0 }
                else if (s > 160 && win.squeeze > 0 && ++calm > 8) { win.squeeze--; calm = 0 }
            }
        }

        // steam from the joints when something happens
        function vent(item) { const p = item.mapToItem(win.contentItem, item.width / 2, 34); steam.x = p.x; steam.y = p.y; steam.puff(); if (Theme.kit === "mechanicus") valve.rise(p.x + 8, p.y - 2) }

        Row {
            id: left
            anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 3 }
            spacing: Theme.compact ? 8 : 14
            Housing { flanges: false; hpad: 5; CogHousing {} }
            Housing { id: hClock; visible: win.leftOrder.includes("clock"); hpad: 6; spacing: 6
                NixieClock {}
                WeatherScreen { visible: Weather.ready && win.squeeze < 3 && Settings.data.barWeather !== false }
            }
            Housing { id: hInstruments; visible: win.leftOrder.includes("instruments"); hpad: 6; Instruments { id: instruments; showRate: win.squeeze < 4 && Settings.data.barNetRate !== false; onPuff: win.vent(instruments) } }
            Housing { id: hCaption; visible: win.squeeze < 5 && win.leftOrder.includes("caption"); hpad: 8
                CaptionScreen { anchors.verticalCenter: parent.verticalCenter; maxWidth: win.squeeze >= 1 ? 180 : 280 }
            }
        }

        // ---- the sectors, dead centre: nothing on either side is attached to them, so they never move
        Housing {
            id: heart
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 3 }
            flanges: false; hpad: 5
            WsSelector { anchors.verticalCenter: parent.verticalCenter }
        }

        Row {
            id: right
            anchors { right: parent.right; rightMargin: 10; top: parent.top; topMargin: 3 }
            spacing: Theme.compact ? 8 : 14
            Housing { id: hMedia; hpad: 5; visible: Media.available && win.rightOrder.includes("media"); VoxReceiver { maxWidth: win.squeeze >= 1 ? 170 : 230; compact: win.squeeze >= 2 } }
            Housing { id: hTray; hpad: 5; visible: tray.hasItems && win.rightOrder.includes("tray"); Tray { id: tray } }
            Housing { id: hControls; hpad: 6; Toggles {} SanctumButton {} PowerButton {} }
        }

        // the screens' own life, over the instruments
        Repeater {
            model: [left, heart, right]
            Flicker { required property var modelData; z: 30; x: modelData.x - 3; y: 0; width: modelData.width + 6; height: 34; radius: 5 }
        }

        Sparks { id: steam; z: 50 }
        Wisp { id: valve; z: 50; tint: "#d8d8d0" }
    }
}
