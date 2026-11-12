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
        // the stack closes up smoothly when a message leaves or a new one pushes in above
        move: Transition { NumberAnimation { properties: "y"; duration: Theme.dMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
        Repeater {
            model: Notifs.toasts
            NotifCard {
                id: toast
                required property var modelData
                notif: modelData
                width: stack.width
                // How a message arrives, by faction: slides in on a sprung rail (mechanicus), runs in and stops dead
                // (ultramarines), phases in where it stands (necrons), drops onto the stack and bounces (khorne).
                readonly property string kit: Theme.kit
                property real enter: Theme.motionEnabled ? 0 : 1
                NumberAnimation on enter { running: Theme.motionEnabled; from: 0; to: 1; duration: Theme.dEnter
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring }
                opacity: kit === "necrons" ? Math.min(1, enter * 1.4) * (enter >= 1 ? 1 : 0.75 + 0.25 * Math.cos(enter * 28)) : Math.min(1, enter * 2)
                transform: Translate {
                    x: toast.kit === "necrons" || toast.kit === "khorne" ? 0 : 56 * (1 - toast.enter)
                    y: toast.kit === "khorne" ? -30 * (1 - toast.enter) : 0
                }
                Component.onCompleted: { puff.puff(); arrival.play() }
                Arrival { id: arrival; anchors.fill: parent; radius: 10; z: 6; delay: 90 }
                Sparks { id: puff; x: toast.width - 8; y: 10; spread: 14; z: 5 }
            }
        }
    }
}
