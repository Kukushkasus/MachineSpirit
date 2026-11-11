// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus well: a round glass well; its ring lights with the module.
Rectangle {
    required property Item host
    radius: width / 2
    color: host.lit ? Qt.alpha(Theme.glow, 0.14) : Qt.darker(Theme.glass, 1.3)
    border { width: host.lit ? 1.5 : 1; color: host.lit ? Theme.glow : Qt.alpha(Theme.metalEdge, 0.5) }
    Behavior on color { ColorAnimation { duration: Theme.dMedium } }
}
