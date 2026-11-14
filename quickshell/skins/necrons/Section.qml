// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron section: no frame, dark glass with one cut corner held by four light brackets, a channel along the
// top. Title in wide letters behind a lit diamond, readings in a leaning cartouche
Item {
    id: root
    required property Item host
    readonly property real ft: host.frameTop
    readonly property real bh: height - ft
    readonly property color line: host.glow ? Theme.glow : Qt.alpha(Theme.glowDim, 0.75)
    readonly property real k: Math.min(12, bh / 3, width / 6)

    Poly {   // the field
        y: root.ft; width: root.width; height: root.bh
        points: Skin.monolith(width, height, Math.min(7, root.bh / 4), false)
        upper: Qt.darker(root.host.fill, 1.15); lower: Qt.tint(root.host.fill, Qt.alpha(Theme.glowFaint, root.host.glow ? 0.22 : 0.08))
        stroke: Qt.alpha(Theme.glowDim, root.host.glow ? 0.35 : 0.14); strokeWidth: 1
    }
    Strokes {   // the brackets
        y: root.ft; width: root.width; height: root.bh
        color: root.line; lineWidth: root.host.glow ? 1.6 : 1.2
        readonly property real w: width
        readonly property real h: height
        lines: [[0, root.k + 6, 0, 6, 6, 0, root.k + 6, 0],
                [w - root.k, 0, w, 0, w, root.k],
                [0, h - root.k, 0, h, root.k, h],
                [w - root.k, h, w, h, w, h - root.k]]
    }
    Rectangle {   // the channel along the top edge, from the title onward
        visible: root.host.tab !== ""
        x: tabRow.x + tabRow.width + 10; y: root.ft; height: 1
        width: Math.max(0, (root.host.plateBox.visible ? root.host.plateBox.x - 12 : root.width - root.k - 6) - x)
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(Theme.glow, 0.85 * (0.6 + 0.4 * root.host.surge)) }
            GradientStop { position: 1; color: Qt.alpha(Theme.glow, 0.1 + 0.6 * root.host.surge) } }
    }
    Rectangle {   // the title's backing, so the channel and brackets do not run through the letters
        visible: root.host.tab !== ""
        x: 10; y: root.ft - 7; width: tabRow.width + 16; height: 14
        color: Qt.darker(Theme.glass, 1.2)
    }
    Row {
        id: tabRow
        visible: root.host.tab !== ""
        x: 16; y: root.ft - height / 2; spacing: 7
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; rotation: 45; color: Theme.glow; opacity: 0.6 + 0.4 * root.host.surge }
        Icon { visible: root.host.tabIcon !== ""; anchors.verticalCenter: parent.verticalCenter; name: root.host.tabIcon; size: 14; color: Theme.glowDim }
        Glow {
            anchors.verticalCenter: parent.verticalCenter; halo: 0.45
            text: root.host.tab.toUpperCase()
            font { family: Skin.display(root.host.tab); pixelSize: 11; weight: Font.Normal; letterSpacing: 2.4 }
        }
    }
    Poly {   // the cartouche behind the readings
        visible: root.host.plateBox.visible
        x: root.host.plateBox.x - 4; y: root.host.plateBox.y; width: root.host.plateBox.width + 8; height: root.host.plateBox.height
        points: Skin.lean(width, height, 7)
        upper: Qt.darker(Theme.glass, 1.2); lower: Qt.darker(Theme.metal, 1.3)
        stroke: Qt.alpha(Theme.glowDim, 0.6 + 0.4 * root.host.surge); strokeWidth: 1
    }
}
