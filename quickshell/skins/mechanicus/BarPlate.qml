// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Mechanicus bar section: a CRT in a bolted bezel clamped to the top edge, shoulders flowing into it.
// powers on like a CRT at shell start, static after that
Item {
    id: root
    required property Item host
    readonly property real sr: host.sr
    readonly property real r: 10

    Shape {   // shoulders: a square minus a quarter circle on each side, in the bezel's metal
        x: -root.sr; width: root.width + 2 * root.sr; height: root.sr
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: root.sr
                GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 0.3; color: Theme.metalHi } GradientStop { position: 1; color: Theme.metal } }
            startX: 0; startY: 0
            PathLine { x: root.sr + 1; y: 0 }
            PathLine { x: root.sr + 1; y: root.sr }
            PathLine { x: root.sr; y: root.sr }
            PathArc { x: 0; y: 0; radiusX: root.sr; radiusY: root.sr; direction: PathArc.Counterclockwise }
        }
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: root.sr
                GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 0.3; color: Theme.metalHi } GradientStop { position: 1; color: Theme.metal } }
            startX: root.width + 2 * root.sr; startY: 0
            PathLine { x: root.width + root.sr - 1; y: 0 }
            PathLine { x: root.width + root.sr - 1; y: root.sr }
            PathLine { x: root.width + root.sr; y: root.sr }
            PathArc { x: root.width + 2 * root.sr; y: 0; radiusX: root.sr; radiusY: root.sr }
        }
    }

    Item {   // the bezel runs up past the edge and is cut there, so the frame hangs flush
        anchors.fill: parent
        clip: true
        Bezel {
            y: -root.r - 4; width: parent.width; height: parent.height + root.r + 4
            radius: root.r + 2; inset: 0; bolts: false
        }
        CrtScreen {
            x: 7; y: -8; width: parent.width - 14; height: parent.height + 8 - 6
            radius: 5; padding: 0; ambient: false
        }
    }
    Bolt { size: 4; x: 1.5; y: root.height - 9; angle: 30 }
    Bolt { size: 4; x: root.width - 5.5; y: root.height - 9; angle: 80 }
}
