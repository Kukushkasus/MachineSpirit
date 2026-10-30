// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common
import qs.services
PanelWindow {
    id: win
    visible: DesktopWidgets.editing
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
    WlrLayershell.namespace: "machinespirit-desktop-editor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true
    margins.bottom: 24
    implicitWidth: Math.min(800, (screen?.width ?? 1024) - 32)
    implicitHeight: 186
    color: "transparent"
    Bezel { anchors.fill: parent; inset: 0; radius: 12; bolts: false }
    CrtScreen { anchors { fill: parent; margins: 5 } ambient: false; padding: 0 }
    Item {
        anchors { fill: parent; margins: 18 } focus: true
        Keys.onEscapePressed: { DesktopWidgets.editing = false; DesktopWidgets.flush() }
        Text { text: "DESKTOP INSTRUMENTS"; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 14; letterSpacing: 2 } }
        Text { y: 22; text: "Select an instrument · drag its header to move"; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
        BrassMini { anchors.right: parent.right; label: "Done"; icon: "check"; onClicked: DesktopWidgets.toggle() }
        Row { y: 50; spacing: 8
            Repeater { model: DesktopWidgets.catalog
                BrassMini { required property var modelData; label: modelData.name; on: DesktopWidgets.selected === modelData.key; onClicked: DesktopWidgets.selected = modelData.key }
            }
        }
        Row { y: 88; spacing: 9
            BrassMini { label: DesktopWidgets.settings(DesktopWidgets.selected).enabled ? "Enabled" : "Hidden"; on: DesktopWidgets.settings(DesktopWidgets.selected).enabled; onClicked: DesktopWidgets.change(DesktopWidgets.selected, {enabled: !DesktopWidgets.settings(DesktopWidgets.selected).enabled}) }
            BrassMini { label: "−"; onClicked: DesktopWidgets.change(DesktopWidgets.selected, {scale: Math.max(0.8, Math.round((DesktopWidgets.geometry(DesktopWidgets.selected).scale - 0.1) * 10) / 10)}) }
            Text { width: 35; anchors.verticalCenter: parent.verticalCenter; text: Math.round(DesktopWidgets.geometry(DesktopWidgets.selected).scale * 100) + "%"; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 12 } }
            BrassMini { label: "+"; onClicked: DesktopWidgets.change(DesktopWidgets.selected, {scale: Math.min(1.4, Math.round((DesktopWidgets.geometry(DesktopWidgets.selected).scale + 0.1) * 10) / 10)}) }
            BrassMini {
                label: DesktopWidgets.screenFor(DesktopWidgets.selected)?.name ?? "Display"
                onClicked: {
                    const screens = Quickshell.screens
                    const i = screens.findIndex(s => s.name === DesktopWidgets.screenFor(DesktopWidgets.selected)?.name)
                    if (screens.length) DesktopWidgets.change(DesktopWidgets.selected, {screen: screens[(i + 1) % screens.length].name})
                }
            }
            BrassMini { visible: DesktopWidgets.selected === "clock"; label: "Seconds"; on: DesktopWidgets.state.seconds; onClicked: DesktopWidgets.seconds(!DesktopWidgets.state.seconds) }
        }
        Text { y: 129; width: parent.width - 130; elide: Text.ElideRight; text: DesktopWidgets.status; color: DesktopWidgets.error ? Theme.rustText : Theme.glowFaint; font { family: Theme.fontNum; pixelSize: 11 } }
        BrassMini { anchors { right: parent.right; bottom: parent.bottom } label: "Reset layout"; onClicked: DesktopWidgets.reset() }
    }
}
