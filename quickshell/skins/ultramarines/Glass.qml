// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines glass: a tactical display. Blue-black glass cut to the plate's corners, a fine grid, a ruler
// down the left edge, a gold rule under the top edge and gold brackets in the corners. It wipes on from the left.
Item {
    id: root
    required property Item host
    required property bool over
    readonly property real c: Math.max(3, host.radius)
    readonly property bool big: width > 90 && height > 60

    Poly {   // the glass
        visible: !root.over
        anchors.fill: parent
        points: Skin.chamfer(width, height, root.c)
        upper: Qt.alpha(Qt.tint(Theme.glass, Qt.alpha(Theme.metal, 0.32)), Theme.panelOpacity)
        lower: Qt.alpha(Qt.darker(Theme.glass, 1.25), Theme.panelOpacity)
        stroke: Qt.alpha(Theme.brassLo, 0.9); strokeWidth: 1
    }
    Rectangle {   // a cool light across the upper glass
        visible: !root.over
        x: root.c; y: 1; width: Math.max(0, root.width - 2 * root.c); height: root.height * 0.35
        gradient: Gradient { GradientStop { position: 0; color: Qt.alpha(Theme.glowFaint, 0.16) } GradientStop { position: 1; color: "transparent" } }
    }
    Image {   // the grid
        visible: root.over && root.host.scanlines
        anchors { fill: parent; margins: root.c * 0.6 }
        source: Qt.resolvedUrl("../../assets/grid.svg")
        fillMode: Image.Tile; smooth: false
        opacity: 0.08
    }
    Strokes {   // the ruler: a tick every 8 px down the left edge, every fifth one long
        visible: root.over && root.big && root.height > 120
        x: 3; y: root.c + 4; width: 8; height: root.height - 2 * root.c - 8
        color: Qt.alpha(Theme.glowDim, 0.4); lineWidth: 1; round: false
        lines: { const l = [], n = Math.floor(height / 8); for (let i = 0; i <= n; i++) l.push([0, i * 8, i % 5 === 0 ? 6 : 3, i * 8]); return l }
    }
    Rectangle {   // gold rule under the top edge
        visible: root.over && root.big
        x: root.c + 6; y: 3; width: Math.max(0, root.width - 2 * root.c - 12); height: 1
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.2; color: Qt.alpha(Theme.brass, 0.55) }
            GradientStop { position: 0.8; color: Qt.alpha(Theme.brass, 0.55) } GradientStop { position: 1; color: "transparent" } }
    }
    Repeater {   // brackets in the corners
        model: root.over && root.big ? 4 : 0
        Item {
            required property int index
            readonly property real m: 4 + root.c * 0.45
            x: index % 2 ? root.width - m - 10 : m; y: index < 2 ? m : root.height - m - 10; width: 10; height: 10
            Rectangle { y: parent.index < 2 ? 0 : 9; width: 10; height: 1; color: Qt.alpha(Theme.brass, 0.75) }
            Rectangle { x: parent.index % 2 ? 9 : 0; width: 1; height: 10; color: Qt.alpha(Theme.brass, 0.75) }
        }
    }
    Rectangle {   // the wipe after power-on
        visible: root.over && root.host.booting
        width: 2; height: root.height
        x: root.host.sweep * root.width
        color: Qt.alpha(Theme.glow, 0.35)
    }
}
