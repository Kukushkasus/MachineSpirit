// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import qs.common
import qs.services

Instrument {
    id: root
    title: Theme.lex("clock", "Chronometer"); serial: "01 / LOCAL"; corner: 22
    SystemClock { id: clock; precision: DesktopWidgets.state.seconds ? SystemClock.Seconds : SystemClock.Minutes }
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: -3 }
        height: 58; spacing: 9
        Glow {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font { family: Theme.fontMono; pixelSize: 43; weight: Font.Medium; letterSpacing: -1.5 }
            halo: 0.35
        }
        Column {
            visible: DesktopWidgets.state.seconds
            anchors.verticalCenter: parent.verticalCenter; spacing: 0
            Glow {
                id: seconds
                text: Qt.formatDateTime(clock.date, "ss")
                font { family: Theme.fontMono; pixelSize: 23; weight: Font.Medium }
                color: Theme.glowDim; halo: 0.15
                onTextChanged: tick.restart()
                NumberAnimation { id: tick; target: seconds; property: "opacity"; from: 0.65; to: 1; duration: Theme.dShort }
            }
            Text { text: "SEC"; color: Theme.glowFaint; font { family: Theme.fontMono; pixelSize: 9; letterSpacing: 1.5 } }
        }
    }
    Text {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        text: Qt.formatDateTime(clock.date, "ddd  ·  dd MMM yyyy")
        color: Theme.glowDim
        font { family: Theme.fontUi; pixelSize: 12; letterSpacing: 0.3 }
    }
}
