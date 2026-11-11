// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron key: a leaning cell. At rest nothing shows; under the pointer its edge lights; engaged it fills
// with a cold glow and its edge burns.
Item {
    id: root
    required property Item host
    readonly property color tone: host.danger ? Theme.rustText : Theme.glow
    Poly {
        anchors.fill: parent
        points: Skin.lean(width, height, Math.min(7, width / 5))
        upper: root.host.solid && !root.host.on && !root.host.hovered ? Qt.darker(Theme.glass, 1.25) : Qt.alpha(root.tone, root.host.pressed ? 0.24 : root.host.on ? 0.16 : root.host.hovered ? 0.07 : 0)
        lower: root.host.solid && !root.host.on && !root.host.hovered ? Qt.darker(Theme.metal, 1.4) : Qt.alpha(root.tone, root.host.pressed ? 0.12 : root.host.on ? 0.06 : 0)
        stroke: Qt.alpha(root.tone, root.host.on ? 0.95 : root.host.hovered || root.host.pressed ? 0.6 : root.host.solid ? 0.3 : 0)
        strokeWidth: 1
    }
}
