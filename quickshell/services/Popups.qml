pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell

// Which popup panel is open, and where (screen x of the widget that opened it).
Singleton {
    property string active: ""
    property real anchorX: 0
    property string screenName: ""
    property var trayItem: null        // the tray item whose menu is open ("traymenu")

    property real drop: 0              // extra room above the tray menu (when the drawer is open under the bar)
    function openTrayMenu(item, x, screen, below) { trayItem = item; anchorX = x; screenName = screen; drop = below || 0; active = "traymenu" }

    function toggle(name, x, screen) {
        if (active === name && screenName === screen) { close(); return }
        anchorX = x
        screenName = screen
        active = name
    }
    function close() { active = "" }
    // the tray drawer lives in the popup layer too, so a click elsewhere closes it; it can stay open under its menu
    property bool drawer: false
    property real drawerX: 0
    property string drawerScreen: ""
    function toggleDrawer(x, screen) { if (drawer) { drawer = false; return } drawerX = x; drawerScreen = screen; drawer = true }
    function closeAll() { active = ""; drawer = false }
}
