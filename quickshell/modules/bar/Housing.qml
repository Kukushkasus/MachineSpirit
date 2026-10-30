// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// A group of instruments seated on a mount plate (Mount.qml) at the top edge; no box of its own, brass collars on the sides where couplings or cables enter.
// On start it drops from the rail with a small sway; on hover it dips a hair, like something on a hanger.
Item {
    id: root
    default property alias content: row.data
    property alias spacing: row.spacing
    property int hpad: 8
    property bool flanges: true
    readonly property real portY: 14          // where couplings and cables attach
    implicitWidth: row.implicitWidth + hpad * 2
    implicitHeight: 28

    // drop-in on start, ordered left to right by position
    property real drop: 0
    Component.onCompleted: Qt.callLater(() => { if (!Theme.motionEnabled) return; drop = -40; dropAnim.delay = Math.min(240, Math.max(0, root.mapToItem(null, 0, 0).x) / 8); dropAnim.start() })
    Connections { target: Theme; function onMotionEnabledChanged() { if (!Theme.motionEnabled) { dropAnim.stop(); root.drop = 0 } } }
    SequentialAnimation {
        id: dropAnim
        property int delay: 0
        PauseAnimation { duration: dropAnim.delay }
        NumberAnimation { target: root; property: "drop"; to: 0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.4 }
    }
    HoverHandler { id: hover }
    transform: Translate { y: root.drop + (hover.hovered ? 1.5 : 0); Behavior on y { enabled: root.drop === 0; NumberAnimation { duration: 140; easing.type: Easing.OutQuad } } }

    // a thin engraved divider instead of a box: the mount plate is the only surface
    Rectangle { visible: root.flanges && root.x > 0; x: -7; anchors.verticalCenter: parent.verticalCenter; width: 1; height: 16; color: Qt.alpha(Theme.glowFaint, 0.7) }

    Row {
        id: row
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 0 }
        spacing: 4
    }
}
