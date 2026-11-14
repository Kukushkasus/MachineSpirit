// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne section: iron slab with a brass lip and rivets, title on a forged tag in black-letter, readings on a
// second tag. Engaged, it glows like iron left in the fire
Item {
    id: root
    required property Item host
    readonly property real ft: host.frameTop
    readonly property real bh: height - ft
    readonly property real c: Math.min(5, bh / 4)

    Poly {   // the slab
        y: root.ft; width: root.width; height: root.bh
        points: Skin.iron(width, height, root.c, 0)
        upper: Qt.tint(root.host.fill, Qt.alpha(Theme.metal, 0.35))
        lower: Qt.tint(root.host.fill, Qt.alpha(Theme.rust, root.host.glow ? 0.28 : 0.1))
        stroke: root.host.glow ? Qt.alpha(Theme.glow, 0.85) : Qt.darker(Theme.brassLo, 1.15); strokeWidth: root.host.glow ? 1.6 : 1.2
    }
    Rectangle {   // the brass lip
        x: root.c + 1; y: root.ft + 1; width: Math.max(0, root.width - 2 * root.c - 2); height: 2.5
        gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
        opacity: 0.8
    }
    Repeater {   // rivets in the upper corners
        model: root.width > 60 && root.bh > 30 ? 2 : 0
        Rectangle {
            required property int index
            x: index ? root.width - 10 : 6; y: root.ft + 6; width: 4; height: 4; radius: 2
            gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } }
        }
    }
    Item {   // the forged tag
        visible: root.host.tab !== ""
        x: 12; width: tabRow.implicitWidth + 30; height: root.host.tabHeight + 2; y: -1
        Poly {
            anchors.fill: parent
            points: Skin.iron(width, height, 4, 0)
            upper: Qt.lighter(Theme.metal, 1.1); lower: Qt.darker(Theme.metal, 1.6)
            stroke: Qt.tint(Theme.brass, Qt.alpha(Theme.rustText, root.host.surge)); strokeWidth: 1.5
        }
        Repeater {
            model: 2
            Rectangle { required property int index; x: index ? parent.width - 8 : 4; anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: Theme.brass }
        }
        Row {
            id: tabRow
            anchors.centerIn: parent; spacing: 7
            Icon { visible: root.host.tabIcon !== ""; anchors.verticalCenter: parent.verticalCenter; name: root.host.tabIcon; size: 15; color: Theme.brassHi }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.host.tab; renderType: Text.NativeRendering
                color: Theme.brassHi
                font { family: Skin.display(root.host.tab); pixelSize: Skin.display(root.host.tab) === Theme.fontNum ? 13 : 16; weight: Font.Black; letterSpacing: 1 }
            }
        }
    }
    Poly {   // the second tag behind the readings
        visible: root.host.plateBox.visible
        x: root.host.plateBox.x; y: root.host.plateBox.y - 1; width: root.host.plateBox.width; height: root.host.plateBox.height + 2
        points: Skin.iron(width, height, 4, 0)
        upper: Qt.lighter(Theme.metal, 1.1); lower: Qt.darker(Theme.metal, 1.6)
        stroke: Qt.tint(Theme.brass, Qt.alpha(Theme.rustText, root.host.surge)); strokeWidth: 1.5
    }
}
