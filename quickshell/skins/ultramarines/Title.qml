// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines title: gold Roman capitals between gilt bars. Each bar is doubled, ends in a lozenge at the
// letters and is stopped by a short upright at the far end, like a rule on a citation.
Item {
    id: root
    required property Item host
    Text {
        id: title
        anchors.centerIn: parent
        text: root.host.text; renderType: Text.NativeRendering
        color: Theme.brassHi
        font { family: Skin.display(root.host.text); pixelSize: Math.round(root.host.pixelSize * 1.06); weight: Font.Bold; letterSpacing: 5; capitalization: Font.AllUppercase }
    }
    Repeater {
        model: 2
        Item {
            required property int index
            readonly property bool l: index === 0
            anchors.verticalCenter: parent.verticalCenter
            x: l ? 0 : title.x + title.width + 12
            width: Math.max(0, title.x - 12); height: 9
            Rectangle { y: 2; x: parent.l ? 4 : 0; width: parent.width - 10; height: 1.5; color: Theme.brass }
            Rectangle { y: 6; x: parent.l ? parent.width * 0.3 : 0; width: parent.width * 0.7 - 10; height: 1; color: Qt.alpha(Theme.brass, 0.6) }
            Rectangle { x: parent.l ? parent.width - 7 : -1; y: 0.5; width: 6; height: 6; rotation: 45; color: Theme.brassHi }
            Rectangle { x: parent.l ? 2 : parent.width - 9; y: -1; width: 1.5; height: 11; color: Theme.brass }
        }
    }
}
