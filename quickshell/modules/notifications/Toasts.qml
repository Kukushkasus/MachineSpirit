// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.common
import qs.services

// Notification pop-ups, top right under the bar.
PanelWindow {
    visible: Notifs.toasts.length > 0
    WlrLayershell.namespace: "machinespirit-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 58; right: 12 }
    implicitWidth: 380
    implicitHeight: stack.implicitHeight
    color: "transparent"

    Column {
        id: stack
        width: parent.width
        spacing: 10
        Repeater {
            model: Notifs.toasts
            NotifCard {
                id: toast
                required property var modelData
                notif: modelData
                width: stack.width
                opacity: 0
                x: 40
                Component.onCompleted: { opacity = 1; x = 0; puff.puff() }
                Sparks { id: puff; x: toast.width - 8; y: 10; spread: 14; z: 5 }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            }
        }
    }
}
