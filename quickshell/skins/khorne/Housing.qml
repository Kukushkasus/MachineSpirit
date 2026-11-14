// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne housing: blackened iron under a brass lip, cut corners, rivets, spikes up top, saw edge on large windows.
// nothing glows on it except the forge light in the glass
Item {
    id: root
    required property Item host
    readonly property real c: Math.max(3, root.host.radius * 0.55)
    readonly property bool big: root.host.role === "window" || root.host.role === "toast"
    readonly property bool dressed: Theme.ornaments > 0 && root.big && width > 120 && height > 60
    readonly property real teeth: root.big && width > 160 && height > 80 ? 4 : 0

    Poly {   // the brass lip, its foot cut into teeth
        anchors.fill: parent
        points: Skin.iron(width, height, root.c, root.teeth)
        upper: Theme.brass; lower: Qt.darker(Theme.brassLo, 1.2)
        stroke: Qt.darker(Theme.brassLo, 1.8); strokeWidth: 0.8
    }
    Poly {   // the iron
        x: 2.5; y: 2.5; width: parent.width - 5; height: parent.height - 5 - root.teeth
        points: Skin.iron(width, height, Math.max(1, root.c - 1), 0)
        upper: Qt.lighter(Theme.metal, 1.05); lower: Qt.darker(Theme.metal, 1.9)
    }
    Repeater {   // nicks in the lip
        model: root.width > 90 ? 3 : 0
        Rectangle {
            required property int index
            x: root.c + 6 + Skin.hash(root.width, root.height, index + 20) * (root.width - 2 * root.c - 20); y: 0
            width: 3 + Skin.hash(root.width, root.height, index + 30) * 4; height: 2; color: Qt.darker(Theme.metalLo, 1.4)
        }
    }
    Repeater {   // rivets along the top
        model: root.width > 80 ? Math.max(2, Math.floor((root.width - 2 * root.c - 24) / 46) + 1) : 0
        Rectangle {
            required property int index
            readonly property int n: Math.max(2, Math.floor((root.width - 2 * root.c - 24) / 46) + 1)
            width: 4; height: 4; radius: 2
            x: root.c + 12 + index * (root.width - 2 * root.c - 24) / Math.max(1, n - 1) - 2; y: 2.5
            gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
        }
    }
    Repeater {   // spikes off the upper corners
        model: root.dressed ? 2 : 0
        Poly {
            required property int index
            readonly property bool r: index === 1
            readonly property real k: root.c
            width: k + 14; height: k + 14
            x: r ? root.width - k : -14; y: -14
            // a blade standing on the cut corner, pointing out along the diagonal
            points: r ? [[k * 0.15, k * 0.15 + 14], [k * 0.85, k * 0.85 + 14], [k / 2 + 11, k / 2 + 14 - 11]]
                      : [[k * 0.85 + 14, k * 0.15 + 14], [k * 0.15 + 14, k * 0.85 + 14], [k / 2 + 14 - 11, k / 2 + 14 - 11]]
            upper: Theme.brassHi; lower: Theme.brassLo
            stroke: Qt.darker(Theme.brassLo, 1.6); strokeWidth: 0.7
        }
    }
}
