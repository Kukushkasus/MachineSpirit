// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services
Instrument {
    title: "Chronometer"; serial: "01 / LOCAL"; corner: 22
    property date now: new Date()
    readonly property string timeText: Qt.formatDateTime(now, DesktopWidgets.state.seconds ? "HH:mm:ss" : "HH:mm")
    Timer { interval: 1000; running: true; repeat: true; onTriggered: now = new Date() }
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: -1 }
        spacing: 5
        Repeater { model: timeText.length
            Item {
                required property int index
                readonly property string digit: timeText[index]
                width: digit === ":" ? 8 : (DesktopWidgets.state.seconds ? 29 : 43); height: 53
                Rectangle { anchors.fill: parent; radius: 15; visible: parent.digit !== ":"; color: Qt.alpha(Theme.glassHi, 0.65); border.color: Qt.alpha(Theme.brassHi, 0.25)
                    Rectangle { x: 6; y: 8; width: 1; height: 23; color: Qt.alpha(Theme.glow, 0.15) }
                }
                Nixie { anchors.centerIn: parent; text: parent.digit; size: DesktopWidgets.state.seconds ? 32 : 42 }
                Rectangle { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } width: parent.width - 12; height: 2; visible: parent.digit !== ":"; color: Theme.brassLo }
            }
        }
    }
    Text { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } text: Qt.formatDateTime(now, "dddd  ·  dd MMM yyyy"); color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 13 } }
}
