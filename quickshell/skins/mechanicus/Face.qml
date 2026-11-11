// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus key: a phosphor wash and rim, as strong as the caller asks, or the plain colours it names.
Rectangle {
    required property Item host
    radius: host.round ? height / 2 : host.radius
    color: host.usePlain ? host.plainColor : Qt.alpha(host.tone, host.level)
    border { width: host.usePlain ? host.plainBorderWidth : host.edge > 0 ? host.edgeWidth : 0; color: host.usePlain ? host.plainBorder : Qt.alpha(host.tone, host.edge) }
    Behavior on color { ColorAnimation { duration: Theme.dShort } }
    Behavior on border.color { ColorAnimation { duration: Theme.dShort } }
}
