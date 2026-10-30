pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell

Singleton {
    property bool open: false
    function toggle() { open = !open; if (open) { Settings.open = false; Sanctum.close(); Popups.close(); Launcher.close(); Walls.close() } }
    function close() { open = false }
}
