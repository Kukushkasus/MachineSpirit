// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import qs.common
import qs.services

// One vox message. `compact` = inside the log screen; otherwise a toast in its own housing.
Item {
    id: root
    property var notif
    property bool compact: false
    readonly property bool critical: root.notif?.urgency === 2
    implicitHeight: body.implicitHeight + (compact ? 12 : 28)

    Bezel { visible: !root.compact; anchors.fill: parent; radius: 10; inset: 0; boltSize: 4 }
    CrtScreen {
        visible: !root.compact
        anchors { fill: parent; margins: 6 }
        radius: 5; padding: 0
    }
    Rectangle { visible: root.compact; anchors.fill: parent; radius: 4; color: Theme.glow; opacity: 0.05 }
    Row {
        id: body
        x: root.compact ? 8 : 16; y: root.compact ? 6 : 14
        width: parent.width - x * 2
        spacing: 10
        Item {
            width: 30; height: 30
            Image {
                anchors.fill: parent
                source: root.notif?.image ? root.notif.image : (root.notif?.appIcon ? Quickshell.iconPath(root.notif.appIcon, true) : "")
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready && !root.critical
            }
            Icon { anchors.centerIn: parent; name: "campaign"; size: 22; color: Theme.glow; visible: !root.critical && parent.children[0].status !== Image.Ready }
            PuritySeal { visible: root.critical; anchors.centerIn: parent; size: 24; text: "!" }
        }
        Column {
            width: parent.width - 30 - 10 - 24
            spacing: 2
            Glow { width: parent.width; elide: Text.ElideRight; halo: 0; color: Theme.glowDim; font { family: Theme.fontMono; pixelSize: 11 } text: "+++ " + (root.notif?.appName ?? "") + " +++" }
            Glow { width: parent.width; wrapMode: Text.Wrap; halo: 0.4; color: root.critical ? Theme.rustText : Theme.glow; font { pixelSize: 14; weight: Font.DemiBold } text: root.notif?.summary ?? "" }
            Glow { visible: text !== ""; width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight; halo: 0; color: Theme.glowDim; font { family: Theme.fontUi; pixelSize: 13 } text: root.notif?.body ?? "" }
        }
        Item {
            width: 24; height: 24
            Icon { anchors.centerIn: parent; name: "close"; size: 16; color: xm.containsMouse ? Theme.glow : Theme.glowDim }
            MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dismiss(root.notif) }
        }
    }
}
