// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus housing: forged metal, bevelled edge, brass bolts in the corners. Large windows also get brass
// corner straps and a riveted band
Item {
    id: root
    required property Item host
    Rectangle {   // outer edge, lit from above
        anchors.fill: parent
        radius: root.host.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.metalEdge }
            GradientStop { position: 0.12; color: Theme.metalHi }
            GradientStop { position: 1.0; color: Theme.metalLo }
        }
    }
    Rectangle {   // body
        anchors { fill: parent; margins: 1.5 }
        radius: Math.max(0, root.host.radius - 1.5)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.metalHi }
            GradientStop { position: 0.5; color: Theme.metal }
            GradientStop { position: 1.0; color: Qt.darker(Theme.metal, 1.25) }
        }
    }
    Repeater {
        model: root.host.bolts ? 4 : 0
        Bolt {
            required property int index
            kit: "mechanicus"
            size: root.host.boltSize
            angle: 20 + index * 47
            x: (index % 2 === 0) ? root.host.radius * 0.45 + 1 : root.width - size - root.host.radius * 0.45 - 1
            y: (index < 2) ? root.host.radius * 0.45 + 1 : root.height - size - root.host.radius * 0.45 - 1
        }
    }
    readonly property bool dressed: Theme.ornaments > 0 && (root.host.role === "window") && width > 200 && height > 120
    Repeater {   // brass corner straps: an L of beaten brass over each corner, held by one rivet
        model: root.dressed ? 4 : 0
        Item {
            required property int index
            readonly property bool r: index % 2 === 1
            readonly property bool b: index >= 2
            x: r ? root.width - 26 : -2; y: b ? root.height - 26 : -2; width: 28; height: 28
            Rectangle { x: parent.r ? 0 : 0; y: parent.b ? 23 : 0; width: 28; height: 5; radius: 1.5
                gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } }
            Rectangle { x: parent.r ? 23 : 0; y: 0; width: 5; height: 28; radius: 1.5
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } }
            Rectangle { x: parent.r ? 23.5 : 0.5; y: parent.b ? 23.5 : 0.5; width: 4; height: 4; radius: 2; color: Theme.brassLo; border { width: 0.6; color: Qt.darker(Theme.brassLo, 1.6) } }
        }
    }
    Repeater {   // the riveted band along the top and the foot of the rim
        model: root.dressed ? 2 * Math.max(0, Math.floor((root.width - 70) / 44)) : 0
        Rectangle {
            required property int index
            readonly property int n: Math.max(1, Math.floor((root.width - 70) / 44))
            width: 3; height: 3; radius: 1.5
            x: 35 + (index % n + 0.5) * (root.width - 70) / n - 1.5; y: index < n ? 2.2 : root.height - 5.2
            color: Theme.metalEdge; border { width: 0.5; color: Theme.metalLo }
        }
    }
}
