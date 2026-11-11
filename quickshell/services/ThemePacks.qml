pragma Singleton
// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] Try before you commit. Leave a way back.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Theme manager: the list of packs, a timed preview that touches nothing permanent, apply and revert.
// All of it goes through `ms-theme`; the shell is never reloaded, the theme changes through live properties,
// so it is safe beside the lock screen. While the screen is locked an apply waits for the unlock.
Singleton {
    id: root
    property var packs: []
    property string active: "mechanicus"       // the applied pack
    property string mode: "follow"             // the applied colour mode: follow | guarded | faction
    property string previewId: ""
    property string previewMode: ""
    property int countdown: 0
    property string error: ""
    property string status: ""
    property bool locked: false                // bound from shell.qml to the lock screen
    property var pending: null                 // an apply asked for while locked
    readonly property bool busy: worker.running || lister.running
    readonly property bool previewing: previewId !== ""
    readonly property var modes: [
        {id: "faction", name: "Faction palette", hint: "The pack's own colours. The wallpaper has no say."},
        {id: "guarded", name: "Guarded", hint: "The wallpaper tints the shell, inside the faction's own range."},
        {id: "follow", name: "Follow wallpaper", hint: "Surfaces and light take the wallpaper's colour. Trim, marks and warning colours stay the faction's."}
    ]
    function pack(id) { return packs.find(p => p.id === id) || null }

    function refresh() { if (!lister.running) lister.running = true }
    function preview(id, colourMode) {
        if (worker.running) return
        const p = pack(id)
        if (p && !p.ok) { error = p.error; return }      // a pack the list has not seen yet is judged by ms-theme
        error = ""; status = ""
        run("preview", ["ms-theme", "preview", id, "--mode", colourMode || mode, "--seconds", "" + previewSeconds], {id: id, mode: colourMode || mode})
    }
    function endPreview() {
        countdown = 0; previewId = ""; previewMode = ""
        Theme.endPreview()
        Quickshell.execDetached(["ms-theme", "preview-end"])
    }
    function cancel() { if (previewing) { endPreview(); status = "Preview ended. Nothing was changed." } }
    // keep what is being previewed, or apply a pack outright
    function apply(id, colourMode) {
        const want = {id: id || previewId || active, mode: colourMode || previewMode || mode}
        if (locked) { pending = want; status = "Waiting for the screen to be unlocked"; return }
        if (worker.running) return
        error = ""; status = ""
        run("apply", ["ms-theme", "apply", "--pack", want.id, "--mode", want.mode, "--save"], want)
    }
    function revert() {
        if (locked || worker.running) return
        error = ""; status = ""
        if (previewing) endPreview()
        run("revert", ["ms-theme", "revert"], null)
    }
    onLockedChanged: if (!locked && pending) { const w = pending; pending = null; apply(w.id, w.mode) }

    property int previewSeconds: 30
    property string op: ""
    property var arg: null
    function run(name, command, value) { op = name; arg = value; worker.command = command; worker.running = true }
    Process {
        id: worker
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            const last = (err.text || "").trim().split("\n").pop().replace(/^ms-theme:\s*/, "")
            if (root.op === "preview") {
                let r = {}
                try { r = JSON.parse(out.text) } catch (e) {}
                if (code !== 0 || r.error) { root.error = r.error || last || "Preview failed"; Theme.endPreview(); return }
                root.previewId = root.arg.id; root.previewMode = root.arg.mode
                root.countdown = root.previewSeconds
                Theme.loadPreview()
                root.status = "Previewing. Nothing is saved until you keep it."
            } else {
                if (code !== 0) {
                    // ms-theme rolled its files back; make sure no preview is left showing either
                    root.error = (last || "Theme could not be applied") + ". The previous theme is still in place."
                    if (root.previewing) root.endPreview()
                } else {
                    root.countdown = 0; root.previewId = ""; root.previewMode = ""
                    Theme.endPreview()
                    root.status = root.op === "revert" ? "Previous theme restored" : "Theme applied"
                }
                root.refresh()
            }
        }
    }
    Timer {
        interval: 1000; repeat: true; running: root.countdown > 0
        onTriggered: { root.countdown--; if (root.countdown <= 0 && root.previewing) { root.endPreview(); root.status = "Preview timed out. The previous theme is back." } }
    }
    Process {
        id: lister; command: ["ms-theme", "packs"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const r = JSON.parse(text)
                root.packs = r.packs || []; root.active = r.active || "mechanicus"; root.mode = r.mode || "follow"
                root.previewSeconds = r.previewSeconds || 30
            } catch (e) { root.error = "Could not read the theme packs" }
        } }
    }
    // a theme applied from anywhere (a terminal, another tool) shows up here too
    Connections { target: Theme; function onAppliedPackChanged() { root.refresh() } }
    FileView { path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/machinespirit/theme.conf"; watchChanges: true; onFileChanged: root.refresh(); printErrors: false }
    // A preview left by a shell that died is never shown again: clear it on start.
    Component.onCompleted: { Quickshell.execDetached(["ms-theme", "preview-end"]); refresh() }
}
