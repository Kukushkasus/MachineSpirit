// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs.common
import qs.services

// Bluetooth: adapter power, scanning, and the device list. Click a device to connect, disconnect or pair it.
// scanning stops when the panel closes, so the adapter isn't left discovering in the background
Column {
    id: root
    width: 420
    spacing: 12
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool on: bt?.enabled ?? false
    // connected first, then paired, then the rest; unnamed devices only clutter the list
    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.connected || d.paired || (d.deviceName && d.deviceName !== d.address.replace(/:/g, "-")))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    Component.onDestruction: if (bt && bt.discovering) bt.discovering = false

    function glyph(icon) {
        const i = icon || ""
        return i.includes("headset") ? "headset_mic" : i.includes("audio") || i.includes("headphone") ? "headphones"
            : i.includes("speaker") ? "speaker" : i.includes("mouse") ? "mouse" : i.includes("keyboard") ? "keyboard"
            : i.includes("phone") ? "smartphone" : i.includes("computer") ? "computer" : i.includes("game") ? "sports_esports"
            : "bluetooth"
    }
    function status(d) {
        if (d.pairing) return "pairing..."
        if (d.state === BluetoothDeviceState.Connecting) return "connecting..."
        if (d.state === BluetoothDeviceState.Disconnecting) return "disconnecting..."
        if (d.connected) return d.batteryAvailable ? "connected · " + Math.round(d.battery * 100) + "%" : "connected"
        return d.paired ? "paired" : "new"
    }

    Tile {
        width: parent.width; height: 64; radius: 6; padding: 12
        Item {
            anchors.fill: parent
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Glow { font { pixelSize: 16; weight: Font.DemiBold } text: !root.bt ? "No adapter" : root.bt.name || "Bluetooth" }
                Glow { halo: 0; color: Theme.glowDim; font.pixelSize: 11
                    text: !root.bt ? "bluetoothd isn't running or there is no adapter"
                        : !root.on ? "off" : root.bt.discovering ? "searching for devices..." : root.devices.filter(d => d.connected).length + " connected" }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8
                BrassMini { visible: root.on; label: root.bt?.discovering ? "Stop" : "Search"; onClicked: root.bt.discovering = !root.bt.discovering }
                BrassMini { visible: !!root.bt; label: root.on ? "Turn off" : "Turn on"; onClicked: root.bt.enabled = !root.on }
            }
        }
    }

    Tile {
        visible: root.on
        width: parent.width; height: Math.max(56, list.implicitHeight + 16); radius: 6; padding: 8
        Glow {
            visible: root.devices.length === 0
            anchors.centerIn: parent; halo: 0; color: Theme.glowDim; font.pixelSize: 12
            text: root.bt?.discovering ? "Put your device in pairing mode" : "No devices yet. Press Search"
        }
        Column {
            id: list
            width: parent.width
            Repeater {
                model: root.devices
                Item {
                    id: row
                    required property var modelData
                    readonly property var dev: modelData
                    property bool wantConnect: false
                    width: list.width; height: 40
                    // a new device: pair, trust it so it reconnects by itself next time, then connect
                    Connections {
                        target: row.dev
                        function onPairedChanged() { if (row.dev.paired && row.wantConnect) { row.dev.trusted = true; row.dev.connect(); row.wantConnect = false } }
                    }
                    Rectangle { anchors.fill: parent; radius: 4; color: Theme.glow; opacity: rm.containsMouse ? 0.08 : row.dev.connected ? 0.05 : 0 }
                    Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; name: root.glyph(row.dev.icon); size: 20; color: row.dev.connected ? Theme.glow : Theme.glowDim }
                    Column {
                        x: 40; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40 - (forget.visible ? forget.width + 12 : 8)
                        Glow { width: parent.width; elide: Text.ElideRight; halo: row.dev.connected ? 0.4 : 0; color: row.dev.connected ? Theme.glow : Theme.surfaceOn
                            font { pixelSize: 13; weight: row.dev.connected ? Font.DemiBold : Font.Normal } text: row.dev.name }
                        Glow { halo: 0; color: Theme.glowDim; font { family: Theme.fontMono; pixelSize: 10 } text: root.status(row.dev) }
                    }
                    MouseArea {
                        id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const d = row.dev
                            if (d.pairing) d.cancelPair()
                            else if (d.connected) d.disconnect()
                            else if (d.paired) d.connect()
                            else { row.wantConnect = true; d.pair() }
                        }
                    }
                    BrassMini {
                        id: forget
                        visible: row.dev.paired
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        label: "Forget"; onClicked: row.dev.forget()
                    }
                }
            }
        }
    }
}
