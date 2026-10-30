// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// A knife switch on the panel: a lamp above, a lever in a slot that throws up (on) or down (off) with a
// snap, an engraved label below. `momentary`: a push lever that springs back (for one-shot actions).
Item {
    id: root
    property bool on: false
    property string label: ""
    property string tip: ""
    property bool momentary: false
    property bool lamp: true
    signal toggled()
    signal more()
    width: 52; height: 92
    readonly property bool up: momentary ? ma.pressed : on

    Lamp { id: lmp; visible: root.lamp; anchors.horizontalCenter: parent.horizontalCenter; y: 0; lit: root.on || (root.momentary && ma.pressed) }
    Item {   // the slot and the lever
        id: slot
        anchors.horizontalCenter: parent.horizontalCenter
        y: 20; width: 22; height: 46
        Rectangle { anchors.fill: parent; radius: 6; color: Qt.darker(Theme.glass, 1.3); border { width: 1; color: Qt.alpha(Theme.glow, 0.25) } }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 6; width: 2; height: parent.height - 12; radius: 1; color: Qt.alpha(Theme.glow, 0.15) }
        Rectangle {   // the lever's knob
            id: knob
            anchors.horizontalCenter: parent.horizontalCenter
            width: 18; height: 16; radius: 4
            y: root.up ? 3 : slot.height - height - 3
            Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutBack; easing.overshoot: 2 } }
            color: root.up ? Theme.glow : Qt.alpha(Theme.glow, ma.containsMouse ? 0.4 : 0.28)
            Behavior on color { ColorAnimation { duration: 120 } }
            Rectangle { anchors.centerIn: parent; width: 10; height: 1.5; color: root.up ? Theme.glass : Qt.alpha(Theme.glow, 0.6) }
            Rectangle { anchors.centerIn: parent; anchors.verticalCenterOffset: 3; width: 10; height: 1.5; color: root.up ? Theme.glass : Qt.alpha(Theme.glow, 0.6) }
        }
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: slot.bottom; topMargin: 6 }
        text: root.label
        color: root.on ? Theme.glow : Theme.glowDim
        font { family: Theme.fontNum; pixelSize: 10; weight: Font.Bold; letterSpacing: 1.5; capitalization: Font.AllUppercase }
        renderType: Text.NativeRendering
    }
    MouseArea {
        id: ma
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.more() : root.toggled()
    }
    Rectangle {   // tooltip
        visible: ma.containsMouse && root.tip !== ""
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 4 }
        width: tt.implicitWidth + 16; height: 22; radius: 5; z: 99
        color: Theme.glass; border { width: 1; color: Qt.alpha(Theme.glow, 0.4) }
        Text { id: tt; anchors.centerIn: parent; text: root.tip; color: Theme.glow; renderType: Text.NativeRendering; font { family: Theme.fontNum; pixelSize: 12 } }
    }
}
