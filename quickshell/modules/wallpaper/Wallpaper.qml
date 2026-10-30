// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common

// Draws the wallpaper on the background layer.
// File: $XDG_DATA_HOME/machinespirit/wallpaper.png (default ~/.local/share/...).
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "machinespirit-wallpaper"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.surface

        Image {
            anchors.fill: parent
            source: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : "file://" + (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/machinespirit/wallpaper.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }
}
