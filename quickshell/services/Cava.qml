pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick

// Audio spectrum from `cava` (raw ASCII output). Runs only while something wants it.
Singleton {
    id: root
    property var bars: []          // values 0..1
    property int refs: 0           // consumers that need the data
    property bool playing: false   // set by the media service
    readonly property bool wanted: refs > 0 && playing

    function retain() { refs += 1 }
    function release() { refs = Math.max(0, refs - 1) }

    Process {
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]
        running: root.wanted
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(s => s !== "").map(s => Number(s) / 100)
                if (v.length > 0) root.bars = v
            }
        }
        onRunningChanged: if (!running) root.bars = []
    }
}
