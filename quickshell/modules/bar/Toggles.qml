// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import QtQuick
import qs.common
import qs.services

// Control panel: layout plate, screenshot, wallpapers, volume, microphone, bluetooth.
Row {
    id: root
    spacing: 2
    readonly property var mic: Pipewire.defaultAudioSource?.audio
    readonly property var bt: Bluetooth.defaultAdapter
    property string layout: "en"
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    function setLayout(name) {
        const n = (name || "").toLowerCase()
        layout = n.startsWith("russian") ? "ru" : n.startsWith("english") ? "en" : (name || "en").substring(0, 2).toLowerCase()
    }
    Process {
        command: ["hyprctl", "devices", "-j"]; running: true
        stdout: StdioCollector { onStreamFinished: { try { const j = JSON.parse(text); const kb = j.keyboards.find(k => k.main) || j.keyboards[0]; if (kb) root.setLayout(kb.active_keymap) } catch (e) {} } }
    }
    Connections { target: Hyprland; function onRawEvent(event) { if (event.name === "activelayout") root.setLayout(event.data.split(",").slice(1).join(",")) } }

    BarButton {
        interactive: true; tip: "Switch layout (Alt+Shift)"
        implicitWidth: 30
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
        Glow { anchors.centerIn: parent; halo: 0; color: parent.hovered ? Theme.glow : Theme.glowDim
            font { family: Theme.fontNum; pixelSize: 13; weight: Font.DemiBold } text: root.layout }
    }
    GlyphButton { icon: "screenshot_region"; tip: "Screenshot of an area (Print)"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/ms-screenshot", "region"]) }
    GlyphButton { icon: "imagesmode"; tip: "Wallpapers (Super+W)"; onClicked: Walls.toggle() }
    VolumeScreen {}
    GlyphButton {
        icon: root.mic?.muted ? "mic_off" : "mic"; tip: root.mic?.muted ? "Microphone off" : "Microphone on"
        tint: root.mic?.muted ? Theme.rustText : Theme.glowDim
        onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
    }
    GlyphButton {
        visible: root.bt !== null
        icon: root.bt?.enabled ? "bluetooth" : "bluetooth_disabled"; tip: root.bt?.enabled ? "Bluetooth on" : "Bluetooth off"
        on: root.bt?.enabled ?? false
        onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
    }
}
