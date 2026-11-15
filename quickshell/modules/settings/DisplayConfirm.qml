// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.services

// "Keep these display settings?" on every screen while a display change is on trial, like Windows does.
// Screens can move or change size, so one panel per screen is the only way to be sure it's seen.
Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
        visible: Settings.countdown > 0
        WlrLayershell.namespace: "machinespirit-display-confirm"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 440; implicitHeight: 150
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.surfaceContainer
            border { width: 1; color: Theme.glowDim }
            Column {
                anchors { fill: parent; margins: 20 }
                spacing: 8
                Text { text: "Keep these display settings?"; color: Theme.surfaceOn; font { family: Theme.fontNum; pixelSize: 18; weight: Font.DemiBold } renderType: Text.NativeRendering }
                Text { text: "Going back to the previous ones in " + Settings.countdown + " s"; color: Theme.surfaceVariantOn; font { family: Theme.fontNum; pixelSize: 13 } renderType: Text.NativeRendering }
                Item { width: 1; height: 6 }
                Row {
                    anchors.right: parent.right
                    spacing: 10
                    BrassMini { label: "Revert"; onClicked: Settings.run("revert") }
                    BrassMini { label: "Keep"; on: true; onClicked: Settings.run("confirm") }
                }
            }
            Keys.onReturnPressed: Settings.run("confirm")
            Keys.onEscapePressed: Settings.run("revert")
            focus: true
        }
    }
}
