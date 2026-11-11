// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import QtQuick.Shapes
import qs.common

// Open strokes: `lines` is a list of [x1, y1, x2, y2] or longer polylines [x1, y1, x2, y2, x3, y3, ...].
// For engraved rules, glyphs and energy lines. `unit` scales the coordinates (glyphs are drawn on a 10 grid).
Shape {
    id: root
    property var lines: []
    property color color: Theme.glow
    property real lineWidth: 1
    property real unit: 1
    property bool round: true
    preferredRendererType: Shape.CurveRenderer
    enabled: false
    ShapePath {
        strokeColor: root.color
        strokeWidth: root.lineWidth
        fillColor: "transparent"
        capStyle: root.round ? ShapePath.RoundCap : ShapePath.FlatCap
        joinStyle: ShapePath.MiterJoin
        PathMultiline {
            paths: (root.lines || []).filter(l => l && l.length > 3).map(l => { const r = []; for (let i = 0; i + 1 < l.length; i += 2) r.push(Qt.point(l[i] * root.unit, l[i + 1] * root.unit)); return r })
        }
    }
}
