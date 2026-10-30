// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import qs.common
import qs.services

// Vox-caster: traffic traces and the link's particulars as terminal lines. Click a value to copy it.
Column {
    id: root
    width: 420
    spacing: 12
    property string copied: ""
    Timer { id: unflash; interval: 1400; onTriggered: root.copied = "" }
    function copy(v) { Quickshell.execDetached(["wl-copy", v]); root.copied = v; unflash.restart() }

    Tile {
        width: parent.width; height: 160; radius: 6; padding: 12
        Item {
            anchors.fill: parent
            Glow { font { pixelSize: 16; weight: Font.DemiBold } text: Net.online ? (Net.connection !== "" ? Net.connection : Net.iface) + ", " + Net.kind.toLowerCase() : "No vox signal" }
            Oscillo { y: 28; width: parent.width; height: 80; values: Sys.rxHist; values2: Sys.txHist }
            Row {
                anchors.bottom: parent.bottom; spacing: 26
                Row { spacing: 6
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "south"; size: 16; color: Theme.glow }
                    Glow { font { pixelSize: 15; weight: Font.DemiBold } text: Sys.formatRate(Sys.rxRate) }
                    Glow { anchors.baseline: parent.children[1].baseline; halo: 0; color: Theme.glowDim; font.pixelSize: 11; text: Net.fmtBytes(Net.rxTotal) + " received" } }
                Row { spacing: 6
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "north"; size: 16; color: Theme.glowDim }
                    Glow { color: Theme.glowDim; font { pixelSize: 15; weight: Font.DemiBold } text: Sys.formatRate(Sys.txRate) }
                    Glow { anchors.baseline: parent.children[1].baseline; halo: 0; color: Theme.glowDim; font.pixelSize: 11; text: Net.fmtBytes(Net.txTotal) + " sent" } }
            }
        }
    }
    Tile {
        width: parent.width; height: lines.implicitHeight + 20; radius: 6; padding: 10
        Column {
            id: lines
            width: parent.width
            Repeater {
                model: [
                    { k: "Interface",        v: Net.iface },
                    { k: "Local address",    v: Net.localIp },
                    { k: "Public address",   v: Net.publicIp !== "" ? Net.publicIp : "checking" },
                    { k: "Gateway",          v: Net.gateway },
                    { k: "Hardware address", v: Net.mac }
                ]
                Item {
                    required property var modelData
                    width: lines.width; height: 26
                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.glow; opacity: lm.containsMouse ? 0.08 : 0 }
                    Glow { x: 4; anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim; font { family: Theme.fontMono; pixelSize: 12 } text: modelData.k.toLowerCase().replace(/ /g, "_") }
                    Glow { anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter } halo: root.copied === modelData.v ? 0.9 : 0.2
                        font { family: Theme.fontMono; pixelSize: 12 } text: root.copied === modelData.v ? "copied" : modelData.v }
                    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.copy(modelData.v) }
                }
            }
        }
    }
}
