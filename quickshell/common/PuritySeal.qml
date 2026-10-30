// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Wax seal with two parchment tails. `text` is pressed into the wax.
Item {
    id: root
    property string text: ""
    property real size: 18
    width: size; height: size * 1.6
    Rectangle { x: root.size * 0.18; y: root.size * 0.55; width: root.size * 0.26; height: root.size; rotation: 8; color: "#d9cba3"; antialiasing: true }
    Rectangle { x: root.size * 0.54; y: root.size * 0.55; width: root.size * 0.26; height: root.size * 0.9; rotation: -6; color: "#cbbc92"; antialiasing: true }
    Shape {
        width: root.size; height: root.size
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.darker(Theme.wax, 1.6); strokeWidth: 0.6
            fillGradient: RadialGradient {
                centerX: root.size * 0.38; centerY: root.size * 0.34; centerRadius: root.size * 0.7
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: Qt.lighter(Theme.wax, 1.6) }
                GradientStop { position: 1; color: Qt.darker(Theme.wax, 1.3) }
            }
            PathPolyline {
                path: {
                    const p = [], c = root.size / 2
                    for (let i = 0; i <= 40; i++) {
                        const a = i / 40 * Math.PI * 2, r = c * (0.9 + 0.08 * Math.sin(a * 9))
                        p.push(Qt.point(c + r * Math.cos(a), c + r * Math.sin(a)))
                    }
                    return p
                }
            }
        }
    }
    Text {
        width: root.size; height: root.size
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        text: root.text
        color: "#ffd9cc"
        font { family: Theme.fontNum; pixelSize: root.size * 0.5; weight: Font.Bold }
        renderType: Text.NativeRendering
    }
}
