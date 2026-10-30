// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services
Instrument {
    title: "Augury"; serial: "02 / ATMOS"; corner: 10
    Text { width: parent.width - 52; text: Weather.ready ? Weather.area : "Weather unavailable"; elide: Text.ElideRight; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
    Icon { anchors.right: parent.right; y: 16; name: Weather.icon; size: 45; color: Theme.glow }
    Text { y: 16; text: Weather.ready ? Math.round(Weather.temp) + "°" : "—"; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 53; weight: Font.Light } }
    Text { y: 77; width: parent.width; elide: Text.ElideRight; text: Weather.ready ? Weather.desc + " · feels " + Math.round(Weather.feels) + "°" : "Waiting for a weather report"; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
    Text { y: 98; text: Weather.ready ? Weather.wind + " km/h   ·   " + Weather.humidity + "% humidity" : ""; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } }
    Row { y: 123; spacing: 8
        Repeater { model: Weather.ready ? Weather.upcoming.slice(0, 4) : []
            Column { required property var modelData; width: 60; spacing: 4
                Text { text: modelData.label; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 10 } }
                Row { spacing: 5; Icon { name: modelData.icon; size: 16; color: Theme.glowDim } Text { text: Math.round(modelData.temp) + "°"; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 13 } } }
            }
        }
    }
    Text { anchors { right: parent.right; top: parent.top } visible: Weather.stale; text: "STALE"; color: Theme.rustText; font { family: Theme.fontNum; pixelSize: 10 } }
}
