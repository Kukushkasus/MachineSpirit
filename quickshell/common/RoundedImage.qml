// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Effects
import qs.common

// Image clipped to a rounded rectangle (plain `clip` ignores the radius).
Item {
    id: root
    property alias source: img.source
    property real radius: 12
    property alias status: img.status
    property color fallback: Theme.surfaceContainerHigh

    Rectangle { anchors.fill: parent; radius: root.radius; color: root.fallback }
    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        sourceSize: Qt.size(root.width * 2, root.height * 2)
    }
    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: root.radius }
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        visible: img.status === Image.Ready
    }
}
