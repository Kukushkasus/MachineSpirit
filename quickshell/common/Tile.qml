// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// A panel drawn on a cogitator screen: a faint phosphor wash with a thin lit border. Used inside the
// popup screens instead of a screen-within-a-screen. Same API as CrtScreen for drop-in use.
Item {
    id: root
    default property alias content: inner.data
    property real radius: 8
    property real padding: 8
    property bool scanlines: false     // accepted for CrtScreen compatibility
    property bool bootOnLoad: false
    property bool lit: false           // highlighted tile
    readonly property alias inner: inner
    function powerOn() {}

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(Theme.glow, root.lit ? 0.09 : 0.045)
        border { width: 1; color: Qt.alpha(Theme.glow, root.lit ? 0.45 : 0.16) }
    }
    Item { id: inner; anchors { fill: parent; margins: root.padding } }
}
