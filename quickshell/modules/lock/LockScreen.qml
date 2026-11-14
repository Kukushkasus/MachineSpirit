// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] A seal is real only when the compositor says it holds.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.common
import qs.services

// lock screen. `phase` is "secure" only after ext-session-lock confirms it (WlSessionLock.secure). A marker file
// keeps the Hyprland instance: if the shell dies locked, the supervisor restarts it and it takes the lock over
// (misc:allow_session_lock_restore)
Scope {
    id: root
    readonly property string runDir: Quickshell.env("MS_RUN")
    readonly property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string marker: runDir !== "" ? runDir + "/locked" : ""
    // True from the request until the screen is unlocked. The shell does not reload its files while it is true.
    property bool held: false
    property string password: ""
    property string error: ""
    property bool checking: false
    property date now: new Date()

    // Read from the compositor's state at the moment of asking: WlSessionLock does not announce every change of `locked`,
    // so a binding on it can go stale.
    function phaseNow() { return sessionLock.secure ? "secure" : (sessionLock.locked ? "locking" : "unlocked") }
    function request() {
        if (sessionLock.locked || marker === "") return
        error = ""; password = ""; checking = false; held = true
        sessionLock.locked = true
    }
    function release() {   // only after PAM accepted the password
        password = ""; checking = false; error = ""
        unmark.running = true; held = false
        sessionLock.locked = false
    }
    function submit() {
        if (checking || password === "") return
        error = ""; checking = true
        if (!pam.start()) { checking = false; password = ""; error = "The authentication service could not be started." }
    }

    // The marker says "the screen was locked by this shell in this Hyprland session".
    Process { id: mark; command: ["sh", "-c", "printf %s \"$1\" > \"$2\"", "sh", root.instance, root.marker] }
    Process { id: unmark; command: ["rm", "-f", root.marker] }
    FileView {
        id: previous; path: root.marker; blockLoading: true; printErrors: false
        Component.onCompleted: {
            if (root.marker === "") return
            const held = previous.text().trim()
            if (held !== "" && held === root.instance) { root.request() }   // the lock outlived the shell: take it over
            else if (held !== "") unmark.running = true                    // left by another session
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false
        onSecureChanged: { if (secure) mark.running = true; else if (!locked) { unmark.running = true; root.held = false } }
        onLockedChanged: if (!locked) { unmark.running = true; root.held = false }
        WlSessionLockSurface {
            color: Theme.surface
            LockSurface { anchors.fill: parent; owner: root }
        }
    }

    PamContext {
        id: pam
        config: "hyprlock"          // the root-owned stack from the hyprlock package
        user: Quickshell.env("USER")
        onPamMessage: { if (responseRequired) respond(root.password) }
        onCompleted: result => {
            root.checking = false; root.password = ""
            if (result === PamResult.Success) root.release()
            else root.error = result === PamResult.MaxTries ? "Too many attempts. Wait a moment and try again." : "The passphrase was not accepted."
        }
        onError: err => { root.checking = false; root.password = ""; root.error = "Authentication failed: " + PamError.toString(err) }
    }

    Timer { interval: 1000; running: sessionLock.secure; repeat: true; onTriggered: root.now = new Date() }

    // Used by ms-session: lock, state, cancel. `cancel` withdraws a request the compositor has not confirmed.
    IpcHandler {
        target: "lock"
        function lock(): void { root.request() }
        function state(): string { return root.phaseNow() }
        function cancel(): string { if (!sessionLock.secure) sessionLock.locked = false; return root.phaseNow() }
    }
}
