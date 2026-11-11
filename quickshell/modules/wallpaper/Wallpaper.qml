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

        // Two layers: a new wallpaper is decoded into the hidden one and faded in only once it is ready, so a
        // change never shows an empty background. Decoded at screen size, not at the file's full resolution.
        id: win
        readonly property string wanted: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper : "file://" + (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/machinespirit/wallpaper.png"
        property int front: 0
        onWantedChanged: { const back = layers[1 - front]; if (back.source.toString() !== wanted) back.source = wanted; else back.show() }
        readonly property var layers: [l0, l1]
        component Layer: Image {
            id: img
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; cache: false
            sourceSize: Qt.size(win.width, win.height)
            opacity: 0
            Behavior on opacity { enabled: Theme.motionEnabled; NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            function show() {
                const other = win.layers[1 - win.layers.indexOf(img)]
                img.z = 1; other.z = 0; img.opacity = 1; win.front = win.layers.indexOf(img)
                hide.restart()
            }
            Timer { id: hide; interval: 500; onTriggered: { const other = win.layers[1 - win.layers.indexOf(img)]; if (other.source.toString() !== win.wanted) { other.opacity = 0; other.source = "" } } }
            onStatusChanged: if (status === Image.Ready && source.toString() === win.wanted) show()
        }
        Layer { id: l0; source: win.wanted }
        Layer { id: l1 }
    }
}
