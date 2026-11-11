// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// A fastener, by faction: a slotted round-head bolt (mechanicus), a hex bolt (ultramarines),
// a small lit node (necrons), a pyramid stud (khorne).
Item {
    id: root
    property real size: 6
    property real angle: 30
    width: size; height: size
    property string kit: Skin.frame
    function ring(n, turn) {
        const p = [], c = size / 2, r = size / 2 - 0.4
        for (let i = 0; i <= n; i++) { const a = (i / n) * Math.PI * 2 + turn; p.push(Qt.point(c + Math.cos(a) * r, c + Math.sin(a) * r)) }
        return p
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.kit === "necrons" ? Qt.alpha(Theme.glowDim, 0.8) : Qt.darker(Theme.brassLo, 1.4); strokeWidth: 0.6
            fillGradient: RadialGradient {
                centerX: root.size * 0.35; centerY: root.size * 0.3; centerRadius: root.size * 0.7
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: root.kit === "necrons" ? Theme.metalHi : Theme.brassHi }
                GradientStop { position: 1; color: root.kit === "necrons" ? Theme.metalLo : Theme.brassLo }
            }
            PathPolyline { path: root.kit === "ultramarines" ? root.ring(6, Math.PI / 6) : root.kit === "necrons" ? root.ring(4, 0) : root.kit === "khorne" ? root.ring(4, Math.PI / 4) : root.ring(24, 0) }
        }
    }
    Rectangle {   // the slot
        visible: root.kit === "mechanicus"
        anchors.centerIn: parent
        width: root.size * 0.62; height: Math.max(0.8, root.size * 0.12)
        rotation: root.angle
        color: Qt.alpha(Theme.metalLo, 0.85)
    }
    Rectangle {   // hex socket / node core / stud peak
        visible: root.kit !== "mechanicus"
        anchors.centerIn: parent
        width: root.size * (root.kit === "khorne" ? 0.22 : 0.34); height: width; radius: root.kit === "khorne" ? 0 : width / 2
        rotation: root.kit === "khorne" ? 45 : 0
        color: root.kit === "necrons" ? Theme.glow : root.kit === "khorne" ? Theme.brassHi : Qt.alpha(Theme.metalLo, 0.8)
    }
}
