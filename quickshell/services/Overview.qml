pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell

// stub for old callers, the overview moved into the command console
Singleton {
    readonly property bool open: Launcher.open
    function toggle() { Launcher.toggleSectors() }
    function close() { Launcher.close() }
}
