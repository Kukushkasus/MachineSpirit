// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import qs.common
import qs.services

// Clickable area on the bar. `popup` names the panel it opens; hover lights it slightly.
Item {
    id: root
    default property alias content: holder.data
    property string popup: ""
    property bool interactive: popup !== ""
    property string tip: ""
    readonly property bool hovered: ma.containsMouse
    readonly property bool pressed: ma.pressed
    readonly property bool active: popup !== "" && Popups.active === popup
    signal clicked()
    signal rightClicked()
    signal wheel(var event)
    implicitWidth: holder.childrenRect.width
    implicitHeight: 28

    function openPopup(name) {
        const p = root.mapToItem(null, width / 2, height)
        Popups.toggle(name, p.x + Theme.barMargin, QsWindow.window?.screen?.name ?? "")
    }

    Rectangle {   // hover light on the metal
        anchors { fill: parent; margins: -2 }
        radius: 6
        color: Theme.glow
        opacity: root.active ? 0.14 : (ma.containsMouse && root.interactive ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
    }
    Item { id: holder; anchors.fill: parent }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { root.rightClicked(); return }
            if (root.popup !== "") root.openPopup(root.popup)
            root.clicked()
        }
        onWheel: event => root.wheel(event)
    }
    Rectangle {   // tooltip plate
        visible: ma.containsMouse && root.tip !== ""
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 12 }
        width: tipText.implicitWidth + 18; height: 24; radius: 4
        color: Theme.glass
        border { width: 1; color: Theme.brass }
        z: 99
        Text {
            id: tipText; anchors.centerIn: parent; text: root.tip; color: Theme.glow
            font { family: Theme.fontNum; pixelSize: 12; weight: Font.Medium }
            renderType: Text.NativeRendering
        }
    }
}
