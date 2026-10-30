// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.common
import qs.services

// System tray. Pinned icons stay on the bar; the chevron opens a drawer with the rest. The drawer and the
// menus are drawn by the popup layer, so a click anywhere else or Esc closes them. Pins: TrayPins.
Row {
    id: root
    spacing: 2
    readonly property var items: SystemTray.items.values
    readonly property bool hasItems: items.length > 0
    readonly property var onBar: items.filter(i => TrayPins.pinned.includes(i.id))
    readonly property var inDrawer: items.filter(i => !TrayPins.pinned.includes(i.id))
    readonly property bool drawerOpen: Popups.drawer && Popups.drawerScreen === (QsWindow.window?.screen?.name ?? "")

    Repeater { model: root.onBar; TrayIcon { required property var modelData; item: modelData } }

    BarButton {
        id: chevron
        visible: root.inDrawer.length > 0
        interactive: true
        tip: root.drawerOpen ? "Hide tray" : root.inDrawer.length + " more in the tray"
        implicitWidth: 26
        onClicked: {
            const p = chevron.mapToItem(null, chevron.width / 2, chevron.height)
            Popups.toggleDrawer(p.x + Theme.barMargin, QsWindow.window?.screen?.name ?? "")
        }
        Icon {
            anchors.centerIn: parent; name: "expand_more"; size: 20; color: Theme.glowDim
            rotation: root.drawerOpen ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.OutBack } }
        }
        Rectangle {   // count lamp
            visible: !root.drawerOpen
            x: 17; y: 2; width: 6; height: 6; radius: 3; color: Theme.glow
        }
    }
}
