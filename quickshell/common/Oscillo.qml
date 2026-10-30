// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Vector trace of a history array (oldest first) on a faint grid. Optional second trace.
Item {
    id: root
    property var values: []
    property var values2: []
    property real max: 0              // 0 = auto
    property bool grid: true
    property color tone: Theme.glow
    property color tone2: Theme.glowDim
    readonly property real ceiling: {
        if (max > 0) return max
        let m = 1
        for (const v of values) m = Math.max(m, v)
        for (const v of values2) m = Math.max(m, v)
        return m * 1.15
    }
    function pts(arr) {
        const n = Math.max(2, arr.length), out = []
        for (let i = 0; i < arr.length; i++)
            out.push(Qt.point(i / (n - 1) * width, height - Math.min(1, arr[i] / ceiling) * (height - 2) - 1))
        return out
    }
    function area(arr) {
        const p = pts(arr)
        if (p.length === 0) return p
        return [Qt.point(0, height)].concat(p, [Qt.point(p[p.length - 1].x, height)])
    }

    Repeater {   // grid
        model: root.grid ? 3 : 0
        Rectangle { required property int index; x: 0; y: (index + 1) * root.height / 4; width: root.width; height: 1; color: Qt.alpha(root.tone, 0.10) }
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillColor: Qt.alpha(root.tone, 0.16)
            PathPolyline { path: root.area(root.values) }
        }
        ShapePath {
            strokeColor: root.tone; strokeWidth: 1.6
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.pts(root.values) }
        }
        ShapePath {
            strokeColor: root.values2.length > 1 ? root.tone2 : "transparent"; strokeWidth: 1.2
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.pts(root.values2) }
        }
    }
}
