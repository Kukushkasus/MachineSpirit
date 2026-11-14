// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// Mechanicus glass: cogitator CRT. Under the content: recessed glass and vignette. Over it: power-on line,
// scanlines (thicker under real load on the Cogitator) and tube sheen
Item {
    id: root
    required property Item host
    required property bool over
    readonly property real radius: host.radius

    Rectangle {   // recessed glass
        visible: !root.over
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(Theme.glass, Theme.panelOpacity)
        border { width: 1; color: Qt.alpha(Theme.metalLo, 0.9) }
    }
    Shape {       // vignette: lighter centre, dark rim
        visible: !root.over
        anchors { fill: parent; margins: 1 }
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.width / 2; centerY: root.height * 0.45
                centerRadius: Math.max(root.width, root.height) * 0.7
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: Qt.alpha(Theme.glowFaint, 0.18) }
                GradientStop { position: 1; color: Qt.alpha("black", 0.35) }
            }
            startX: root.radius; startY: 0
            PathLine { x: root.width - 2 - root.radius; y: 0 }
            PathArc { x: root.width - 2; y: root.radius; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: root.width - 2; y: root.height - 2 - root.radius }
            PathArc { x: root.width - 2 - root.radius; y: root.height - 2; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: root.radius; y: root.height - 2 }
            PathArc { x: 0; y: root.height - 2 - root.radius; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: 0; y: root.radius }
            PathArc { x: root.radius; y: 0; radiusX: root.radius; radiusY: root.radius }
        }
    }
    Rectangle {   // the power-on line
        visible: root.over && root.host.boot < 1
        anchors.verticalCenter: parent.verticalCenter
        x: root.width * 0.5 * (1 - Math.min(1, root.host.boot * 3)); width: root.width * Math.min(1, root.host.boot * 3)
        height: 2; color: Theme.glow
        opacity: 1 - root.host.boot
    }
    Rectangle {   // the sweep after power-on
        visible: root.over && root.host.booting
        width: root.width; height: 3
        y: root.host.sweep * root.height
        color: Qt.alpha(Theme.glow, 0.18)
    }
    Image {       // scanlines; noise under load thickens them a little, the text is never moved
        visible: root.over && root.host.scanlines
        anchors { fill: parent; margins: 1 }
        source: Qt.resolvedUrl("../../assets/scanlines.svg")
        fillMode: Image.Tile
        opacity: 0.22 + (root.host.loadNoise && Theme.fxOn("screenLife") ? Math.max(0, Math.min(0.16, (Sys.cpu - 0.6) * 0.4)) : 0)
        Behavior on opacity { NumberAnimation { duration: 600 } }
        smooth: false
    }
    Rectangle {   // glass sheen
        visible: root.over
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
        height: parent.height * 0.4; radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.05) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
