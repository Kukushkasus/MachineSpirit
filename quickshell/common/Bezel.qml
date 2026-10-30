// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Instrument housing: forged metal with a bevelled edge and optional corner bolts.
// Content goes inside, inset by `inset`.
Item {
    id: root
    default property alias content: inner.data
    property real radius: 8
    property real inset: 4
    property bool bolts: true
    property real boltSize: 5
    readonly property alias inner: inner

    Rectangle {   // outer edge, lit from above
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.metalEdge }
            GradientStop { position: 0.12; color: Theme.metalHi }
            GradientStop { position: 1.0; color: Theme.metalLo }
        }
    }
    Rectangle {   // body
        anchors { fill: parent; margins: 1.5 }
        radius: Math.max(0, root.radius - 1.5)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.metalHi }
            GradientStop { position: 0.5; color: Theme.metal }
            GradientStop { position: 1.0; color: Qt.darker(Theme.metal, 1.25) }
        }
    }
    Repeater {
        model: root.bolts ? 4 : 0
        Bolt {
            required property int index
            size: root.boltSize
            angle: 20 + index * 47
            x: (index % 2 === 0) ? root.radius * 0.45 + 1 : root.width - size - root.radius * 0.45 - 1
            y: (index < 2) ? root.radius * 0.45 + 1 : root.height - size - root.radius * 0.45 - 1
        }
    }
    Item { id: inner; anchors { fill: parent; margins: root.inset } }
}
