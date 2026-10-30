// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Tonal container: depth comes from the colour step, not from borders or shadows.
Rectangle {
    default property alias content: inner.data
    property bool focusRing: false
    radius: Theme.r20
    color: Theme.surfaceContainerHigh
    border { width: focusRing ? 2 : 0; color: Theme.primary }
    Item { id: inner; anchors.fill: parent }
}
