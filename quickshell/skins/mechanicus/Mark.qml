// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus key cap: only the engaged key has one, glass under a phosphor rim; a dot marks an occupied sector.
Item {
    id: root
    required property Item host
    Rectangle {
        anchors.fill: parent
        radius: 5
        color: Theme.glass
        border { width: 1; color: Theme.glow }
        opacity: root.host.focused ? 1 : (root.host.hovered ? 0.35 : 0)
        Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
    }
    Rectangle {
        visible: root.host.occupied && !root.host.focused
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
        width: 3; height: 3; radius: 1.5
        color: Theme.glowDim
    }
}
