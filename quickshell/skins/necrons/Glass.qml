// [ PURITY SEAL ] The metal remembers.
import QtQuick
import qs.common

// Necron glass: phase glass, nearly black, cut to the monolith's outline. Circuit traces run faint in it,
// a cold light rises from below, a band of light hangs a third of the way down, and a column of glyphs is
// set into the left margin of a tall screen. It wakes with a green wash instead of switching on.
Item {
    id: root
    required property Item host
    required property bool over
    readonly property real c: Math.max(3, host.radius * 1.1)
    readonly property bool big: width > 90 && height > 60

    Poly {   // the glass
        visible: !root.over
        anchors.fill: parent
        points: Skin.monolith(width, height, root.c, false)
        upper: Qt.alpha(Qt.darker(Theme.glass, 1.35), Theme.panelOpacity)
        lower: Qt.alpha(Qt.tint(Theme.glass, Qt.alpha(Theme.glowFaint, 0.22)), Theme.panelOpacity)
        stroke: Qt.alpha(Theme.glowDim, 0.4); strokeWidth: 1
    }
    Rectangle {   // a band of light hanging in the glass
        visible: !root.over && root.big
        x: root.c * 0.5; width: root.width - root.c; y: root.height * 0.28; height: Math.min(80, root.height * 0.18)
        gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Qt.alpha(Theme.glowFaint, 0.10) } GradientStop { position: 1; color: "transparent" } }
    }
    Image {   // circuit traces
        visible: root.over && root.host.scanlines
        anchors { fill: parent; margins: root.c * 0.5 }
        source: Qt.resolvedUrl("../../assets/traces.svg")
        fillMode: Image.Tile; smooth: false
        opacity: 0.07
    }
    Rectangle {   // the cold light rising from below
        visible: root.over
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: root.c * 0.4 }
        height: parent.height * 0.3
        gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha(Theme.glowFaint, 0.28) } }
    }
    Column {   // glyphs in the left margin of a tall screen
        visible: root.over && root.big && root.height > 220 && Theme.ornaments > 0
        x: 3; y: root.c * 1.6 + 18; spacing: 12
        Repeater {
            model: Math.max(0, Math.min(9, Math.floor((root.height * 0.55) / 18)))
            Strokes {
                required property int index
                width: 6; height: 6; unit: 0.6; lineWidth: 0.9
                color: Qt.alpha(Theme.glow, 0.22)
                lines: Skin.glyphs[(index * 5 + Math.round(root.width)) % Skin.glyphs.length]
            }
        }
    }
    Rectangle {   // the glass waking
        visible: root.over && root.host.boot < 1
        anchors { fill: parent; margins: 1 }
        color: Theme.glowFaint; opacity: (1 - root.host.boot) * 0.35
    }
}
