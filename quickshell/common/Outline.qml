// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import qs.common

// A rim drawn in the livery's own corner language: a rounded rectangle (mechanicus), cut corners
// (ultramarines), the monolith's uneven cuts (necrons), small iron cuts (khorne). Optionally filled.
Item {
    id: root
    property real radius: 6
    property color color: Theme.glow
    property real lineWidth: 1
    property color fill: "transparent"
    property string style: Skin.frame
    enabled: false
    Rectangle {
        visible: root.style === "mechanicus"
        anchors.fill: parent; radius: root.radius; color: root.fill
        border { width: root.lineWidth; color: root.color }
    }
    Poly {
        visible: root.style !== "mechanicus"
        anchors.fill: parent
        points: visible ? Skin.outline(root.style, width, height, Math.max(3, root.radius)) : []
        upper: root.fill; stroke: root.color; strokeWidth: root.lineWidth
    }
}
