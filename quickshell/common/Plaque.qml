// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Brass name plate with engraved lettering. `gothic` marks a ceremonial plate: bolder, wider spaced.
Rectangle {
    id: root
    property string text: ""
    property bool gothic: false
    property int size: 13
    implicitWidth: label.implicitWidth + (gothic ? 32 : 24)
    implicitHeight: label.implicitHeight + (gothic ? 10 : 8)
    radius: 3
    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.brassHi }
        GradientStop { position: 0.45; color: Theme.brass }
        GradientStop { position: 1.0; color: Theme.brassLo }
    }
    border { width: 1; color: Qt.darker(Theme.brassLo, 1.3) }
    Text {   // engraving highlight
        anchors.centerIn: label; anchors.verticalCenterOffset: 1
        text: label.text; font: label.font
        color: Qt.alpha(Theme.brassHi, 0.6)
        renderType: Text.NativeRendering
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Qt.darker(Theme.brassLo, 1.6)
        font { family: Theme.fontNum; pixelSize: root.gothic ? Math.round(root.size * 0.85) : root.size; weight: root.gothic ? Font.Bold : Font.DemiBold; letterSpacing: root.gothic ? 2 : 1; capitalization: root.gothic ? Font.AllUppercase : Font.MixedCase }
        renderType: Text.NativeRendering
    }
}
