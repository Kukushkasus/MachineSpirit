// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

Item {
    id: root
    property string title: ""
    property string serial: ""
    property real corner: 12
    property bool quiet: false
    property string housing: "screen"
    default property alias contents: body.data
    Bezel { anchors.fill: parent; radius: root.corner; inset: 0; bolts: false }
    CrtScreen { anchors { fill: parent; margins: 5 } radius: Math.max(3, root.corner - 5); padding: 0; ambient: false }
    Rectangle { x: 16; y: 17; width: 4; height: 4; radius: 2; color: Theme.glow }
    Text { x: 27; y: 11; text: root.title.toUpperCase(); color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11; letterSpacing: 1.6 } }
    Text { anchors { right: parent.right; rightMargin: 17; top: parent.top; topMargin: 11 } text: root.serial; color: Theme.glowFaint; font { family: Theme.fontNum; pixelSize: 10 } }
    Rectangle { x: 16; y: 32; width: parent.width - 32; height: 1; color: Qt.alpha(Theme.glow, 0.16) }
    Item { id: body; anchors { fill: parent; leftMargin: 18; rightMargin: 18; topMargin: 42; bottomMargin: 15 } }
    // Receiver vents and the memorandum feed distinguish the physical instruments.
    Repeater {
        model: root.housing === "receiver" ? 12 : 0
        Rectangle { required property int index; x: 8; y: 48 + index * 11; width: 3; height: 6; radius: 1; color: Theme.metalLo }
    }
    Repeater {
        model: root.housing === "tape" ? 2 : 0
        Rectangle { required property int index; x: 5; y: index === 0 ? 34 : root.height - 12; width: root.width - 10; height: 5; radius: 2
            color: Theme.metalLo
            Rectangle { x: 9; y: 1; width: parent.width - 18; height: 1; color: Theme.metalHi }
        }
    }
    // One subtle scan every minute or two. Never over note input.
    Rectangle {
        id: scan; x: 7; y: -20; width: parent.width - 14; height: 16
        visible: sweep.running; color: Qt.alpha(Theme.glow, 0.025)
    }
    NumberAnimation { id: sweep; target: scan; property: "y"; from: 35; to: root.height - 22; duration: 650 }
    Timer { interval: 60000 + Math.random() * 60000; repeat: true; running: root.visible && !root.quiet && !Theme.lowPower && !DesktopWidgets.editing
        onTriggered: { sweep.restart(); interval = 60000 + Math.random() * 60000 } }
}
