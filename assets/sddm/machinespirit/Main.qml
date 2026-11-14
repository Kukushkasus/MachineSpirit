// SPDX-License-Identifier: GPL-3.0-only
// login screen. Plain QtQuick: it runs before any user session, so no Quickshell, matugen or Hyprland.
// colours come from theme.conf, with the same values as fallback
import QtQuick

Rectangle {
    id: root
    width: 1280; height: 720
    color: pick("background", "#070d0b")

    readonly property real s: Math.max(0.7, Math.min(height / 1080, width / 1920 * 1.2, 2.4))
    readonly property color cPanel: pick("panel", "#0c1512")
    readonly property color cMetal: pick("metal", "#3b4843")
    readonly property color cBrass: pick("brass", "#9a7b3f")
    readonly property color cPhos: pick("phosphor", "#86e6c4")
    readonly property color cText: pick("text", "#cfe9de")
    readonly property color cMuted: pick("muted", "#6f8c82")
    readonly property color cWarn: pick("warn", "#e2a35c")
    readonly property color cError: pick("error", "#e8826a")
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: 0
    property bool failed: false
    property bool busy: false
    property date now: new Date()

    function pick(key, fallback) { var v = config && config[key]; return (v !== undefined && v !== "") ? v : fallback }
    // Sessions are listed alphabetically, so "hyprland-uwsm" comes before "hyprland". MachineSpirit starts its own
    // shell and does not support the UWSM wrapper: when nothing better is remembered, prefer the plain session.
    function initialSession() {
        var i = sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
        var item = sessionView.itemAtIndex(i)
        if (item && item.sfile.indexOf("uwsm") >= 0)
            for (var k = 0; k < sessionView.count; k++) {
                var other = sessionView.itemAtIndex(k)
                if (other && other.sfile === "hyprland.desktop") return k
            }
        return i
    }
    function attempt() {
        if (busy || userView.count === 0 || !userView.currentItem) return
        failed = false; busy = true
        sddm.login(userView.currentItem.uname, field.text, sessionIndex)
    }
    function step(view, delta, assign) {
        if (view.count < 2) return
        assign((view.currentIndex + delta + view.count) % view.count)
    }

    FontLoader { id: plexMedium; source: "fonts/IBMPlexSansCondensed-Medium.ttf" }
    FontLoader { id: plexBold; source: "fonts/IBMPlexSansCondensed-Bold.ttf" }
    readonly property string face: plexMedium.status === FontLoader.Ready ? plexMedium.name : "sans-serif"
    readonly property string faceBold: plexBold.status === FontLoader.Ready ? plexBold.name : "sans-serif"

    // Models are read through hidden lists: this works on every SDDM 0.2x without numeric role ids.
    ListView {
        id: userView; model: userModel; currentIndex: root.userIndex
        width: 10; height: Math.max(10, count * 10); opacity: 0; enabled: false
        delegate: Item { height: 10; width: 10; property string uname: model.name; property string rname: model.realName }
    }
    ListView {
        id: sessionView; model: sessionModel; currentIndex: root.sessionIndex
        width: 10; height: Math.max(10, count * 10); opacity: 0; enabled: false
        delegate: Item { height: 10; width: 10; property string sname: model.name; property string sfile: model.file }
        onCountChanged: Qt.callLater(function () { root.sessionIndex = root.initialSession() })
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // Fixed backdrop: soft glow, brass hairlines in the manner of the wallpapers, scanlines.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient { GradientStop { position: 0; color: "#0c1713" } GradientStop { position: 0.5; color: "transparent" } GradientStop { position: 1; color: "#040807" } }
    }
    Repeater {
        model: [0.07, 0.31, 0.69, 0.93]
        Rectangle { x: root.width * modelData; width: 1; height: root.height; color: root.cBrass; opacity: 0.16 }
    }
    Repeater {
        model: [0.1, 0.9]
        Rectangle { y: root.height * modelData; width: root.width; height: 1; color: root.cBrass; opacity: 0.4 }
    }
    Item { // corner bracket, bottom right
        x: root.width - 120 * root.s; y: root.height - 100 * root.s
        Rectangle { x: 100 * root.s; width: 2; height: 80 * root.s; color: root.cBrass; opacity: 0.7 }
        Rectangle { y: 80 * root.s; width: 102 * root.s; height: 2; color: root.cBrass; opacity: 0.7; x: 0 }
    }
    Image { anchors.fill: parent; source: "scan.png"; fillMode: Image.Tile; opacity: 0.55; smooth: false }

    Item {
        id: stage; anchors.fill: parent; opacity: 0
        Component.onCompleted: { fadeIn.start(); field.forceActiveFocus() }
        NumberAnimation { id: fadeIn; target: stage; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
        NumberAnimation { id: fadeOut; target: stage; property: "opacity"; to: 0; duration: 250; easing.type: Easing.InCubic }

        // Instrument housing in the centre.
        Item {
            id: panel
            width: 520 * root.s; height: column.implicitHeight + 64 * root.s
            anchors.centerIn: parent; anchors.verticalCenterOffset: -30 * root.s
            transform: Translate { id: nudge }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: nudge; property: "x"; to: -14 * root.s; duration: 50 }
                NumberAnimation { target: nudge; property: "x"; to: 12 * root.s; duration: 70 }
                NumberAnimation { target: nudge; property: "x"; to: -7 * root.s; duration: 60 }
                NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
            }
            Rectangle { anchors.fill: parent; radius: 12 * root.s; color: root.cPanel; border.color: root.cMetal; border.width: Math.max(2, 3 * root.s) }
            Rectangle { anchors.fill: parent; anchors.margins: 6 * root.s; radius: 8 * root.s; color: "transparent"; border.color: "#1b2c27"; border.width: 1 }
            Repeater {   // rivets
                model: [[10, 10], [1, 10], [10, 1], [1, 1]]
                Rectangle {
                    width: 6 * root.s; height: width; radius: width / 2; color: "#25322d"; border.color: root.cMetal; border.width: 1
                    x: modelData[0] === 1 ? panel.width - 16 * root.s : 10 * root.s; y: modelData[1] === 1 ? panel.height - 16 * root.s : 10 * root.s
                }
            }
            Column {
                id: column
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 32 * root.s; anchors.topMargin: 30 * root.s
                spacing: 14 * root.s

                Item {
                    width: parent.width; height: caption.implicitHeight
                    Text { id: caption; text: "●  ACCESS"; color: root.cPhos; font.family: root.face; font.pixelSize: 15 * root.s; font.letterSpacing: 2.5 * root.s }
                    Text { anchors.right: parent.right; text: "01 / SANCTUM"; color: root.cMuted; font.family: root.face; font.pixelSize: 13 * root.s; font.letterSpacing: 2 * root.s }
                }
                Rectangle { width: parent.width; height: 1; color: "#1f322c" }

                Item {
                    width: parent.width; height: clock.implicitHeight + date.implicitHeight + 4 * root.s
                    Text {   // soft glow under the digits
                        anchors.horizontalCenter: parent.horizontalCenter; text: clock.text; font: clock.font; color: root.cPhos; opacity: 0.18
                        anchors.horizontalCenterOffset: 0; y: 2 * root.s
                    }
                    Text {
                        id: clock; anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(root.now, "hh:mm"); color: root.cPhos
                        font.family: root.faceBold; font.pixelSize: 104 * root.s; font.letterSpacing: 4 * root.s
                    }
                    Text {
                        id: date; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: clock.bottom; anchors.topMargin: -6 * root.s
                        text: Qt.formatDate(root.now, "dddd  ·  dd MMMM yyyy").toUpperCase(); color: root.cMuted
                        font.family: root.face; font.pixelSize: 14 * root.s; font.letterSpacing: 2.5 * root.s
                    }
                }

                Item { width: 1; height: 6 * root.s }
                Text { text: "OPERATOR"; color: root.cMuted; font.family: root.face; font.pixelSize: 12 * root.s; font.letterSpacing: 3 * root.s }
                Item {
                    width: parent.width; height: 34 * root.s
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80 * root.s; elide: Text.ElideRight
                        text: userView.currentItem ? (userView.currentItem.rname || userView.currentItem.uname) : "—"
                        color: root.cText; font.family: root.faceBold; font.pixelSize: 26 * root.s; font.letterSpacing: 1 * root.s
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 16 * root.s; visible: userView.count > 1
                        Text { text: "‹"; color: root.cPhos; font.pixelSize: 30 * root.s; font.family: root.face
                            MouseArea { anchors.fill: parent; anchors.margins: -10 * root.s; cursorShape: Qt.PointingHandCursor; onClicked: root.step(userView, -1, function (i) { root.userIndex = i }) } }
                        Text { text: "›"; color: root.cPhos; font.pixelSize: 30 * root.s; font.family: root.face
                            MouseArea { anchors.fill: parent; anchors.margins: -10 * root.s; cursorShape: Qt.PointingHandCursor; onClicked: root.step(userView, 1, function (i) { root.userIndex = i }) } }
                    }
                }

                // Terminal-style input: phosphor underline, block caret, dots.
                Item {
                    id: inputBox; width: parent.width; height: 52 * root.s
                    Rectangle { anchors.fill: parent; radius: 6 * root.s; color: "#08110e"; border.width: 1; border.color: root.failed ? root.cError : (field.activeFocus ? root.cPhos : root.cMetal) }
                    Text {
                        visible: field.text.length === 0 && !root.busy; anchors.verticalCenter: parent.verticalCenter; x: 18 * root.s
                        text: "Enter passphrase"; color: root.cMuted; font.family: root.face; font.pixelSize: 18 * root.s; font.letterSpacing: 1 * root.s
                    }
                    TextInput {
                        id: field; anchors.fill: parent; anchors.leftMargin: 18 * root.s; anchors.rightMargin: 18 * root.s
                        verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password; passwordCharacter: "•"
                        color: root.cPhos; font.family: root.face; font.pixelSize: 22 * root.s; selectionColor: root.cPhos; selectedTextColor: root.cPanel
                        enabled: !root.busy; clip: true
                        cursorDelegate: Rectangle { width: 9 * root.s; color: root.cPhos; opacity: 0.8; SequentialAnimation on opacity { loops: Animation.Infinite; running: field.activeFocus; NumberAnimation { to: 0.15; duration: 600 } NumberAnimation { to: 0.8; duration: 600 } } }
                        onAccepted: root.attempt()
                        onTextChanged: root.failed = false
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Up) { root.step(userView, -1, function (i) { root.userIndex = i }); event.accepted = true }
                            else if (event.key === Qt.Key_Down) { root.step(userView, 1, function (i) { root.userIndex = i }); event.accepted = true }
                        }
                    }
                }
                Item {
                    width: parent.width; height: status.implicitHeight
                    Text {
                        id: status; width: parent.width; wrapMode: Text.WordWrap; font.family: root.face; font.pixelSize: 14 * root.s; font.letterSpacing: 1 * root.s
                        text: root.busy ? "AUTHENTICATING…"
                            : root.failed ? "ACCESS DENIED. The passphrase was not accepted."
                            : (keyboard && keyboard.capsLock) ? "CAPS LOCK IS ON"
                            : "AWAITING PASSPHRASE"
                        color: root.failed ? root.cError : ((keyboard && keyboard.capsLock && !root.busy) ? root.cWarn : root.cMuted)
                    }
                }
                Rectangle {
                    width: parent.width; height: 44 * root.s; radius: 6 * root.s; color: auth.containsMouse ? "#12241e" : "#0e1a16"
                    border.width: 1; border.color: root.cPhos; opacity: root.busy ? 0.5 : 1
                    Text { anchors.centerIn: parent; text: "AUTHENTICATE"; color: root.cPhos; font.family: root.faceBold; font.pixelSize: 16 * root.s; font.letterSpacing: 3 * root.s }
                    MouseArea { id: auth; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.attempt() }
                }
            }
        }

        // Session, layout and power, along the bottom.
        Row {
            anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 34 * root.s; spacing: 14 * root.s
            Rectangle {
                visible: sessionView.count > 0; width: sessionText.implicitWidth + 28 * root.s; height: 34 * root.s; radius: 5 * root.s
                color: "#0a130f"; border.width: 1; border.color: sessionArea.containsMouse ? root.cPhos : root.cMetal
                Text { id: sessionText; anchors.centerIn: parent; color: root.cText; font.family: root.face; font.pixelSize: 14 * root.s; font.letterSpacing: 1.5 * root.s
                    text: "SESSION  " + (sessionView.currentItem ? sessionView.currentItem.sname.toUpperCase() : "") + (sessionView.count > 1 ? "  ›" : "") }
                MouseArea { id: sessionArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.step(sessionView, 1, function (i) { root.sessionIndex = i }) }
            }
            Rectangle {
                visible: keyboard && keyboard.layouts && keyboard.layouts.length > 0
                width: layoutText.implicitWidth + 28 * root.s; height: 34 * root.s; radius: 5 * root.s
                color: "#0a130f"; border.width: 1; border.color: layoutArea.containsMouse ? root.cPhos : root.cMetal
                Text { id: layoutText; anchors.centerIn: parent; color: root.cText; font.family: root.face; font.pixelSize: 14 * root.s; font.letterSpacing: 1.5 * root.s
                    text: (keyboard && keyboard.layouts && keyboard.layouts.length > 0 && keyboard.layouts[keyboard.currentLayout]) ? "LAYOUT  " + keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "" }
                MouseArea { id: layoutArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (keyboard.layouts.length > 1) keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length }
            }
        }
        Row {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 34 * root.s; anchors.rightMargin: 150 * root.s; spacing: 14 * root.s
            Repeater {
                model: [{ label: "REBOOT", ok: sddm.canReboot, act: 0 }, { label: "POWER OFF", ok: sddm.canPowerOff, act: 1 }]
                Rectangle {
                    visible: modelData.ok; width: powerText.implicitWidth + 28 * root.s; height: 34 * root.s; radius: 5 * root.s
                    color: "#0a130f"; border.width: 1; border.color: powerArea.containsMouse ? root.cWarn : root.cMetal
                    Text { id: powerText; anchors.centerIn: parent; text: modelData.label; color: powerArea.containsMouse ? root.cWarn : root.cMuted; font.family: root.face; font.pixelSize: 14 * root.s; font.letterSpacing: 1.5 * root.s }
                    MouseArea { id: powerArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.act === 0 ? sddm.reboot() : sddm.powerOff() }
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 18 * root.s
            text: "M A C H I N E   S P I R I T  /  " + sddm.hostName.toUpperCase(); color: root.cBrass; opacity: 0.55
            font.family: root.face; font.pixelSize: 12 * root.s; font.letterSpacing: 2 * root.s
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() { root.busy = false; field.text = ""; root.failed = true; field.forceActiveFocus(); shake.restart() }
        function onLoginSucceeded() { fadeOut.start() }
    }
}
