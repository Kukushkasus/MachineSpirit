// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Mechanicus section: dark glass in a thin rounded rim, halo when engaged, engraved plates top left and right.
// current runs through the plate edges when the panel opens
Item {
    id: root
    required property Item host
    readonly property color plateEdge: Qt.alpha(Theme.metalEdge, 0.7)
    readonly property color edge: host.surge > 0 ? Qt.tint(plateEdge, Qt.alpha(Theme.spark, host.surge)) : plateEdge

    Rectangle {   // a soft halo when engaged
        anchors { fill: body; margins: -2 } radius: root.host.radius + 2; color: "transparent"
        border { width: 3; color: Qt.alpha(Theme.glow, root.host.glow ? 0.16 : 0) }
        Behavior on border.color { ColorAnimation { duration: Theme.dMedium } }
    }
    Rectangle {
        id: body
        anchors { fill: parent; topMargin: root.host.frameTop }
        radius: root.host.radius; color: root.host.fill
        border { width: root.host.glow ? 1.5 : 1; color: root.host.glow ? Qt.alpha(Theme.glow, 0.85) : root.host.rim }
        Behavior on border.color { ColorAnimation { duration: Theme.dMedium } }
        Behavior on color { ColorAnimation { duration: Theme.dMedium } }
    }
    Rectangle {   // the engraved plate
        visible: root.host.tab !== ""
        x: 12; width: tabRow.implicitWidth + 26; height: root.host.tabHeight; radius: 7
        gradient: Gradient { GradientStop { position: 0; color: Theme.metal } GradientStop { position: 1; color: Theme.metalLo } }
        border { width: 1; color: root.edge }
        Row {
            id: tabRow
            anchors.centerIn: parent; spacing: 8
            Icon { visible: root.host.tabIcon !== ""; anchors.verticalCenter: parent.verticalCenter; name: root.host.tabIcon; size: 16; color: Theme.glow }
            Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0.35; text: root.host.tab.toUpperCase()
                font { family: Theme.fontNum; pixelSize: 13; weight: Font.Bold; letterSpacing: 3 } }
        }
    }
    Rectangle {   // the right-hand plate, set into the rim like the name plate
        visible: root.host.plateBox.visible
        x: root.host.plateBox.x; y: root.host.plateBox.y; width: root.host.plateBox.width; height: root.host.plateBox.height
        radius: 7
        gradient: Gradient { GradientStop { position: 0; color: Theme.metal } GradientStop { position: 1; color: Theme.metalLo } }
        border { width: 1; color: root.edge }
    }
}
