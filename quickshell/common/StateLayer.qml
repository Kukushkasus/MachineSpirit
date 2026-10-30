// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Hover / press overlay (Material state layer). Fills its parent and follows its radius.
Rectangle {
    property bool hovered: false
    property bool pressed: false
    property color tone: Theme.surfaceOn
    anchors.fill: parent
    radius: parent.radius ?? 0
    color: tone
    opacity: pressed ? Theme.pressLayer : (hovered ? Theme.hoverLayer : 0)
    Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
}
