// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// engraved name plate, drawn by the livery (Skin.frame). `gothic`: ceremonial, bolder and wider spaced
Item {
    id: root
    property string text: ""
    property bool gothic: false
    property int size: 13
    readonly property string style: Skin.frame
    implicitWidth: label.implicitWidth + (gothic ? 32 : 24)
    implicitHeight: label.implicitHeight + (gothic ? 10 : 8)
    Rectangle {
        visible: root.style === "mechanicus"
        anchors.fill: parent
        radius: 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.brassHi }
            GradientStop { position: 0.45; color: Theme.brass }
            GradientStop { position: 1.0; color: Theme.brassLo }
        }
        border { width: 1; color: Qt.darker(Theme.brassLo, 1.3) }
    }
    Poly {
        visible: root.style !== "mechanicus"
        anchors.fill: parent
        points: root.style === "ultramarines" ? Skin.chamfer(width, height, 4) : root.style === "necrons" ? Skin.lean(width, height, 6) : Skin.iron(width, height, 3, 0)
        upper: root.style === "ultramarines" ? Theme.brassHi : root.style === "necrons" ? Qt.darker(Theme.glass, 1.2) : Qt.lighter(Theme.metal, 1.1)
        lower: root.style === "ultramarines" ? Theme.brass : root.style === "necrons" ? Qt.darker(Theme.metal, 1.3) : Qt.darker(Theme.metal, 1.6)
        stroke: root.style === "ultramarines" ? Theme.brassLo : root.style === "necrons" ? Theme.glowDim : Theme.brass
        strokeWidth: root.style === "khorne" ? 1.5 : 1
    }
    readonly property color ink: style === "necrons" ? Theme.glow : style === "khorne" ? Theme.brassHi : Qt.darker(Theme.brassLo, 1.6)
    Text {   // engraving highlight
        visible: root.style === "mechanicus" || root.style === "ultramarines"
        anchors.centerIn: label; anchors.verticalCenterOffset: 1
        text: label.text; font: label.font
        color: Qt.alpha(Theme.brassHi, 0.6)
        renderType: Text.NativeRendering
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.ink
        font { family: root.style === "mechanicus" ? Theme.fontNum : Skin.display(root.text); pixelSize: root.gothic ? Math.round(root.size * 0.85) : root.style === "necrons" ? Math.round(root.size * 0.85) : root.style === "khorne" && Skin.display(root.text) !== Theme.fontNum ? Math.round(root.size * 1.25) : root.size
               weight: root.gothic ? Font.Bold : root.style === "khorne" ? Font.Black : Font.DemiBold; letterSpacing: root.gothic ? 2 : 1; capitalization: root.gothic ? Font.AllUppercase : Font.MixedCase }
        renderType: Text.NativeRendering
    }
}
