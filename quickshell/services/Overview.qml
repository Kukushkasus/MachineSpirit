pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell

// Kept for call sites: the overview now lives inside the command console.
Singleton {
    readonly property bool open: Launcher.open
    function toggle() { Launcher.toggleSectors() }
    function close() { Launcher.close() }
}
