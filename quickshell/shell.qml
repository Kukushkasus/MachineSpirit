//@ pragma Env QT_QUICK_DEFAULT_TEXT_RENDER_TYPE=NativeTextRendering
// SPDX-License-Identifier: GPL-3.0-only
// Super-tap approach adapted from end-4/dots-hyprland (end-4 and contributors).
// Credits: THIRD-PARTY.md.
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.settings
import qs.modules.bar
import qs.modules.popups
import qs.modules.notifications
import qs.modules.desktop
import qs.modules.wallpaper
import qs.modules.launcher
import qs.modules.power
import qs.modules.wallpapers
import qs.modules.sanctum
import qs.services
import QtQuick

ShellRoot {
    id: root
    readonly property bool privacyLoaded: Privacy.loaded
    SettingsWindow {}
    Startup {}
    IpcHandler { target: "settings"; function toggle(): void { Settings.toggle(false) } function setup(): void { Privacy.restartSetup() } }
    IpcHandler { target: "manual"; function toggle(): void { Settings.toggle(true) } }
    Wallpaper {}
    Desktop {}
    Bar {}
    PopupLayer {}
    Toasts {}
    // the big windows exist only while used, and a minute after, then free their memory
    component Lazy: LazyLoader {
        id: lz
        property bool want: false
        active: want || keep.running
        onWantChanged: if (!want) keep.restart()
        property Timer keep: Timer { interval: 60000 }
    }
    ConsoleWindow {}   // the most used one stays loaded so Super opens it at once
    Lazy { want: Power.open; PowerWindow {} }
    Lazy { want: Walls.open; WallsWindow {} }
    Lazy { want: Sanctum.open; SanctumWindow {} }

    // Tapping Super alone opens the console; any Super+key combo interrupts the tap (see hypr/binds.lua).
    property bool superTapArmed: false
    property real superDownAt: 0
    GlobalShortcut {
        appid: "machinespirit"; name: "superDown"
        onPressed: { root.superTapArmed = true; root.superDownAt = Date.now() }
    }
    GlobalShortcut {
        appid: "machinespirit"; name: "superTap"
        onReleased: {
            if (root.superTapArmed && Date.now() - root.superDownAt < 600) Launcher.toggle()
            root.superTapArmed = false
        }
    }
    GlobalShortcut { appid: "machinespirit"; name: "superInterrupt"; onPressed: root.superTapArmed = false }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Launcher.toggle() }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { Overview.toggle() }
    }

    IpcHandler {
        target: "walls"
        function toggle(): void { Walls.toggle() }
    }

    IpcHandler {
        target: "sanctum"
        function toggle(): void { Sanctum.toggle() }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Power.toggle() }
    }
}
