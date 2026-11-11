// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// The mark of something that matters (an urgent message, unread count). `text` is pressed into it.
// Wax and parchment, a gilt medal on a ribbon, a lit cartouche, or a rough brand, by faction.
Item {
    id: root
    property string text: ""
    property real size: 18
    width: size; height: size * 1.6
    readonly property string kit: Skin.glyph
    // the tails: parchment (mechanicus), a ribbon in the chapter's metal (ultramarines), none (necrons), a torn strip (khorne)
    Rectangle { visible: root.kit !== "necrons"; x: root.size * 0.18; y: root.size * 0.55; width: root.size * 0.26; height: root.size; rotation: root.kit === "ultramarines" ? 4 : 8; antialiasing: true
        color: root.kit === "ultramarines" ? Theme.metalHi : root.kit === "khorne" ? "#7c6a52" : "#d9cba3" }
    Rectangle { visible: root.kit === "mechanicus" || root.kit === "ultramarines"; x: root.size * 0.54; y: root.size * 0.55; width: root.size * 0.26; height: root.size * 0.9; rotation: root.kit === "ultramarines" ? -4 : -6; antialiasing: true
        color: root.kit === "ultramarines" ? Theme.metal : "#cbbc92" }
    Shape {
        width: root.size; height: root.size
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.kit === "ultramarines" ? Theme.brassLo : root.kit === "necrons" ? Theme.glowDim : Qt.darker(Theme.wax, 1.6); strokeWidth: root.kit === "necrons" ? 1 : 0.6
            fillGradient: RadialGradient {
                centerX: root.size * 0.38; centerY: root.size * 0.34; centerRadius: root.size * 0.7
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: root.kit === "ultramarines" ? Theme.brassHi : root.kit === "necrons" ? Theme.metalHi : Qt.lighter(Theme.wax, 1.6) }
                GradientStop { position: 1; color: root.kit === "ultramarines" ? Theme.brassLo : root.kit === "necrons" ? Theme.metalLo : Qt.darker(Theme.wax, 1.3) }
            }
            PathPolyline {
                // pressed wax (mechanicus), a ten-sided medal (ultramarines), a lozenge cartouche (necrons), a rough brand (khorne)
                path: {
                    const p = [], c = root.size / 2, k = root.kit
                    const n = k === "ultramarines" ? 10 : k === "necrons" ? 4 : 40
                    for (let i = 0; i <= n; i++) {
                        const a = i / n * Math.PI * 2 - Math.PI / 2
                        const r = c * (k === "ultramarines" ? 0.94 : k === "necrons" ? 0.98 : k === "khorne" ? 0.86 + 0.13 * Math.sin(a * 5 + 1) * Math.cos(a * 3) : 0.9 + 0.08 * Math.sin(a * 9))
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
        color: root.kit === "ultramarines" ? Theme.metalLo : root.kit === "necrons" ? Theme.glow : "#ffd9cc"
        font { family: Theme.fontNum; pixelSize: root.size * 0.5; weight: Font.Bold }
        renderType: Text.NativeRendering
    }
}
