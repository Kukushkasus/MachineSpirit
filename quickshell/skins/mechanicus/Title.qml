// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus title: spaced phosphor capitals between double rules that fade outward.
Item {
    id: root
    required property Item host
    Glow {
        id: title
        anchors.centerIn: parent
        text: root.host.text; halo: 0.55
        font { family: Theme.fontNum; pixelSize: root.host.pixelSize; weight: Font.Bold; letterSpacing: 7 }
    }
    Repeater {
        model: 2
        Column {
            required property int index
            anchors.verticalCenter: parent.verticalCenter
            x: index === 0 ? 0 : title.x + title.width + 10
            width: title.x - 10; spacing: 3
            Rectangle { width: parent.width; height: 1; gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: index === 0 ? "transparent" : Qt.alpha(Theme.glow, 0.6) }
                GradientStop { position: 1; color: index === 0 ? Qt.alpha(Theme.glow, 0.6) : "transparent" } } }
            Rectangle { x: index === 0 ? parent.width * 0.35 : 0; width: parent.width * 0.65; height: 1; color: Qt.alpha(Theme.glow, 0.25) }
        }
    }
}
