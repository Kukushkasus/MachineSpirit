pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell

// The command console: launcher on top, the sector strip below. One window, opened by tapping Super.
Singleton {
    property bool open: false
    property bool sectorsFirst: false   // Super+Tab: keyboard goes to the sectors
    property string preset: ""          // text to pre-fill when opened from elsewhere
    function closeOthers() { Settings.open = false; Sanctum.close(); Popups.close(); Power.close(); Walls.close() }
    function openWith(text) { preset = text; sectorsFirst = false; open = true; closeOthers() }
    function toggle() { sectorsFirst = false; open = !open; if (open) closeOthers() }
    function toggleSectors() { sectorsFirst = true; open = !open; if (open) closeOthers() }
    function close() { open = false }
}
