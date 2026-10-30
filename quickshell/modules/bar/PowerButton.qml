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
        Rectangle { anchors.fill: parent; radius: 11; color: Qt.alpha(Theme.rustText, root.hovered ? 0.2 : 0.06)
            border { width: 1.4; color: Qt.alpha(Theme.rustText, root.hovered ? 1 : 0.7) }
            Behavior on color { ColorAnimation { duration: Theme.dShort } } }
        Icon { anchors.centerIn: parent; name: "power_settings_new"; size: 14; color: Theme.rustText }
    }
}
