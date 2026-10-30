// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Small push button for panels on cogitator screens: a phosphor outline that lights when touched.
// (Named for its brass ancestor; the calls stay the same.)
Item {
    id: root
    property string icon: ""
    property string label: ""
    property bool on: false
    signal clicked()
    implicitWidth: label !== "" ? txt.implicitWidth + (icon !== "" ? 34 : 22) : 26
    implicitHeight: 26
    Rectangle {
        anchors.fill: parent; radius: 6
        scale: ma.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        color: root.on ? Qt.alpha(Theme.glow, 0.2) : (ma.containsMouse ? Qt.alpha(Theme.glow, 0.14) : Qt.alpha(Theme.glow, 0.04))
        border { width: 1; color: Qt.alpha(Theme.glow, root.on || ma.containsMouse ? 0.55 : 0.22) }
    }
    Row {
        anchors.centerIn: parent; spacing: 5
        Icon { visible: root.icon !== ""; anchors.verticalCenter: parent.verticalCenter; name: root.icon; size: 15; color: Theme.glow }
        Text { id: txt; visible: root.label !== ""; anchors.verticalCenter: parent.verticalCenter; text: root.label; color: Theme.glow
            font { family: Theme.fontNum; pixelSize: 12; weight: Font.DemiBold } renderType: Text.NativeRendering }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
