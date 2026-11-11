pragma Singleton
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property bool open: false
    property bool manual: false
    property var data: ({layouts:["us"], primaryOutput:"", monitors:[], bindings:{}})
    property var defaults: ({})
    property var draft: ({})
    property bool initialized: false
    property bool finishRequested:false
    function finishSetup(){if(busy||countdown>0)return;if(dirty){finishRequested=true;run("write",draft)}else Privacy.completeSetup()}
    readonly property bool dirty: initialized && JSON.stringify(draft) !== JSON.stringify(data)
    readonly property bool unsaved:dirty||BrowserPrivacy.dirty
    readonly property bool busy: worker.running
    property bool closeRequested: false
    property var monitors: []
    property var bindings: []
    property string error: ""
    property string status: ""
    property string operation: "read"
    property string payload: ""
    property int countdown: 0
    // search: the title of the control that was looked for. It lights up and asks to be scrolled into view.
    property string sought: ""
    signal reveal(var item)
    signal showPage(int index)
    function openPage(index) { if (!open) toggle(false); showPage(index) }
    function clone(value) { return JSON.parse(JSON.stringify(value)) }
    function set(key, value) { const d = clone(draft); d[key] = value; draft = d; status = ""; error = "" }
    function patch(values) { draft = Object.assign({}, draft, values); status = ""; error = "" }
    function discard() { BrowserPrivacy.discard(); draft = clone(data); status = ""; error = "" }
    function requestClose() {
        if (unsaved) { closeRequested = true; return }
        open = false
    }
    function primary() { return Quickshell.screens.find(s => s.name === data.primaryOutput) || Quickshell.screens[0] || null }
    function toggle(help) {
        if (open && manual === help) { requestClose(); return }
        Popups.close(); Launcher.close(); Walls.close(); Power.close(); Sanctum.close();
        manual = help; closeRequested = false; open = true; run("read"); refreshDevices()
    }
    function refreshDevices() { if (!probe.running) probe.running = true; if (!keys.running) keys.running = true }
    function run(op, value) {
        if (worker.running) return
        error = ""; operation = op; payload = value ? JSON.stringify(value) + "\n" : ""; worker.running = true
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/machinespirit/settings.json"
        watchChanges: true
        onFileChanged: refresh.restart()
    }
    Timer { id: refresh; interval: 300; onTriggered: { if (worker.running) restart(); else root.run("read") } }
    Process {
        id: worker; running: true
        command: ["ms-settings", root.operation]
        stdinEnabled: true
        onStarted: { if (root.payload) write(root.payload); stdinEnabled = false }
        onExited: (code,status) => { stdinEnabled = true; if(code!==0){root.finishRequested=false;if(!root.error)root.error="Settings operation failed. Your unsaved changes are preserved."} }
        stdout: StdioCollector { onStreamFinished: {
            try {
                const r = JSON.parse(text)
                if (r.error) { root.error = r.error; root.finishRequested=false; return }
                const editedDuringSave = root.operation === "write" && JSON.stringify(root.draft) !== root.payload.trim()
                const keepDraft = root.initialized && ((root.dirty && root.operation === "read") || editedDuringSave)
                if (r.defaults) root.defaults = r.defaults
                if (r.data) {
                    root.data = r.data
                    if (!keepDraft) root.draft = root.clone(r.data)
                    root.initialized = true
                }
                if (root.operation === "write") { root.status = r.preview ? "Confirm your display setup" : "Settings applied"; root.refreshDevices() }
                if(root.operation==="write"&&root.finishRequested){root.finishRequested=false;if(editedDuringSave)root.status="New changes are waiting. Finish setup again to save them.";else if(!r.preview)Privacy.completeSetup();else root.status="Confirm displays before finishing setup"}
                if (r.preview) root.countdown = 15
                if (root.operation === "confirm" || root.operation === "revert") {
                    root.countdown = 0; root.status = root.operation === "confirm" ? "Display setup kept" : "Previous display setup restored"; root.refreshDevices()
                }
            } catch(e) { root.finishRequested=false; root.error = "Could not read settings: " + e.message }
        } }
    }
    Process { id: probe; command: ["ms-settings", "monitors"]; stdout: StdioCollector { onStreamFinished: { try { const r = JSON.parse(text); if (r.error) throw new Error(r.error); root.monitors = r.monitors || [] } catch(e) { root.error = e.message } } } }
    Process { id: keys; command: ["ms-settings", "binds"]; stdout: StdioCollector { onStreamFinished: { try { const r = JSON.parse(text); if (r.error) throw new Error(r.error); root.bindings = r.bindings || [] } catch(e) { root.error = e.message } } } }
    Timer { interval: 1000; repeat: true; running: root.countdown > 0; onTriggered: { root.countdown--; if (!root.countdown) root.run("revert") } }
}
