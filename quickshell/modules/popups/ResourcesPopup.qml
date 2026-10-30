// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

// Cogitator station: four readouts, a trace of the processor and the hungriest processes.
Column {
    id: root
    width: 372
    spacing: 12
    // four readouts: what it is, how full, how much
    Grid {
        columns: 2; spacing: 10
        Repeater {
            model: [
                { name: "Processor", icon: "memory", v: Sys.cpu, sub: "load " + Sys.load1.toFixed(2) },
                { name: "Memory", icon: "memory_alt", v: Sys.ram, sub: Sys.ramUsedGb.toFixed(1) + " / " + Sys.ramTotalGb.toFixed(1) + " GB" },
                { name: "Swap", icon: "swap_horiz", v: Sys.swap, sub: Sys.swapTotalGb > 0 ? Sys.swapUsedGb.toFixed(1) + " / " + Sys.swapTotalGb.toFixed(1) + " GB" : "none" },
                { name: "Archive", icon: "hard_drive", v: Sys.disk, sub: Math.round(Sys.diskUsedGb) + " / " + Math.round(Sys.diskTotalGb) + " GB" }
            ]
            Tile {
                id: tile
                required property var modelData
                readonly property bool hot: modelData.v > 0.85
                width: (root.width - 10) / 2; height: 80; padding: 10
                lit: hot
                Glow {
                    anchors { right: parent.right; top: parent.top; topMargin: -4 }
                    halo: 0.5; color: tile.hot ? Theme.rustText : Theme.glow
                    font { family: Theme.fontNum; pixelSize: 22; weight: Font.DemiBold; features: { "tnum": 1 } }
                    text: Math.round(tile.modelData.v * 100) + "%"
                }
                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: 5
                    Row {
                        spacing: 5
                        Icon { anchors.verticalCenter: parent.verticalCenter; name: tile.modelData.icon; size: 16; color: tile.hot ? Theme.rustText : Theme.glowDim }
                        Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 14; weight: Font.Medium } text: tile.modelData.name }
                    }
                    Glow { halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11 } text: tile.modelData.sub }
                    Item {   // level: lit segment, then the dim rest with an end stop
                        width: parent.width; height: 4
                        Rectangle { width: parent.width; height: 4; radius: 2; color: Qt.alpha(Theme.glow, 0.12) }
                        Rectangle {
                            width: Math.max(4, parent.width * Math.min(1, tile.modelData.v)); height: 4; radius: 2
                            color: tile.hot ? Theme.rustText : Theme.glow
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                        Rectangle { x: parent.width - 3; y: -1; width: 3; height: 6; radius: 1.5; color: Theme.glowDim }
                    }
                }
            }
        }
    }
    Tile {
        width: parent.width; height: procCol.implicitHeight + 24; radius: 8; padding: 12
        clip: true
        Column {
            id: procCol
            width: parent.width
            spacing: 8
            Row {
                spacing: 10
                Glow { font { pixelSize: 15; weight: Font.DemiBold } text: "Processor load" }
                Glow { color: Theme.glowDim; halo: 0; font.pixelSize: 13; anchors.baseline: parent.children[0].baseline; text: "last two minutes, load " + Sys.load1.toFixed(2) }
            }
            Oscillo { width: parent.width; height: 66; values: Sys.cpuHist; max: 1 }
            Repeater {
                model: Sys.procs
                Item {
                    required property var modelData
                    width: parent.width; height: 18
                    Glow { halo: 0; font { family: Theme.fontMono; pixelSize: 12 } text: "> " + modelData.name }
                    Glow { anchors.right: parent.right; halo: 0; color: Theme.glowDim; font { family: Theme.fontMono; pixelSize: 12 } text: modelData.cpu.toFixed(1) + "%" }
                }
            }
        }
    }
}
