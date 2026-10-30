// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import qs.common

// Date and time in nixie tubes right on the bar's glass. Click opens the chronometer.
BarButton {
    id: root
    popup: "calendar"
    tip: Qt.locale("en_US").toString(clock.date, "dddd d MMMM")
    implicitWidth: row.implicitWidth + 8
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Row {
        id: row
        anchors.centerIn: parent; spacing: 8
        Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim
            font { family: Theme.fontNum; pixelSize: 13; weight: Font.Medium }
            text: Qt.locale("en_US").toString(clock.date, "ddd d/MM") }
        Nixie { anchors.verticalCenter: parent.verticalCenter; size: 17; text: Qt.locale("en_US").toString(clock.date, "HH:mm") }
    }
}
