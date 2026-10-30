pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick

// The control panel and the switches only it owns: keep awake and game mode.
Singleton {
    id: root
    property bool open: false
    function toggle() { open = !open; if (open) { Settings.open = false; Launcher.close(); Walls.close(); Power.close(); Popups.close() } }
    function close() { open = false }

    // keep awake: an inhibitor that lives as long as the switch is on. Blocking sleep needs an active seat
    // session (polkit); when that is refused it falls back to blocking idle only, which anyone may.
    property bool keepAwake: false
    Process {
        running: root.keepAwake
        command: ["sh", "-c", "systemd-inhibit --what=idle:sleep --who=MachineSpirit --why='Keep awake' sleep infinity 2>/dev/null"
            + " || exec systemd-inhibit --what=idle --who=MachineSpirit --why='Keep awake' sleep infinity"]
    }

    // game mode: Hyprland without animations, blur, shadows and gaps; off restores the config
    property bool gameMode: false
    onGameModeChanged: {
        // the Lua config takes changes through eval (keyword is for the legacy parser)
        if (gameMode) Quickshell.execDetached(["hyprctl", "eval",
            "hl.config({ animations = { enabled = false }, decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } }, general = { gaps_in = 0, gaps_out = 0 } })"])
        else Quickshell.execDetached(["hyprctl", "reload"])
    }
}
