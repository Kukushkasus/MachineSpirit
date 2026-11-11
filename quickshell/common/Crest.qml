// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// The shell's own crest: a skull set in a cog, borne on forged wings. Drawn here from scratch; it is not
// and must not become a copy of anyone's emblem. Everything is laid out on a 58 px tall grid and scaled.
Item {
    id: root
    height: 58
    width: height * 4.5
    readonly property real s: height / 58
    readonly property real cx: 130.5    // grid centre (261 wide)
    readonly property real cy: 29
    readonly property color bone: Qt.lighter(Theme.metalEdge, 1.45)

    function f(n) { return n.toFixed(2) }
    // one feather as a leaf: root, a bulging upper edge to the tip, a fuller lower edge back
    function feather(dir, rx, ry, deg, len, w) {
        const a = deg * Math.PI / 180, dx = Math.cos(a) * dir, dy = Math.sin(a), nx = -dy * dir, ny = dx * dir
        const tx = rx + dx * len, ty = ry + dy * len
        const c1x = rx + dx * len * 0.5 - nx * w, c1y = ry + dy * len * 0.5 - ny * w
        const c2x = rx + dx * len * 0.62 + nx * w * 1.25, c2y = ry + dy * len * 0.62 + ny * w * 1.25
        return "M" + f(rx) + "," + f(ry) + " Q" + f(c1x) + "," + f(c1y) + " " + f(tx) + "," + f(ty) + " Q" + f(c2x) + "," + f(c2y) + " " + f(rx) + "," + f(ry) + " Z "
    }
    function quill(dir, rx, ry, deg, len) {
        const a = deg * Math.PI / 180
        return "M" + f(rx) + "," + f(ry) + " L" + f(rx + Math.cos(a) * dir * len * 0.86) + "," + f(ry + Math.sin(a) * len * 0.86) + " "
    }
    // rows of a wing: [degrees, length, half width] from the lowest feather up, so upper ones overlap
    readonly property var primaries: [[27, 46, 11], [20, 62, 11.5], [14, 78, 12], [8, 93, 12], [3, 106, 11.5]]
    readonly property var coverts: [[17, 32, 9.5], [10, 42, 10], [4, 52, 10]]
    function row(list, x0, y0, spread, quills) {
        let out = ""
        for (const dir of [-1, 1])
            list.forEach((p, i) => {
                const rx = cx + dir * x0, ry = cy + y0 - i * spread
                out += quills ? quill(dir, rx, ry, p[0], p[1]) : feather(dir, rx, ry, p[0], p[1], p[2])
            })
        return out
    }
    readonly property string cog: {
        const ro = 27.5, ri = 23, n = 14
        let d = ""
        for (let i = 0; i < n; i++) {
            const a = i / n * Math.PI * 2 - Math.PI / 2, w = Math.PI / n
            for (const [ang, r] of [[a - w * 0.6, ri], [a - w * 0.36, ro], [a + w * 0.36, ro], [a + w * 0.6, ri]])
                d += (d === "" ? "M" : "L") + f(cx + Math.cos(ang) * r) + "," + f(cy + Math.sin(ang) * r) + " "
        }
        return d + "Z"
    }

    Rectangle {   // a breath of phosphor behind the cog
        anchors.centerIn: parent; width: root.height * 1.5; height: width; radius: width / 2
        gradient: Gradient { GradientStop { position: 0; color: Qt.alpha(Theme.glow, 0.0) } GradientStop { position: 0.5; color: Qt.alpha(Theme.glow, 0.07) } GradientStop { position: 1; color: Qt.alpha(Theme.glow, 0.0) } }
    }
    Shape {
        width: 261; height: 58
        scale: root.s; transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {   // primaries
            strokeColor: Qt.darker(Theme.metalLo, 1.3); strokeWidth: 0.9
            fillGradient: LinearGradient { x1: 0; y1: 8; x2: 0; y2: 58
                GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 1; color: Theme.metal } }
            PathSvg { path: root.row(root.primaries, 17, 15, 5.6, false) }
        }
        ShapePath {   // their quills
            strokeColor: Qt.alpha(Theme.metalEdge, 0.55); strokeWidth: 0.7; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathSvg { path: root.row(root.primaries, 17, 15, 5.6, true) }
        }
        ShapePath {   // coverts, lighter and shorter, over the roots
            strokeColor: Qt.darker(Theme.metal, 1.3); strokeWidth: 0.9
            fillGradient: LinearGradient { x1: 0; y1: 6; x2: 0; y2: 46
                GradientStop { position: 0; color: root.bone } GradientStop { position: 1; color: Theme.metalHi } }
            PathSvg { path: root.row(root.coverts, 15, 6, 6, false) }
        }
        ShapePath {
            strokeColor: Qt.alpha(Theme.glow, 0.35); strokeWidth: 0.7; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathSvg { path: root.row(root.coverts, 15, 6, 6, true) }
        }
        ShapePath {   // the cog
            strokeColor: Qt.darker(Theme.metalLo, 1.2); strokeWidth: 1; joinStyle: ShapePath.RoundJoin
            fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: 58
                GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 0.5; color: Theme.metalHi } GradientStop { position: 1; color: Theme.metalLo } }
            PathSvg { path: root.cog }
        }
        ShapePath {   // the bevel inside the teeth
            strokeColor: Qt.alpha(Theme.metalLo, 0.9); strokeWidth: 1.2; fillColor: "transparent"
            PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 20.5; radiusY: 20.5; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {   // the dark bore in a phosphor ring
            strokeColor: Qt.alpha(Theme.glow, 0.75); strokeWidth: 1.1
            fillGradient: RadialGradient { centerX: root.cx; centerY: root.cy; centerRadius: 18; focalX: root.cx; focalY: root.cy
                GradientStop { position: 0; color: Qt.tint(Qt.darker(Theme.glass, 1.2), Qt.alpha(Theme.glow, 0.1)) } GradientStop { position: 1; color: Qt.darker(Theme.glass, 1.6) } }
            PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 17.5; radiusY: 17.5; startAngle: 0; sweepAngle: 360 }
        }
    }
    Shape {   // the skull, on a 40 px grid
        x: (root.cx - 20 * 0.66) * root.s; y: (root.cy - 21.5 * 0.66) * root.s; width: 40; height: 42
        scale: root.s * 0.66; transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {   // cranium, cheekbones and jaw
            strokeColor: Qt.darker(Theme.metalEdge, 1.7); strokeWidth: 1.1; joinStyle: ShapePath.RoundJoin
            fillGradient: LinearGradient { x1: 6; y1: 2; x2: 34; y2: 40
                GradientStop { position: 0; color: root.bone } GradientStop { position: 0.6; color: Theme.metalEdge } GradientStop { position: 1; color: Qt.darker(Theme.metalEdge, 1.35) } }
            PathSvg { path: "M20,2 C30,2 37,9 37,19 C37,24 35.5,27 33.5,29 L32.5,33.5 C32.3,35.6 30.5,36.6 28.4,36.6 L27.4,40.5 L12.6,40.5 L11.6,36.6 C9.5,36.6 7.7,35.6 7.5,33.5 L6.5,29 C4.5,27 3,24 3,19 C3,9 10,2 20,2 Z" }
        }
        ShapePath {   // light on the brow
            strokeColor: Qt.alpha("white", 0.35); strokeWidth: 1.1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathSvg { path: "M8,13 C10,8 14,5.5 19,5" }
        }
        ShapePath {   // sockets under heavy brows, the nose
            strokeColor: "transparent"; fillColor: Qt.darker(Theme.metalLo, 1.9)
            PathSvg { path: "M7.6,20.4 C8.4,16.4 15.6,16.2 17.8,19.6 C18.6,23.2 16,26.4 12.6,26 C9.4,25.6 7.2,23.6 7.6,20.4 Z "
                          + "M32.4,20.4 C31.6,16.4 24.4,16.2 22.2,19.6 C21.4,23.2 24,26.4 27.4,26 C30.6,25.6 32.8,23.6 32.4,20.4 Z "
                          + "M20,25.4 C18.8,27.6 17.6,30 17.4,31.6 L20,30.4 L22.6,31.6 C22.4,30 21.2,27.6 20,25.4 Z" }
        }
        ShapePath {   // cheek hollows and teeth
            strokeColor: Qt.darker(Theme.metalEdge, 1.9); strokeWidth: 0.9; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathSvg { path: "M8.4,30 C9.6,31.2 10.6,32.8 11,34.4 M31.6,30 C30.4,31.2 29.4,32.8 29,34.4 "
                          + "M12.4,35.6 L27.6,35.6 M14.8,33.6 L14.8,40 M17.4,33.8 L17.4,40.2 M20,34 L20,40.4 M22.6,33.8 L22.6,40.2 M25.2,33.6 L25.2,40" }
        }
    }
    // phosphor in the sockets
    Repeater {
        model: 2
        Rectangle {
            required property int index
            x: (root.cx + (index === 0 ? -4.7 : 4.7)) * root.s - width / 2; y: (root.cy - 0.4) * root.s - height / 2
            width: 2.6 * root.s; height: width; radius: width / 2; color: Theme.glow
            Rectangle { anchors.centerIn: parent; width: parent.width * 2.3; height: width; radius: width / 2; color: Qt.alpha(Theme.glow, 0.22) }
        }
    }
}
