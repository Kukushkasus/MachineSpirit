pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick
import qs.common

// Night light through hyprsunset: warm the screen to `temperature` kelvin, or give it back its own colour.
// The daemon starts on first use; the switch and the chosen warmth survive a restart of the shell.
Singleton {
    id: root
    readonly property int minK: 2500
    readonly property int maxK: 6000
    readonly property int step: 250
    property bool available: false
    property bool active: false
    property int temperature: 4500
    property bool loaded: false
    readonly property string path: Theme.stateDir + "/nightlight.json"

    function toggle() { setActive(!active) }
    function setActive(on) {
        if (!available) return
        active = on
        apply()
        save.restart()
    }
    function nudge(dir) {
        const t = Math.max(minK, Math.min(maxK, temperature + dir * step))
        if (t === temperature) return
        temperature = t
        if (active) apply()
        save.restart()
    }
    function apply() {
        if (!available) return
        // hyprctl talks to the daemon over its socket; start it first and give it a moment when it is not up yet
        const cmd = active ? "hyprctl hyprsunset temperature " + temperature : "hyprctl hyprsunset identity"
        Quickshell.execDetached(["sh", "-c", "pidof hyprsunset >/dev/null || { setsid -f hyprsunset >/dev/null 2>&1; sleep 0.6; }; " + cmd + " >/dev/null"])
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset >/dev/null"]
        onExited: code => { root.available = code === 0; if (root.available && root.loaded && root.active) root.apply() }
    }
    FileView {
        path: root.path
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text())
                root.active = !!j.active
                if (j.temperature) root.temperature = Math.max(root.minK, Math.min(root.maxK, j.temperature))
            } catch (e) {}
            root.loaded = true
            if (root.available && root.active) root.apply()
        }
        onLoadFailed: root.loaded = true
    }
    Timer { id: save; interval: 300; onTriggered: { if (writer.running) restart(); else writer.running = true } }
    Process {
        id: writer
        command: ["python3", Quickshell.shellPath("scripts/save-json.py"), root.path]
        stdinEnabled: true
        onStarted: { write(JSON.stringify({ active: root.active, temperature: root.temperature }) + "\n"); stdinEnabled = false }
        onExited: stdinEnabled = true
    }
}
