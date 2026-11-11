pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root
    readonly property var catalog: [
        {key: "clock", name: "Chronometer", w: 320, h: 132},
        {key: "weather", name: "Augury", w: 320, h: 230},
        {key: "resources", name: "Cogitator", w: 360, h: 220},
        {key: "media", name: "Vox", w: 360, h: 210},
        {key: "notes", name: "Memorandum", w: 300, h: 260}
    ]
    property var state: ({version: 1, widgets: {}, seconds: false, note: {title: "Memorandum", text: ""}})
    property bool editing: false
    property string selected: "clock"
    property bool loaded: false
    property bool blocked: false
    property bool dirty: false
    property string error: ""
    property int revision: 0
    property int savingRevision: 0
    property string payload: ""
    readonly property string path: Theme.stateDir + "/desktop-widgets.json"
    readonly property string status: error !== "" ? "Not saved · " + error : (dirty || writer.running ? "Saving…" : "Saved")
    function settings(key) { return state.widgets[key] || {enabled: false, screen: "", x: 24, y: 70, scale: 1} }
    function screenFor(key) { return Quickshell.screens.find(s => s.name === settings(key).screen) || Quickshell.screens[0] || null }
    function packed(key, screen, scale) {
        const compact = screen.height < 760
        const leftKeys = compact ? ["clock", "weather", "media"] : ["clock", "weather"]
        const left = leftKeys.includes(key)
        let y = 70
        for (const c of catalog) {
            if (c.key === key) return {x: left ? 24 : Math.max(24, screen.width - c.w * scale - 24), y: y, scale: scale}
            if (leftKeys.includes(c.key) === left) y += c.h * scale + 16
        }
    }
    function geometry(key) {
        const cfg = settings(key), screen = screenFor(key)
        if (!screen) return cfg
        // Temporarily reflow on a small display; saved coordinates remain intact.
        const peers = catalog.filter(c => settings(c.key).screen === cfg.screen)
        const savedWidth = cfg.viewportWidth || Math.max(...peers.map(c => settings(c.key).x + c.w * settings(c.key).scale + 24))
        const savedHeight = cfg.viewportHeight || Math.max(...peers.map(c => settings(c.key).y + c.h * settings(c.key).scale + 24))
        if ((screen.width < 1000 || screen.height < 860) && (screen.width < savedWidth || screen.height < savedHeight)) return packed(key, screen, 0.8)
        return cfg
    }
    function change(key, fields) {
        const next = JSON.parse(JSON.stringify(state))
        const screen = screenFor(key)
        next.widgets[key] = Object.assign({}, settings(key), geometry(key), {viewportWidth: screen?.width ?? 1920, viewportHeight: screen?.height ?? 1080}, fields)
        state = next; changed()
    }
    function changed() { dirty = true; revision++; saveTimer.restart() }
    function note(title, text) {
        const next = Object.assign({}, state, {note: {title: title, text: text}})
        state = next; changed()
    }
    function seconds(value) { state = Object.assign({}, state, {seconds: value}); changed() }
    function toggle() { editing = !editing; if (!editing) flush() }
    function defaults() {
        const s = Quickshell.screens[0]
        if (!s) return
        const scale = s.height < 860 || s.width < 1000 ? 0.8 : 1
        const widgets = {}
        catalog.forEach(c => {
            widgets[c.key] = Object.assign({enabled: true, screen: s.name, viewportWidth: s.width, viewportHeight: s.height}, packed(c.key, s, scale))
        })
        state = Object.assign({}, state, {widgets: widgets}); changed()
    }
    function reset() { defaults(); flush() }
    function flush() {
        saveTimer.stop()
        if (!loaded || blocked || !dirty || writer.running) return
        payload = JSON.stringify(state) + "\n"; savingRevision = revision
        writer.running = true
    }
    Timer { id: saveTimer; interval: 500; onTriggered: root.flush() }
    Process {
        id: reader
        command: ["python3", Quickshell.shellPath("scripts/desktop-state.py"), "read", root.path]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    if (r.error) throw new Error(r.error)
                    if (r.data) root.state = r.data
                    root.loaded = true
                    if (r.missing) root.defaults()
                } catch(e) { root.blocked = true; root.error = "State file: " + e.message; root.loaded = true }
            }
        }
    }
    Process {
        id: writer
        command: ["python3", Quickshell.shellPath("scripts/desktop-state.py"), "write", root.path]
        stdinEnabled: true
        onStarted: write(root.payload)
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    if (!r.ok) throw new Error(r.error || "Write failed")
                    root.error = ""; root.dirty = root.revision !== root.savingRevision
                    if (root.dirty) saveTimer.restart()
                } catch(e) { root.error = e.message }
            }
        }
    }
    IpcHandler { target: "desktop"; function toggle(): void { root.toggle() } function status(): string { return JSON.stringify({state: root.state, error: root.error, loaded: root.loaded}) } }
}
