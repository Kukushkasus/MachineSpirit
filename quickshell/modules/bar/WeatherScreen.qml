// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

BarButton {
    popup: "weather"
    visible: Weather.ready
    tip: Weather.desc
    implicitWidth: row.implicitWidth + 8
    Row {
        id: row
        anchors.centerIn: parent; spacing: 3
        Icon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon; size: 17; color: Theme.glowDim }
        Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim
            font { family: Theme.fontNum; pixelSize: 12; weight: Font.Medium } text: Math.round(Weather.temp) + "°" }
    }
}
