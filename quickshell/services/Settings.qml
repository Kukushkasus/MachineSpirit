pragma Singleton
// [ PURITY SEAL ] The user's will survives every reload.
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property bool open: false
    property bool manual: false
    property var data: ({layouts:["us"], primaryOutput:"", monitors:[], bindings:{}, reducedMotion:false, lowPower:false})
    property var monitors: []
    property var bindings: []
    property string error: ""
    property string status: ""
    property string operation: "read"
    property string payload: ""
    property int countdown: 0
    function primary() { return Quickshell.screens.find(s => s.name === data.primaryOutput) || Quickshell.screens[0] || null }
    function toggle(help) {
        if (open && manual === help) { open = false; return }
        Popups.close(); Launcher.close(); Walls.close(); Power.close(); Sanctum.close();
        manual = help; open = true; run("read"); probe.running = true; keys.running = true
    }
    function run(op, value) {
        if (worker.running) return
        error = ""; operation = op; payload = value ? JSON.stringify(value) + "\n" : ""; worker.running = true
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/machinespirit/settings.json"
        watchChanges: true
        onFileChanged: refresh.restart()
    }
    Timer { id: refresh; interval: 250; onTriggered: { if (worker.running) restart(); else root.run("read") } }
    Process {
        id: worker; running: true
        command: ["ms-settings", root.operation]
        stdinEnabled: true
        onStarted: { if (root.payload) write(root.payload); stdinEnabled = false }
        onExited: { stdinEnabled = true }
        stdout: StdioCollector { onStreamFinished: {
            try {
                const r = JSON.parse(text)
                if (r.error) { root.error = r.error; return }
                if (r.data) root.data = r.data
                if (root.operation === "write") { root.status = "Settings saved"; keys.running = true }
                if (r.preview) root.countdown = 15
                if (root.operation === "confirm" || root.operation === "revert") root.countdown = 0
            } catch(e) { root.error = e.message }
        } }
    }
    Process { id: probe; command: ["ms-settings", "monitors"]; stdout: StdioCollector { onStreamFinished: { try { root.monitors = JSON.parse(text).monitors || [] } catch(e) { root.error = e.message } } } }
    Process { id: keys; command: ["ms-settings", "binds"]; stdout: StdioCollector { onStreamFinished: { try { root.bindings = JSON.parse(text).bindings || [] } catch(e) { root.error = e.message } } } }
    Timer { interval: 1000; repeat: true; running: root.countdown > 0; onTriggered: { root.countdown--; if (!root.countdown) root.run("revert") } }
}
