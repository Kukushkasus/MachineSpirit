// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron title: wide lit letters on a thin line that runs out to both sides, broken by a glyph near each end
// and closed by a node; a short underline with a node sits beneath the letters.
Item {
    id: root
    required property Item host
    Glow {
        id: title
        anchors.centerIn: parent; anchors.verticalCenterOffset: -1
        text: root.host.text.toUpperCase(); halo: 0.7
        font { family: Skin.display(root.host.text); pixelSize: Math.round(root.host.pixelSize * 0.8); weight: Font.Normal; letterSpacing: 4 }
    }
    Rectangle { anchors { horizontalCenter: title.horizontalCenter; top: title.bottom; topMargin: 3 } width: title.width * 0.4; height: 1; color: Qt.alpha(Theme.glow, 0.6) }
    Rectangle { anchors { horizontalCenter: title.horizontalCenter; top: title.bottom; topMargin: 1 } width: 5; height: 5; rotation: 45; color: Theme.glow }
    Repeater {
        model: 2
        Item {
            required property int index
            readonly property bool l: index === 0
            anchors.verticalCenter: parent.verticalCenter
            x: l ? 0 : title.x + title.width + 12
            width: Math.max(0, title.x - 12); height: 10
            Rectangle { y: 5; x: parent.l ? 18 : 0; width: parent.width - 18; height: 1
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(Theme.glow, parent.parent.l ? 0.15 : 0.8) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.glow, parent.parent.l ? 0.8 : 0.15) } } }
            Strokes { x: parent.l ? 4 : parent.width - 12; y: 1; width: 8; height: 8; unit: 0.8; lineWidth: 1; color: Qt.alpha(Theme.glow, 0.75)
                lines: Skin.glyphs[parent.l ? 2 : 5] }
            Rectangle { x: parent.l ? 0 : parent.width - 3; y: 3.5; width: 3; height: 3; radius: 1.5; color: Theme.glow }
        }
    }
}
