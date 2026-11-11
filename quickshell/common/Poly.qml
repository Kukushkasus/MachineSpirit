// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import QtQuick.Shapes
import qs.common

// A closed polygon with a vertical gradient fill and an optional stroke. The cut-cornered liveries draw
// their plates, rims and glass with it. `points` are [x, y] pairs in the item's own coordinates.
Shape {
    id: root
    property var points: []
    property color upper: "transparent"
    property color lower: upper
    property color stroke: "transparent"
    property real strokeWidth: 1
    // a horizontal gradient instead (left to right)
    property bool across: false
    preferredRendererType: Shape.CurveRenderer
    enabled: false
    readonly property var closed: points && points.length ? points.concat([points[0]]).map(p => Qt.point(p[0], p[1])) : []
    ShapePath {
        strokeColor: root.stroke
        strokeWidth: root.stroke.a > 0 ? root.strokeWidth : -1
        joinStyle: ShapePath.MiterJoin
        fillGradient: LinearGradient {
            x1: 0; y1: 0; x2: root.across ? root.width : 0; y2: root.across ? 0 : root.height
            GradientStop { position: 0; color: root.upper }
            GradientStop { position: 1; color: root.lower }
        }
        PathPolyline { path: root.closed }
    }
}
