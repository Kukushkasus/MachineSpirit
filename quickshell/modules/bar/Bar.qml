// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import qs.common
import qs.services

// The hanging manifold: three mount plates clamped to the top edge of the screen, housings seated on them. The cog, time and
// instruments hang on the left, the sectors alone in the middle, the receiver and the controls on the right,
// so music never moves the middle. Braided cables sag across the two long spans; the spirit's lightning
// runs along their bare copper.
Variants {
    model: Quickshell.screens

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
        Mount { x: left.x - 10; width: left.width + 20; height: 40 }
        Mount { x: heart.x - 10; width: heart.width + 20; height: 40 }
        Mount { x: right.x - 10; width: right.width + 20; height: 40 }
        Cables { id: spanL; portY: 17; x: win.leftEnd + 10; width: Math.max(0, heart.x - win.leftEnd - 20); height: parent.height }
        Cables { id: spanR; portY: 17; x: heart.x + heart.width + 10; width: Math.max(0, right.x - 10 - x); height: parent.height }

        readonly property real leftEnd: left.x + left.width
        readonly property real centreStart: heart.x
        readonly property real centreEnd: heart.x + heart.width

        // `quickshell ipc -c machinespirit call spirit discharge` sets it off by hand
        IpcHandler { target: "spirit"; function discharge(): void { const s = [spanL, spanR].filter(c => c.hasBare()); for (const c of s) c.strike(false) } }
        // the spirit discharges now and then; between strikes the bare copper crackles faintly
        Timer {
            running: Theme.motionEnabled; repeat: false; interval: 1800
            onTriggered: { const s = [spanL, spanR].filter(c => c.hasBare()); if (s.length) s[Math.floor(Math.random() * s.length)].strike(false); interval = 3500 + Math.random() * 5000; restart() }
        }
        Timer {
            running: Theme.motionEnabled; repeat: false; interval: 1500
            onTriggered: { const s = [spanL, spanR].filter(c => c.hasBare()); if (s.length) s[Math.floor(Math.random() * s.length)].crackle(); interval = 1500 + Math.random() * 3000; restart() }
        }

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
        function vent(item) { const p = item.mapToItem(win.contentItem, item.width / 2, 34); steam.x = p.x; steam.y = p.y; steam.puff() }

        Row {
            id: left
            anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 3 }
            spacing: 14
            Housing { flanges: false; hpad: 5; CogHousing {} }
            Housing { hpad: 6; spacing: 6
                NixieClock {}
                WeatherScreen { visible: Weather.ready && win.squeeze < 3 }
            }
            Housing { hpad: 6; Instruments { id: instruments; showRate: win.squeeze < 4; onPuff: win.vent(instruments) } }
            Housing { visible: win.squeeze < 5; hpad: 8
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
            spacing: 14
            Housing { hpad: 5; visible: Media.available; VoxReceiver { maxWidth: win.squeeze >= 1 ? 170 : 230; compact: win.squeeze >= 2 } }
            Housing { hpad: 5; visible: tray.hasItems; Tray { id: tray } }
            Housing { hpad: 6; Toggles {} SanctumButton {} PowerButton {} }
        }

        // the screens' own life, over the instruments
        Repeater {
            model: [left, heart, right]
            Flicker { required property var modelData; z: 30; x: modelData.x - 3; y: 0; width: modelData.width + 6; height: 34; radius: 5 }
        }

        Sparks { id: steam; z: 50 }
    }
}
