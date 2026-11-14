// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// screen heading: phosphor capitals between two rules on Mechanicus, the livery's Title elsewhere
Item {
    id: root
    property string text: ""
    property int size: 13
    readonly property bool plain: Skin.type === "mechanicus"
    implicitWidth: plain ? row.implicitWidth : measure.implicitWidth * 1.35 + size * 9
    implicitHeight: plain ? row.implicitHeight : size + 14
    Text { id: measure; visible: false; text: root.text.toUpperCase(); font { family: Skin.display(root.text); pixelSize: root.size; letterSpacing: 4 } }
    Row {
        id: row
        visible: root.plain
        spacing: 10
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: root.size * 2; height: 1; color: Theme.glowFaint }
        Glow {
            anchors.verticalCenter: parent.verticalCenter
            halo: 0.5; color: Theme.glow
            font { family: Theme.fontNum; pixelSize: root.size; weight: Font.Bold; letterSpacing: root.size / 4; capitalization: Font.AllUppercase }
            text: root.text
        }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: root.size * 2; height: 1; color: Theme.glowFaint }
    }
    Loader {
        anchors.fill: parent
        active: !root.plain
        sourceComponent: Title { text: root.text; pixelSize: root.size }
    }
}
