// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services
import qs.modules.bar
import Quickshell.Services.SystemTray

// One overlay hosting the open panel. A pipe drops from the bar into a forged housing; the
// housing carries a brass plate with the panel's name. Click outside or Esc closes it.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property bool mine: Popups.active !== "" && Popups.screenName === modelData.name
        property string shown: ""
        readonly property var titles: ({ calendar: Theme.lex("clock", "Chronometer"), resources: Theme.lex("resources", "Cogitator"), network: Theme.kit === "mechanicus" ? "Vox-caster" : "Network", weather: Theme.lex("weather", "Augury"), notifs: Theme.lex("logTitle", "Vox Log") })   // panels without a title get no plate
        Connections {
            target: Popups
            function onActiveChanged() {
                if (Popups.active !== "") win.shown = Popups.active
                if (Popups.active === "notifs") Notifs.markRead()
                Sys.wantProcs = Popups.active === "resources"
            }
        }

        readonly property bool drawerHere: Popups.drawer && Popups.drawerScreen === modelData.name
        visible: mine || card.open > 0.01 || drawerHere || drawerBox.opacity > 0.01
        WlrLayershell.namespace: "machinespirit-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: mine || drawerHere ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea { anchors.fill: parent; onClicked: Popups.closeAll() }
        Item { focus: true; Keys.onEscapePressed: Popups.closeAll() }

        // ---- the tray drawer: a small screen hanging on two short leads under the chevron
        Item {
            id: drawerBox
            readonly property var items: SystemTray.items.values.filter(i => !TrayPins.pinned.includes(i.id))
            width: Math.max(60, dgrid.implicitWidth + 28); height: dgrid.implicitHeight + 28
            x: Math.max(8, Math.min(win.width - width - 8, Popups.drawerX - width / 2))
            y: win.rodTop + 10
            opacity: win.drawerHere ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
            transform: Translate { y: win.drawerHere ? 0 : -8; Behavior on y { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.OutCubic } } }
            Rectangle { x: Popups.drawerX - drawerBox.x - 5; y: -10; width: 2; height: 12; color: Qt.darker(Theme.rust, 1.2) }
            Rectangle { x: Popups.drawerX - drawerBox.x + 3; y: -10; width: 2; height: 12; color: Theme.brassLo
                Rectangle { y: 3; width: 2; height: 5; color: Theme.brassHi } }
            MouseArea { anchors.fill: parent }
            Bezel { anchors.fill: parent; radius: 9; inset: 0; boltSize: 3.5 }
            CrtScreen { anchors { fill: parent; margins: 5 } radius: 6; padding: 0; ambient: false }
            Grid {
                id: dgrid
                anchors.centerIn: parent
                columns: Math.min(6, Math.max(1, drawerBox.items.length))
                spacing: 2
                Repeater { model: drawerBox.items; TrayIcon { required property var modelData; item: modelData; inDrawer: true; menuDrop: drawerBox.height + 12 } }
            }
        }

        readonly property real pipeX: Math.max(card.x + 40, Math.min(card.x + card.width - 40, Popups.anchorX))

        // two thin cables drop out of the bar, then the panel unfolds from where they hold it; one of them is
        // stripped bare in the middle and arcs when the panel connects. Closing is the same motion backwards.
        readonly property real rodTop: 38
        Item {
            id: leads
            visible: card.open > 0
            x: win.pipeX - 10; y: win.rodTop; width: 20
            height: Math.max(0, (card.y - win.rodTop + 3) * Math.min(1, card.open * 2))
            clip: true
            readonly property real full: card.y - win.rodTop + 3
            // other liveries: two gilt rods with a brace (ultramarines), a beam of light (necrons), a short chain (khorne)
            Item {
                visible: Skin.bar === "ultramarines"
                width: 20; height: leads.full
                Repeater { model: 2; Rectangle { required property int index; x: index ? 13 : 5; width: 2.5; height: parent.height
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } } }
                Rectangle { x: 5; y: parent.height * 0.45; width: 10.5; height: 2; color: Theme.brass }
            }
            Item {
                visible: Skin.bar === "necrons"
                width: 20; height: leads.full
                Rectangle { x: 7.5; width: 5; height: parent.height; color: Qt.alpha(Theme.glow, 0.18) }
                Rectangle { x: 9.5; width: 1; height: parent.height; color: Theme.glow }
            }
            Shape {
                visible: Skin.bar === "khorne"
                width: 20; height: leads.full
                preferredRendererType: Shape.CurveRenderer
                ShapePath { fillColor: "transparent"; strokeColor: Theme.metalHi; strokeWidth: 3.2; strokeStyle: ShapePath.DashLine; dashPattern: [2.0, 3.25]; dashOffset: 3.08
                    startX: 10; startY: 0; PathLine { x: 10; y: leads.full } }
                ShapePath { fillColor: "transparent"; strokeColor: Theme.metalEdge; strokeWidth: 7; strokeStyle: ShapePath.DashLine; dashPattern: [0.5, 1.92]; capStyle: ShapePath.RoundCap
                    startX: 10; startY: 0; PathLine { x: 10; y: leads.full } }
            }
            Shape {
                visible: Skin.bar === "mechanicus"
                width: 20; height: leads.full
                preferredRendererType: Shape.CurveRenderer
                ShapePath {   // insulated lead, sagging a little to the left
                    fillColor: "transparent"; strokeColor: Qt.darker(Theme.metalLo, 1.6); strokeWidth: 3
                    startX: 7; startY: 0
                    PathCubic { x: 7; y: leads.full; control1X: 3; control1Y: leads.full * 0.35; control2X: 3; control2Y: leads.full * 0.65 }
                }
                ShapePath {
                    fillColor: "transparent"; strokeColor: Qt.darker(Theme.rust, 1.2); strokeWidth: 1.8
                    startX: 7; startY: 0
                    PathCubic { x: 7; y: leads.full; control1X: 3; control1Y: leads.full * 0.35; control2X: 3; control2Y: leads.full * 0.65 }
                }
                ShapePath {   // the other lead, sagging right, bare copper in the middle
                    fillColor: "transparent"; strokeColor: Qt.darker(Theme.metalLo, 1.6); strokeWidth: 3
                    startX: 13; startY: 0
                    PathCubic { x: 13; y: leads.full; control1X: 17; control1Y: leads.full * 0.35; control2X: 17; control2Y: leads.full * 0.65 }
                }
                ShapePath {
                    fillColor: "transparent"; strokeColor: Theme.brassLo; strokeWidth: 1.8
                    startX: 13; startY: 0
                    PathCubic { x: 13; y: leads.full; control1X: 17; control1Y: leads.full * 0.35; control2X: 17; control2Y: leads.full * 0.65 }
                }
                ShapePath {
                    fillColor: "transparent"; strokeColor: Theme.brassHi; strokeWidth: 1
                    startX: 15.8; startY: leads.full * 0.38
                    PathLine { x: 16; y: leads.full * 0.62 }
                }
            }
            Item {   // the arc on the bare copper when the panel connects
                id: arc
                visible: Skin.bar === "mechanicus"
                x: 11; y: leads.full * 0.38; width: 10; height: leads.full * 0.24
                opacity: 0
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 7; height: parent.height; radius: 3.5; color: Qt.alpha(Theme.spark, 0.35) }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height; radius: 1; color: "#eaf7ff" }
                SequentialAnimation {
                    id: arcAnim
                    OpacityAnimator { target: arc; from: 0; to: 1; duration: 30 }
                    OpacityAnimator { target: arc; from: 1; to: 0.2; duration: 50 }
                    OpacityAnimator { target: arc; from: 0.2; to: 1; duration: 30 }
                    OpacityAnimator { target: arc; from: 1; to: 0; duration: 160 }
                }
            }
        }
        Rectangle {   // brass clamp where the leads grip the panel
            x: win.pipeX - 9; y: card.y - 3; width: 18; height: 5; radius: 2
            opacity: Math.min(1, card.open * 2); z: 2
            gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
        }
        Sparks { id: steam; x: win.pipeX; y: card.y; z: 3; spread: 10 }

        Item {
            id: card
            readonly property real pad: win.shown === "traymenu" ? 10 : 18
            width: Math.max(plate.visible ? plate.implicitWidth + 60 : 0, loader.implicitWidth + pad * 2)
            readonly property real plateH: plate.visible ? 30 : 0
            height: loader.implicitHeight + pad * 2 + plateH
            x: Math.max(12, Math.min(win.width - 12 - width, Popups.anchorX - width / 2))
            y: 66 + (win.shown === "traymenu" ? Popups.drop : 0)
            property real open: win.mine ? 1 : 0
            Behavior on open { NumberAnimation { duration: win.mine ? Theme.dLong : Theme.dClose; easing.type: win.mine ? Easing.OutCubic : Easing.InCubic } }
            // unload the panel once it has folded away, so nothing inside keeps animating
            property bool vented: false
            onOpenChanged: {
                if (open === 0 && !win.mine) { win.shown = ""; vented = false }
                if (open > 0.5 && win.mine && !vented) { vented = true; if (Theme.fxOn("discharge") && Math.random() < 0.35) { steam.jet(); arcAnim.restart() } }   // the leads reached the panel; now and then they spark
            }
            readonly property real unfold: Math.max(0, (open - 0.25) / 0.75)
            opacity: Math.min(1, unfold * 1.4)
            transform: Scale { origin.x: win.pipeX - card.x; origin.y: 0; yScale: 0.55 + 0.45 * card.unfold; xScale: 0.9 + 0.1 * card.unfold }

            // a cogitator screen: forged bezel, recessed glass that powers on like a CRT, phosphor heading
            Bezel { anchors.fill: parent; radius: 12; inset: 0; boltSize: 5; role: "window" }
            CrtScreen {
                id: glass
                anchors { fill: parent; margins: 7 }
                radius: 7; padding: 0; bootOnLoad: false; ambient: false
            }
            Connections { target: win; function onMineChanged() { if (win.mine) glass.powerOn() } }
            MouseArea { anchors.fill: parent }   // swallow clicks inside the card
            ScreenTitle {
                id: plate
                visible: text !== ""
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 15 }
                text: win.titles[win.shown] ?? ""
            }
            Loader {
                id: loader
                x: card.pad; y: card.pad + card.plateH
                sourceComponent: win.shown === "calendar" ? cCalendar
                    : win.shown === "weather" ? cWeather
                    : win.shown === "notifs" ? cNotifs
                    : win.shown === "network" ? cNetwork
                    : win.shown === "resources" ? cResources
                    : win.shown === "media" ? cMedia
                    : win.shown === "traymenu" ? cTrayMenu : null
            }
            Flicker { anchors { fill: parent; margins: 7 } radius: 7; active: win.mine; z: 20 }
        }

        Component { id: cCalendar; Calendar {} }
        Component { id: cWeather; WeatherCard {} }
        Component { id: cNotifs; NotifPopup {} }
        Component { id: cNetwork; NetPopup {} }
        Component { id: cResources; ResourcesPopup {} }
        Component { id: cMedia; MediaPopup {} }
        Component { id: cTrayMenu; TrayMenu {} }
    }
}
