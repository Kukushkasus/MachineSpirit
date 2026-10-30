// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services
Instrument {
    title: "Cogitator"; serial: "03 / TELEMETRY"; corner: 8
    Text { text: "CPU"; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
    Text { anchors.right: parent.right; text: Math.round(Sys.cpu * 100) + "%"; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 22 } }
    Oscillo { y: 27; width: parent.width; height: 51; values: Sys.cpuHist; max: 1 }
    Text { y: 87; text: "MEMORY"; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11 } }
    Text { y: 87; anchors.right: parent.right; text: Sys.ramUsedGb.toFixed(1) + " / " + Sys.ramTotalGb.toFixed(1) + " GB"; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 12 } }
    Rectangle { y: 109; width: parent.width; height: 4; color: Qt.alpha(Theme.glow, 0.1)
        Rectangle { width: parent.width * Math.min(1, Sys.ram); height: parent.height; color: Theme.glowDim }
    }
    Row { y: 125; spacing: 16
        Column { width: 154; spacing: 4
            Text { text: "↓ " + Sys.formatRate(Sys.rxRate); color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
            Oscillo { width: parent.width; height: 20; values: Sys.rxHist; grid: false }
        }
        Column { width: 154; spacing: 4
            Text { text: "↑ " + Sys.formatRate(Sys.txRate); color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
            Oscillo { width: parent.width; height: 20; values: Sys.txHist; grid: false; tone: Theme.brassHi }
        }
    }
}
