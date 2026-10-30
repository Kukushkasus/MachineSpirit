// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Heading of a cogitator screen: spaced phosphor capitals between two short rules.
Row {
    id: root
    property string text: ""
    property int size: 13
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
