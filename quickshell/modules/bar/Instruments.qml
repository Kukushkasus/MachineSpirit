// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import qs.common
import qs.services

// Small dials for processor and memory (open the Cogitator) and the network rate (opens the Vox-caster).
Row {
    id: root
    spacing: 2
    signal puff()
    property bool showRate: true
    property bool wasHot: false
    Connections {
        target: Sys
        function onCpuChanged() { const hot = Sys.cpu > 0.85; if (hot && !root.wasHot) root.puff(); root.wasHot = hot }
    }
    BarButton {
        popup: "resources"
        tip: "Processor " + Math.round(Sys.cpu * 100) + "%, memory " + Math.round(Sys.ram * 100) + "%"
        implicitWidth: 58
        Row {
            anchors.centerIn: parent; spacing: 4
            RingGauge { value: Sys.cpu; icon: "memory" }
            RingGauge { value: Sys.ram; icon: "memory_alt" }
        }
    }
    BarButton {
        popup: "network"
        tip: Net.online ? "Network: " + (Net.connection || Net.iface) : "Offline"
        implicitWidth: showRate ? 18 + 62 : 24
        Icon { x: 2; anchors.verticalCenter: parent.verticalCenter; size: 15
            name: Net.online ? "swap_vert" : "signal_disconnected"; color: Net.online ? Theme.glowDim : Theme.rustText }
        Glow {
            id: rate
            visible: root.showRate
            x: 20; anchors.verticalCenter: parent.verticalCenter
            width: 58
            halo: 0; color: Theme.glowDim
            font { family: Theme.fontNum; pixelSize: 12; weight: Font.Medium; features: { "tnum": 1 } }
            text: Sys.formatRate(Sys.rxRate + Sys.txRate)
        }
    }
}
