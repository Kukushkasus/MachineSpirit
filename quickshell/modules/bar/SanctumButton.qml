// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

// Opens the Sanctum control panel; carries the count of unread notifications.
Item {
    width: 26; height: 28
    GlyphButton { id: btn; anchors.fill: parent; icon: "tune"; tip: "Sanctum (Super+N)"; on: Sanctum.open; onClicked: Sanctum.toggle() }
    PuritySeal { visible: Notifs.unread > 0; x: 14; y: -3; size: 13; text: Notifs.unread > 9 ? "9+" : Notifs.unread }
    // a short ring when something new arrives
    Connections { target: Notifs; function onUnreadChanged() { if (Notifs.unread > 0 && Theme.motionEnabled && !Notifs.dnd) ring.restart() } }
    SequentialAnimation { id: ring
        RotationAnimator { target: btn; from: 0; to: 14; duration: 60 }
        RotationAnimator { target: btn; from: 14; to: -10; duration: 90 }
        RotationAnimator { target: btn; from: -10; to: 0; duration: 120 } }
}
