// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Chronometer: nixie time, a 24-hour ruler with sunrise, sunset and a needle for now, and the month.
Column {
    id: root
    width: 356
    spacing: 10
    // own ticker aligned to the wall-clock second, so the seconds never stutter
    QtObject { id: sc; property date date: new Date() }
    Timer {
        id: tick; running: true; repeat: false
        interval: 1000 - new Date().getMilliseconds() + 2
        onTriggered: { sc.date = new Date(); interval = 1000 - sc.date.getMilliseconds() + 2; restart() }
    }
    readonly property real nowH: sc.date.getHours() + sc.date.getMinutes() / 60
    property int viewY: new Date().getFullYear()
    property int viewM: new Date().getMonth()
    function stepMonth(d) { const m = viewM + d; viewY += Math.floor(m / 12); viewM = ((m % 12) + 12) % 12 }
    function cellDate(i) { const off = (new Date(viewY, viewM, 1).getDay() + 6) % 7; return new Date(viewY, viewM, 1 - off + i) }
    function fmtH(h) { const hh = Math.floor(h), mm = Math.round((h - hh) * 60); return String(hh).padStart(2, "0") + ":" + String(mm).padStart(2, "0") }

    Tile {
        width: parent.width; height: 78; radius: 6; padding: 0
        Image {   // anode mesh, one tiled texture
            anchors.fill: parent; opacity: 0.1
            source: Qt.resolvedUrl("../../assets/mesh.png"); fillMode: Image.Tile; smooth: false
        }
        Nixie { anchors.centerIn: parent; anchors.verticalCenterOffset: -7; size: 40; text: Qt.locale("en_US").toString(sc.date, "HH:mm:ss") }
        Glow { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 } halo: 0.3; color: Theme.glowDim
            font { family: Theme.fontUi; pixelSize: 12 } text: { const s = Qt.locale("en_US").toString(sc.date, "dddd d MMMM yyyy"); return s.charAt(0).toUpperCase() + s.slice(1) } }
    }

    Tile {   // day ruler
        width: parent.width; height: 54; radius: 6; padding: 10
        Item {
            id: ruler
            anchors.fill: parent
            readonly property real px: width / 24
            Rectangle {   // daylight band
                x: Weather.sunrise * ruler.px; width: Math.max(0, (Weather.sunset - Weather.sunrise) * ruler.px)
                y: 12; height: 8; radius: 2
                color: Qt.alpha(Theme.glow, 0.22)
            }
            Repeater {
                model: 25
                Rectangle {
                    required property int index
                    x: index * ruler.px - 0.5; y: index % 6 === 0 ? 8 : 12
                    width: 1; height: index % 6 === 0 ? 16 : 8
                    color: Qt.alpha(Theme.glowDim, index % 6 === 0 ? 0.9 : 0.5)
                }
            }
            Repeater {
                model: [0, 6, 12, 18, 24]
                Glow { required property int modelData; x: modelData * ruler.px - width / 2; y: 24; halo: 0; color: Theme.glowDim; font.pixelSize: 11; text: String(modelData).padStart(2, "0") }
            }
            Glow { x: Weather.sunrise * ruler.px - width / 2; y: -4; halo: 0; color: Theme.glowDim; font.pixelSize: 11; text: "☀ " + root.fmtH(Weather.sunrise) }
            Glow { x: Weather.sunset * ruler.px - width / 2; y: -4; halo: 0; color: Theme.glowDim; font.pixelSize: 11; text: "☾ " + root.fmtH(Weather.sunset) }
            Rectangle {   // needle: now
                x: root.nowH * ruler.px - 1; y: 4; width: 2; height: 22; radius: 1
                color: Theme.rustText
            }
        }
    }

    Tile {   // month
        width: parent.width; height: 240; radius: 6; padding: 8
        Item {
            anchors.fill: parent
            Glow { anchors { left: parent.left; top: parent.top } halo: 0.4; font { pixelSize: 16; weight: Font.DemiBold }
                text: { const m = Qt.locale("en_US").standaloneMonthName(root.viewM); return m.charAt(0).toUpperCase() + m.slice(1) + " " + root.viewY } }
            Row {
                anchors { right: parent.right; top: parent.top; topMargin: -4 }
                spacing: 2
                BrassMini { icon: "chevron_left"; onClicked: root.stepMonth(-1) }
                BrassMini { icon: "today"; onClicked: { root.viewY = new Date().getFullYear(); root.viewM = new Date().getMonth() } }
                BrassMini { icon: "chevron_right"; onClicked: root.stepMonth(1) }
            }
            Grid {
                y: 30; columns: 7
                Repeater { model: 7
                    Glow { required property int index; width: 48; height: 20; horizontalAlignment: Text.AlignHCenter; halo: 0; color: index >= 5 ? Theme.glowFaint : Theme.glowDim; font.pixelSize: 11
                        text: Qt.locale("en_US").dayName((index + 1) % 7, Locale.ShortFormat) } }
                Repeater { model: 42
                    Item {
                        id: cell; required property int index
                        readonly property date d: root.cellDate(index)
                        readonly property bool inMonth: d.getMonth() === root.viewM
                        readonly property bool today: d.toDateString() === sc.date.toDateString()
                        width: 48; height: 30
                        Rectangle { anchors.centerIn: parent; width: 27; height: 27; radius: 13.5; color: "transparent"; border { width: cell.today ? 2 : 0; color: Theme.glow } }
                        Glow { anchors.centerIn: parent; halo: cell.today ? 0.9 : 0
                            color: cell.today ? Theme.glow : (!cell.inMonth ? Qt.alpha(Theme.glowFaint, 0.5) : (index % 7 >= 5 ? Theme.glowDim : Theme.glow))
                            font { pixelSize: 13; weight: cell.today ? Font.Bold : Font.Normal } text: cell.d.getDate() }
                    }
                }
            }
        }
    }
}
