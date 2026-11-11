// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Session switch drawn on the screen in rust phosphor (the dangerous colour): a power glyph in a thin ring
// that lights up when touched. Opens the Great Valve.
BarButton {
    id: root
    interactive: true
    tip: "Session (Super+Shift+E)"
    implicitWidth: 28
    onClicked: Power.toggle()
    Item {
        anchors.centerIn: parent; width: 22; height: 22
        scale: root.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Face { anchors.fill: parent; round: true; tone: Theme.rustText; danger: true; level: root.hovered ? 0.2 : 0.06; edge: root.hovered ? 1 : 0.7; edgeWidth: 1.4
            hovered: root.hovered; pressed: root.pressed; on: true }
        Icon { anchors.centerIn: parent; name: "power_settings_new"; size: 14; color: Theme.rustText }
    }
}
