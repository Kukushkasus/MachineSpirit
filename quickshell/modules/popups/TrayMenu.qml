// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.common
import qs.services

// A tray item's menu on a cogitator screen: Pin / Unpin on top, then the app's own entries.
// Submenus open in place with a Back entry.
Tile {
    id: root
    readonly property var item: Popups.trayItem
    property var stack: []
    width: 250
    height: col.implicitHeight + 12
    radius: 6; padding: 6
    QsMenuOpener { id: opener; menu: root.item?.menu ?? null }
    function back() { const s = stack.slice(); opener.menu = s.pop(); stack = s }

    component Entry: Item {
        id: en
        property string label: ""
        property string glyph: ""
        property var iconSource: ""
        property bool arrow: false
        property bool dim: false
        signal picked()
        width: col.width; height: 30
        Rectangle { anchors.fill: parent; radius: 3; color: Theme.glow; opacity: em.containsMouse && !en.dim ? 0.14 : 0
            Behavior on opacity { OpacityAnimator { duration: 90 } } }
        Icon { visible: en.glyph !== ""; x: 6; anchors.verticalCenter: parent.verticalCenter; name: en.glyph; size: 16; color: Theme.glowDim }
        IconImage { visible: en.glyph === "" && en.iconSource !== ""; x: 6; anchors.verticalCenter: parent.verticalCenter; implicitSize: 16; source: en.iconSource }
        Glow { x: 30; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 54; elide: Text.ElideRight; halo: 0
            color: en.dim ? Theme.glowFaint : (em.containsMouse ? Theme.glow : Qt.lighter(Theme.glowDim, 1.25))
            font { family: Theme.fontNum; pixelSize: 14 } text: en.label }
        Icon { visible: en.arrow; anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter } name: "chevron_right"; size: 16; color: Theme.glowDim }
        MouseArea { id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: en.dim ? Qt.ArrowCursor : Qt.PointingHandCursor; onClicked: if (!en.dim) en.picked() }
    }

    Column {
        id: col
        width: parent.width
        Entry {
            visible: root.stack.length === 0 && root.item !== null
            glyph: TrayPins.isPinned(root.item?.id) ? "keep_off" : "keep"
            label: TrayPins.isPinned(root.item?.id) ? "Unpin from the bar" : "Pin to the bar"
            onPicked: { TrayPins.toggle(root.item.id); Popups.close() }
        }
        Entry { visible: root.stack.length > 0; glyph: "chevron_left"; label: "Back"; onPicked: root.back() }
        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.glowDim, 0.35) }
        Repeater {
            model: opener.children
            Item {
                id: row
                required property var modelData
                width: col.width
                height: modelData.isSeparator ? 9 : 30
                Rectangle { visible: row.modelData.isSeparator; anchors.centerIn: parent; width: parent.width - 12; height: 1; color: Qt.alpha(Theme.glowDim, 0.35) }
                Entry {
                    visible: !row.modelData.isSeparator
                    label: (row.modelData.checkState === Qt.Checked ? "✓ " : "") + (row.modelData.text ?? "").replace(/_(?!_)/, "")
                    iconSource: row.modelData.icon ?? ""
                    arrow: row.modelData.hasChildren
                    dim: !row.modelData.enabled
                    onPicked: {
                        if (row.modelData.hasChildren) { root.stack = root.stack.concat([opener.menu]); opener.menu = row.modelData }
                        else { row.modelData.triggered(); Popups.closeAll() }
                    }
                }
            }
        }
    }
}
