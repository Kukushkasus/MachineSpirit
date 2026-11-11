// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Effects
import qs.common

// Yellow/black warning stripes, clipped to the item.
Item {
    id: root
    property real stripe: 8
    property real radius: 0
    clip: true
    layer.enabled: radius > 0
    layer.effect: MultiEffect { maskEnabled: true; maskSource: hzMask }
    Item { id: hzMask; anchors.fill: parent; visible: false; layer.enabled: true; Rectangle { anchors.fill: parent; radius: root.radius } }
    Rectangle { anchors.fill: parent; color: "#141210" }
    Row {
        x: -root.height
        Repeater {
            model: Math.max(0, Math.ceil((root.width + root.height * 2) / (root.stripe * 2)) + 1)
            Item {
                width: root.stripe * 2; height: root.height
                Rectangle { width: root.stripe; height: root.height * 2; y: -root.height / 2; color: Theme.hazard; rotation: 35; antialiasing: true }
            }
        }
    }
}
