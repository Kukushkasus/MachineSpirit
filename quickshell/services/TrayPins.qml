pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Tray icons pinned to the bar (the rest live in the drawer). Remembered in ~/.local/state/machinespirit/tray.json.
Singleton {
    id: root
    property var pinned: []
    readonly property string stateFile: Theme.stateDir + "/tray.json"
    FileView { path: root.stateFile; onLoaded: { try { root.pinned = JSON.parse(text()) } catch (e) {} } }
    function isPinned(id) { return pinned.includes(id) }
    function toggle(id) {
        const p = pinned.includes(id) ? pinned.filter(x => x !== id) : pinned.concat([id])
        pinned = p
        Quickshell.execDetached(["sh", "-c", "mkdir -p '" + Theme.stateDir + "' && printf '%s' '" + JSON.stringify(p).replace(/'/g, "") + "' > '" + root.stateFile + "'"])
    }
}
