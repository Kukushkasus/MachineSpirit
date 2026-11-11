// [ PURITY SEAL ] Discipline in every line.
import QtQuick
import qs.common

// Ultramarines gauge: one solid bar in a cut-cornered channel, a gold cap at its head, a ruled scale above
// and below with a long mark every quarter. The last tenth is marked red on the scale, not on the bar.
Item {
    id: root
    required property Item host
    readonly property real lv: Math.max(0, Math.min(1, host.level))
    Poly {
        x: -4; y: -4; width: parent.width + 8; height: parent.height + 8
        points: Skin.chamfer(width, height, 4)
        upper: Qt.darker(Theme.glass, 1.4); lower: Qt.darker(Theme.metal, 1.6)
        stroke: Qt.alpha(Theme.brass, root.host.hovered ? 0.9 : 0.45); strokeWidth: 1
    }
    Rectangle {   // the bar
        x: 1; y: 3; height: parent.height - 6; width: Math.max(0, (parent.width - 2) * root.lv)
        gradient: Gradient {
            GradientStop { position: 0; color: root.host.off ? Qt.alpha(Theme.glow, 0.3) : Qt.lighter(Theme.glow, 1.15) }
            GradientStop { position: 1; color: root.host.off ? Qt.alpha(Theme.glow, 0.2) : Theme.glowDim }
        }
    }
    Rectangle {   // the gold cap
        visible: root.lv > 0.01
        x: Math.max(0, 1 + (parent.width - 2) * root.lv - 2); y: 0; width: 3; height: parent.height
        color: Theme.brassHi
    }
    Strokes {   // the scale
        anchors.fill: parent
        color: Qt.alpha(Theme.brass, 0.7); lineWidth: 1; round: false
        lines: { const l = []; for (let i = 0; i <= 20; i++) { const x = 1 + (width - 2) * i / 20, long = i % 5 === 0; l.push([x, -4, x, long ? -1 : -2.5]); l.push([x, height + 4, x, height + (long ? 1 : 2.5)]) } return l }
    }
    Rectangle { x: 1 + (parent.width - 2) * 0.9; y: parent.height + 3; width: (parent.width - 2) * 0.1; height: 1.5; color: Theme.rustText }
}
