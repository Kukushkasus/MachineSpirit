// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

// Vox log: incoming messages on a cogitator screen; critical ones carry a purity seal.
Column {
    width: 420
    spacing: 10
    Row {
        anchors.right: parent.right
        visible: Notifs.all.length > 0
        BrassMini { label: "Purge log"; icon: "delete_sweep"; onClicked: Notifs.clearAll() }
    }
    Tile {
        width: parent.width; height: Math.min(420, Math.max(110, list.contentHeight + 24)); radius: 6; padding: 12
        Column {
            anchors.centerIn: parent
            visible: Notifs.all.length === 0
            spacing: 6
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "notifications_off"; size: 30; color: Theme.glowDim }
            Glow { anchors.horizontalCenter: parent.horizontalCenter; halo: 0.3; text: "The vox is silent" }
        }
        ListView {
            id: list
            anchors.fill: parent
            clip: true
            spacing: 8
            model: Notifs.all
            delegate: NotifCard { width: list.width; notif: modelData; compact: true }
        }
    }
}
