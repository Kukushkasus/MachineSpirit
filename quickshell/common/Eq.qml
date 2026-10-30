// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

// Row of vertical bars driven by the spectrum. `count` bars sampled from Cava.bars.
Item {
    id: root
    property int count: 4
    property real barWidth: 3
    property color tone: Theme.primary
    property bool rounded: true
    property bool retained: false
    function sync() {
        const need = visible && !Theme.lowPower
        if (need === retained) return
        retained = need
        if (need) Cava.retain(); else Cava.release()
    }
    onVisibleChanged: sync()
    Connections { target: Theme; function onLowPowerChanged() { root.sync() } }
    Component.onCompleted: sync()
    Component.onDestruction: if (retained) Cava.release()

    Row {
        anchors.fill: parent
        spacing: root.count > 1 ? (root.width - root.count * root.barWidth) / (root.count - 1) : 0
        Repeater {
            model: root.count
            Item {
                id: slot
                required property int index
                width: root.barWidth; height: root.height
                readonly property real v: {
                    const b = Cava.bars
                    if (!b || b.length === 0) return 0.06
                    const i = Math.min(b.length - 1, Math.floor(index * b.length / root.count))
                    return Math.max(0.06, b[i])
                }
                Rectangle {
                    width: parent.width
                    height: Math.max(width, parent.height * slot.v)
                    anchors.bottom: parent.bottom
                    radius: root.rounded ? width / 2 : 0
                    color: root.tone
                    Behavior on height { NumberAnimation { duration: 70 } }
                }
            }
        }
    }
}
