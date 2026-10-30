// [ PURITY SEAL ] Wake quietly, release the controls promptly.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
PanelWindow {
    id: win
    screen: Settings.primary()
    visible: veil.opacity > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "machinespirit-startup"
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    property bool starting: Quickshell.env("MS_STARTUP") === "1"
    Timer { interval: 450; running: win.starting; onTriggered: win.starting = false }
    Rectangle {
        id: veil; anchors.fill: parent; color: Theme.glass
        opacity: win.starting ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Settings.data.reducedMotion ? 0 : 300 } }
        Column {
            anchors.centerIn: parent; spacing: 16
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "✥"; color: Theme.glow; font.pixelSize: 80 }
            Text { text: "M A C H I N E S P I R I T"; color: Theme.glow; font.pixelSize: 30; font.family: Theme.fontUi }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "THE INSTRUMENTS AWAKEN"; color: Theme.glowDim; font.pixelSize: 12 }
        }
    }
}
