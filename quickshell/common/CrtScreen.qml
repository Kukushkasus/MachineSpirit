// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// Cogitator screen: dark glass, faint scanlines, vignette. Put glowing content inside.
Item {
    id: root
    default property alias content: inner.data
    property real radius: 6
    property real padding: 8
    property bool scanlines: true
    property bool bootOnLoad: true     // play the power-on effect when created
    readonly property alias inner: inner
    // a live screen: now and then it flickers like a lamp or a scan wave rolls down it. Turn off where the
    // screen is only a background and a Flicker sits on top of the content instead.
    property bool ambient: true

    // power-on: the picture opens from a bright horizontal line, then a scanline sweeps down
    property real boot: 1
    function powerOn() { if (!Theme.motionEnabled) return; bootAnim.restart() }
    Component.onCompleted: if (bootOnLoad) powerOn()
    SequentialAnimation {
        id: bootAnim
        NumberAnimation { target: root; property: "boot"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: sweep; property: "y"; from: 0; to: root.height; duration: 380; easing.type: Easing.InOutSine }
    }

    Rectangle {   // recessed glass
        anchors.fill: parent
        radius: root.radius
        color: Theme.glass
        border { width: 1; color: Qt.alpha(Theme.metalLo, 0.9) }
    }
    Shape {       // vignette: lighter centre, dark rim
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
    Item {
        id: inner
        anchors { fill: parent; margins: root.padding }
        opacity: Math.min(1, root.boot * 1.6)
        transform: Scale { origin.y: inner.height / 2; yScale: Math.max(0.02, root.boot) }
    }
    Rectangle {   // the power-on line
        anchors.verticalCenter: parent.verticalCenter
        x: root.width * 0.5 * (1 - Math.min(1, root.boot * 3)); width: root.width * Math.min(1, root.boot * 3)
        height: 2; color: Theme.glow
        opacity: root.boot < 1 ? 1 - root.boot : 0
    }
    Rectangle { id: sweep; width: root.width; height: 3; y: root.height + 4; color: Qt.alpha(Theme.glow, 0.18); visible: bootAnim.running }
    Image {       // scanlines over the content
        visible: root.scanlines
        anchors { fill: parent; margins: 1 }
        source: Qt.resolvedUrl("../assets/scanlines.svg")
        fillMode: Image.Tile
        opacity: 0.22
        smooth: false
    }
    Flicker { anchors.fill: parent; radius: root.radius; active: root.ambient }
    Rectangle {   // glass sheen
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
        height: parent.height * 0.4; radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.05) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
