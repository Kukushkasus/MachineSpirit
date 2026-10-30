// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.common
import qs.services

// One tray icon. Left click activates, middle click is the secondary action, right click (or left on a
// menu-only item) opens our menu. `inDrawer`: the icon sits in the drawer, so its menu hangs below it.
Item {
    id: ti
    required property var item
    property bool inDrawer: false
    property real menuDrop: 0
    width: 26; height: 28
    Rectangle { anchors.centerIn: parent; width: 24; height: 24; radius: 6; color: Theme.glow; opacity: tim.containsMouse ? 0.14 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dShort } } }
    IconImage { anchors.centerIn: parent; implicitSize: 16; source: ti.item.icon; scale: tim.pressed ? 0.88 : 1 }
    function openMenu() {
        const p = ti.inDrawer ? Qt.point(Popups.drawerX, 0) : (() => { const q = ti.mapToItem(null, ti.width / 2, ti.height); return Qt.point(q.x + Theme.barMargin, 0) })()
        Popups.openTrayMenu(ti.item, p.x, QsWindow.window?.screen?.name ?? Popups.drawerScreen, ti.inDrawer ? ti.menuDrop : 0)
    }
    MouseArea {
        id: tim
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && ti.item.onlyMenu)) ti.openMenu()
            else if (mouse.button === Qt.MiddleButton) ti.item.secondaryActivate()
            else { ti.item.activate(); Popups.closeAll() }
        }
        onWheel: event => ti.item.scroll(event.angleDelta.y / 120, false)
    }
    Rectangle {   // tooltip plate
        visible: tim.containsMouse && Popups.active !== "traymenu"
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 12 }
        width: tipT.implicitWidth + 18; height: 24; radius: 5
        color: Theme.glass; border { width: 1; color: Qt.alpha(Theme.glow, 0.4) }
        z: 99
        Text { id: tipT; anchors.centerIn: parent; color: Theme.glow; renderType: Text.NativeRendering
            font { family: Theme.fontNum; pixelSize: 12; weight: Font.Medium }
            text: ti.item.tooltipTitle || ti.item.title || ti.item.id }
    }
}
