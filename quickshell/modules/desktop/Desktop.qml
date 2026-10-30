// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

Scope {
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; enabled: DesktopWidgets.editing; onActivated: DesktopWidgets.toggle() }
    Variants {
        model: DesktopWidgets.catalog
        PanelWindow {
            id: win
            required property var modelData
            readonly property var settings: DesktopWidgets.settings(modelData.key)
            screen: DesktopWidgets.screenFor(modelData.key)
            visible: DesktopWidgets.loaded && settings.enabled
            WlrLayershell.namespace: "machinespirit-desktop-" + modelData.key
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; left: true; bottom: DesktopWidgets.editing; right: DesktopWidgets.editing }
            color: "transparent"
            readonly property var geometry: DesktopWidgets.geometry(modelData.key)
            readonly property real factor: geometry.scale
            implicitWidth: Math.ceil(modelData.w * factor)
            implicitHeight: Math.ceil(modelData.h * factor)
            property bool dragging: false
            property real dragX: 0
            property real dragY: 0
            readonly property real placedX: Math.round(Math.max(8, Math.min((screen?.width ?? 1920) - modelData.w * factor - 8, dragging ? dragX : geometry.x)))
            readonly property real placedY: Math.round(Math.max(60, Math.min((screen?.height ?? 1080) - modelData.h * factor - 8, dragging ? dragY : geometry.y)))
            // During editing, move the item inside a stationary surface. This avoids
            // Wayland configure round trips and moving-surface pointer coordinates.
            // Outside the editor the surface shrinks back to the instrument's size.
            margins.left: DesktopWidgets.editing ? 0 : placedX
            margins.top: DesktopWidgets.editing ? 0 : placedY
            mask: Region { item: instrument }

            Item {
                id: instrument
                x: DesktopWidgets.editing ? win.placedX : 0
                y: DesktopWidgets.editing ? win.placedY : 0
                width: win.modelData.w; height: win.modelData.h
                scale: win.factor; transformOrigin: Item.TopLeft
                Loader {
                    anchors.fill: parent; active: win.visible
                    source: { const names = {clock: "Clock", weather: "Weather", resources: "Resources", media: "Media", notes: "Notes"}; return names[win.modelData.key] + "Instrument.qml" }
                }
                Rectangle { anchors.fill: parent; radius: 12; color: "transparent"; border { width: 1; color: Theme.glow } visible: DesktopWidgets.editing && DesktopWidgets.selected === win.modelData.key }
                MouseArea {
                    anchors { left: parent.left; right: parent.right; top: parent.top } height: 34
                    enabled: DesktopWidgets.editing; cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point start
                    property point origin
                    onPressed: m => {
                        DesktopWidgets.selected = win.modelData.key
                        start = mapToItem(win.contentItem, m.x, m.y)
                        origin = Qt.point(win.placedX, win.placedY)
                        win.dragX = origin.x; win.dragY = origin.y; win.dragging = true
                    }
                    onPositionChanged: m => {
                        if (!pressed || !win.dragging) return
                        const p = mapToItem(win.contentItem, m.x, m.y)
                        win.dragX = origin.x + p.x - start.x
                        win.dragY = origin.y + p.y - start.y
                    }
                    onReleased: {
                        // Track every pixel while held; snap once when the drag finishes.
                        const x = Math.max(8, Math.min(win.screen.width - win.modelData.w * win.factor - 8, Math.round(win.placedX / 8) * 8))
                        const y = Math.max(60, Math.min(win.screen.height - win.modelData.h * win.factor - 8, Math.round(win.placedY / 8) * 8))
                        DesktopWidgets.change(win.modelData.key, {x: x, y: y, screen: win.screen.name})
                        win.dragging = false
                    }
                    onCanceled: win.dragging = false
                }
            }
        }
    }
    DesktopEditor {}
}
