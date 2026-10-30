// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

// Augury: now (big reading, sky, feels-like, today's range), the coming hours as a strip of readings,
// the coming days as range bars on one shared scale, and four small instruments: wind, humidity,
// pressure, and the sun's hours.
Column {
    id: root
    width: 392
    spacing: 10
    readonly property var days: Weather.forecast
    readonly property real lo: days.length ? Math.min(...days.map(d => d.lo)) : 0
    readonly property real hi: days.length ? Math.max(...days.map(d => d.hi)) : 1
    function hm(h) { const hh = Math.floor(h), mm = Math.round((h - hh) * 60); return String(hh).padStart(2, "0") + ":" + String(mm).padStart(2, "0") }

    // ---- now
    Item {
        width: parent.width; height: 80
        Row {
            spacing: 14
            Glow {
                halo: 0.8
                font { family: Theme.fontNum; pixelSize: 54; weight: Font.Medium }
                text: Weather.ready ? Math.round(Weather.temp) + "°" : "–"
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Glow { halo: 0; font { family: Theme.fontNum; pixelSize: 16; weight: Font.DemiBold }
                    text: Weather.ready ? Weather.desc : "Consulting the auspex" }
                Glow { halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 13 }
                    text: "Feels like " + Math.round(Weather.feels) + "°" }
                Glow { halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 13 }
                    visible: root.days.length > 0
                    text: root.days.length ? "High " + root.days[0].hi + "°, low " + root.days[0].lo + "°" : "" }
            }
        }
        Column {
            anchors { right: parent.right; top: parent.top }
            spacing: 4
            Icon { anchors.right: parent.right; name: Weather.icon; size: 46; color: Theme.glow }
            Row {
                anchors.right: parent.right; spacing: 3
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "location_on"; size: 14; color: Theme.glowDim }
                Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 12 } text: Weather.area }
            }
        }
    }

    // ---- the coming hours
    Tile {
        width: parent.width; height: 88; padding: 8
        Row {
            anchors.fill: parent
            Repeater {
                model: Weather.upcoming
                Column {
                    required property var modelData
                    required property int index
                    width: parent.width / Math.max(1, Weather.upcoming.length)
                    spacing: 4
                    Glow { anchors.horizontalCenter: parent.horizontalCenter; halo: 0; color: index === 0 ? Theme.glow : Theme.glowDim
                        font { family: Theme.fontNum; pixelSize: 11; weight: index === 0 ? Font.Bold : Font.Normal } text: modelData.label }
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; name: index === 0 ? Weather.icon : modelData.icon; size: 20; color: Theme.glow }
                    Glow { anchors.horizontalCenter: parent.horizontalCenter; halo: 0
                        font { family: Theme.fontNum; pixelSize: 14; weight: Font.DemiBold } text: Math.round(index === 0 ? Weather.temp : modelData.temp) + "°" }
                    Glow { anchors.horizontalCenter: parent.horizontalCenter; halo: 0; color: Theme.glowDim
                        opacity: modelData.rain >= 20 ? 1 : 0
                        font { family: Theme.fontNum; pixelSize: 10 } text: modelData.rain + "%" }
                }
            }
        }
    }

    // ---- the coming days: each range on the same scale
    Tile {
        width: parent.width; height: root.days.length * 27 + 12; padding: 6
        Column {
            anchors.fill: parent
            Repeater {
                model: root.days
                Item {
                    id: day
                    required property var modelData
                    required property int index
                    width: parent.width; height: 27
                    Glow { x: 6; anchors.verticalCenter: parent.verticalCenter; width: 62; halo: 0
                        font { family: Theme.fontNum; pixelSize: 14; weight: Font.Medium }
                        text: day.index === 0 ? "Today" : day.modelData.day.charAt(0).toUpperCase() + day.modelData.day.slice(1) }
                    Icon { x: 72; anchors.verticalCenter: parent.verticalCenter; name: day.modelData.icon; size: 20; color: Theme.glow }
                    Glow { x: 98; anchors.verticalCenter: parent.verticalCenter; width: 34; halo: 0; color: Theme.glowDim
                        horizontalAlignment: Text.AlignRight; font { family: Theme.fontNum; pixelSize: 11 }
                        opacity: day.modelData.rain >= 20 ? 1 : 0; text: day.modelData.rain + "%" }
                    Glow { x: 138; anchors.verticalCenter: parent.verticalCenter; width: 34; halo: 0; color: Theme.glowDim
                        horizontalAlignment: Text.AlignRight; font { family: Theme.fontNum; pixelSize: 14 } text: day.modelData.lo + "°" }
                    Item {   // range bar
                        x: 180; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 180 - 44; height: 6
                        readonly property real span: Math.max(1, root.hi - root.lo)
                        Rectangle { anchors.fill: parent; radius: 3; color: Qt.alpha(Theme.glow, 0.12) }
                        Rectangle {
                            x: parent.width * (day.modelData.lo - root.lo) / parent.span
                            width: Math.max(6, parent.width * (day.modelData.hi - day.modelData.lo) / parent.span); height: 6; radius: 3
                            gradient: Gradient { orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.glowDim } GradientStop { position: 1; color: Theme.glow } }
                        }
                        Rectangle {   // where today is now
                            visible: day.index === 0 && Weather.ready
                            x: parent.width * (Weather.temp - root.lo) / parent.span - 4; y: -1
                            width: 8; height: 8; radius: 4; color: Theme.glass; border { width: 2; color: Theme.glow }
                        }
                    }
                    Glow { anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter } halo: 0
                        font { family: Theme.fontNum; pixelSize: 14; weight: Font.DemiBold } text: day.modelData.hi + "°" }
                }
            }
        }
    }

    // ---- instruments
    Row {
        spacing: 10
        Repeater {
            model: [
                { icon: "air", name: "Wind", value: Weather.wind + " km/h" },
                { icon: "humidity_percentage", name: "Humidity", value: Weather.humidity + "%" },
                { icon: "compress", name: "Pressure", value: Weather.pressure + " hPa" },
                { icon: "wb_twilight", name: "Sun", value: "↑" + root.hm(Weather.sunrise) + " ↓" + root.hm(Weather.sunset) }
            ]
            Tile {
                required property var modelData
                width: (root.width - 30) / 4; height: 54; padding: 8
                Row {
                    spacing: 5
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 15; color: Theme.glowDim }
                    Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11 } text: modelData.name }
                }
                Glow { anchors.bottom: parent.bottom; width: parent.width; elide: Text.ElideRight; halo: 0
                    font { family: Theme.fontNum; pixelSize: modelData.value.length > 9 ? 11 : 13; weight: Font.DemiBold } text: modelData.value }
            }
        }
    }
}
