// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// The moment a large window arrives, drawn over its housing by faction. It runs once per opening (about half a second),
// costs nothing at rest and never holds back the window's controls: they take input from the first frame.
//   mechanicus    current runs out from the crown along the frame in two crackling points and earths at the feet
//   ultramarines  a gold pulse travels the trim, left to right along the top and back along the foot, then the rim answers
//   necrons       a phase line scans down the glass while glyphs flare and fade along its path
//   khorne        a sheen of heat sweeps across the iron and the plate throws sparks where it lands
// Put it over the housing (anchors.fill) and call play(). `landed` fires when a heavy window touches down.
Item {
    id: root
    property string kit: Theme.kit
    property real radius: 10
    property real delay: 0               // ms after play() before the effect starts (to follow a slide)
    signal landed()
    enabled: false                       // decorative: never takes input
    visible: run.running || play0.running
    readonly property bool on: Theme.arrivals

    function play() {
        if (!on || width < 40 || height < 40) { if (Theme.motionEnabled && kit === "khorne") landed(); return }
        armed = true
        run.stop(); p = 0; q = 0; flash = 0
        glyphSeed = Math.random() * 1000
        play0.restart()
    }
    function stop() { play0.stop(); run.stop(); p = 0; q = 0; flash = 0 }
    Timer { id: play0; interval: Math.max(1, root.delay); onTriggered: run.restart() }

    property real p: 0        // main travel 0..1
    property real q: 0        // second phase 0..1
    property real flash: 0    // rim answer
    property real glyphSeed: 0
    // a faction's layer is built the first time this window arrives, and only that faction's
    property bool armed: false

    SequentialAnimation {
        id: run
        ParallelAnimation {
            NumberAnimation { target: root; property: "p"; from: 0; to: 1
                duration: root.kit === "necrons" ? 620 : root.kit === "khorne" ? 560 : root.kit === "ultramarines" ? 520 : 460
                easing.type: root.kit === "ultramarines" ? Easing.InOutQuart : root.kit === "necrons" ? Easing.InOutSine : root.kit === "khorne" ? Easing.OutCubic : Easing.OutQuad }
            SequentialAnimation {
                PauseAnimation { duration: root.kit === "khorne" ? 30 : 200 }
                ScriptAction { script: if (root.kit === "khorne") root.landed() }
                NumberAnimation { target: root; property: "q"; from: 0; to: 1; duration: root.kit === "ultramarines" ? 420 : 380; easing.type: Easing.InOutCubic }
            }
        }
        ScriptAction { script: { if (root.kit === "mechanicus") root.landed() } }
        NumberAnimation { target: root; property: "flash"; from: 1; to: 0; duration: root.kit === "ultramarines" ? 420 : 300; easing.type: Easing.OutQuad }
    }

    // ---- a point running along the frame: from the top centre (d 0) round to the bottom corner (d 1), on either side
    component Runner: Item {
        id: rn
        property real d: 0          // 0..1 along half the perimeter
        property bool east: true
        property color tone: Theme.spark
        property real size: 6
        property real jitter: 0
        readonly property real half: root.width / 2
        readonly property real len: half + root.height
        readonly property real s: d * len
        x: (s < half ? (east ? half + s : half - s) : (east ? root.width : 0)) - size / 2
        y: (s < half ? 0 : Math.min(root.height, s - half)) - size / 2 + jitter
        width: size; height: size
        Rectangle { anchors.centerIn: parent; width: rn.size * 3.2; height: width; radius: width / 2; color: Qt.alpha(rn.tone, 0.18) }
        Rectangle { anchors.centerIn: parent; width: rn.size * 1.8; height: width; radius: width / 2; color: Qt.alpha(rn.tone, 0.4) }
        Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.lighter(rn.tone, 1.6) }
    }

    // ---------------- mechanicus: two crackling points of current, a trail of afterglow, a flash where they earth
    Loader {
        anchors.fill: parent
        active: root.armed && root.kit === "mechanicus"
        sourceComponent: Component { Item {
        anchors.fill: parent
        Repeater {   // a head and a streak of afterglow on either side
            model: root.kit === "mechanicus" ? 18 : 0
            Runner {
                required property int index
                east: index % 2 === 0
                readonly property int k: Math.floor(index / 2)
                d: Math.max(0, root.p - k * 0.011)
                size: k === 0 ? 7 : Math.max(2, 5 - k * 0.4)
                opacity: (root.p > 0.02 && root.p < 0.995 ? 1 : 0) * (1 - k * 0.1) * (0.7 + 0.3 * Math.sin(root.p * 90 + index))
                tone: Theme.spark
                jitter: k === 0 ? Math.sin(root.p * 140 + index) * 1.6 : 0
            }
        }
        Rectangle {   // the frame lights for a moment as the current earths
            anchors.fill: parent; radius: root.radius; color: "transparent"
            border { width: 1.5; color: Theme.spark }
            opacity: root.flash * 0.55
        }
    } } }

    // ---------------- ultramarines: a disciplined gold pulse along the trim, then the whole rim answers
    Loader {
        anchors.fill: parent
        active: root.armed && root.kit === "ultramarines"
        sourceComponent: Component { Item {
        anchors.fill: parent
        clip: true
        Rectangle {   // along the top, left to right
            y: 0; height: 2; width: Math.max(60, root.width * 0.22)
            x: -width + root.p * (root.width + width)
            opacity: root.p > 0 && root.p < 1 ? 1 : 0
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.8; color: Theme.brassHi } GradientStop { position: 1; color: "#ffffff" } }
        }
        Rectangle {   // along the foot, right to left
            y: root.height - 2; height: 2; width: Math.max(60, root.width * 0.22)
            x: root.width - root.q * (root.width + width)
            opacity: root.q > 0 && root.q < 1 ? 1 : 0
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#ffffff" } GradientStop { position: 0.2; color: Theme.brassHi } GradientStop { position: 1; color: "transparent" } }
        }
        Rectangle {
            anchors.fill: parent; radius: root.radius; color: "transparent"
            border { width: 1; color: Theme.brassHi }
            opacity: root.flash * 0.6
        }
    } } }

    // ---------------- necrons: a phase line scans down; glyphs flare where it passes
    Loader {
        anchors.fill: parent
        active: root.armed && root.kit === "necrons"
        sourceComponent: Component { Item {
        anchors.fill: parent
        clip: true
        Rectangle {   // the wake above the line
            width: parent.width; height: 90
            y: root.p * (root.height + 20) - height
            opacity: root.p > 0 && root.p < 1 ? 0.5 : 0
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha(Theme.glow, 0.22) } }
        }
        Rectangle {
            width: parent.width; height: 1.5
            y: root.p * (root.height + 20) - 1
            opacity: root.p > 0 && root.p < 1 ? 1 : 0
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.2; color: Theme.glow }
                GradientStop { position: 0.5; color: Qt.lighter(Theme.glow, 1.5) } GradientStop { position: 0.8; color: Theme.glow }
                GradientStop { position: 1; color: "transparent" } }
        }
        Repeater {   // glyphs along the margins, each lit as the line reaches it
            model: root.kit === "necrons" ? 7 : 0
            Item {
                required property int index
                readonly property real fy: ((index * 0.137 + root.glyphSeed * 0.001) % 1) * 0.86 + 0.07
                readonly property bool west: index % 2 === 0
                readonly property real lit: Math.max(0, 1 - Math.abs(root.p * 1.02 - fy) * 7)
                x: west ? 10 + (index % 3) * 4 : root.width - 22 - (index % 3) * 4; y: fy * root.height - 6
                width: 12; height: 12
                opacity: lit
                Poly { anchors.fill: parent; points: index % 3 === 0 ? [[6, 0], [12, 12], [0, 12]] : index % 3 === 1 ? [[0, 0], [12, 0], [6, 12]] : [[6, 0], [12, 6], [6, 12], [0, 6]]
                    upper: Qt.lighter(Theme.glow, 1.3); lower: Theme.glow }
            }
        }
        Rectangle {
            anchors.fill: parent; radius: root.radius; color: "transparent"
            border { width: 1; color: Theme.glow }
            opacity: root.flash * 0.45
        }
    } } }

    // ---------------- khorne: heat sweeps across the iron; sparks fly where the plate lands
    Loader {
        anchors.fill: parent
        active: root.armed && root.kit === "khorne"
        sourceComponent: Component { Item {
        anchors.fill: parent
        clip: true
        Rectangle {
            width: root.width * 0.5; height: root.height * 2.2
            rotation: 18; transformOrigin: Item.Center
            x: -width + root.q * (root.width + width * 1.4); y: -root.height * 0.6
            opacity: root.q > 0 && root.q < 1 ? 0.55 : 0
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.45; color: Qt.alpha(Theme.rust, 0.25) }
                GradientStop { position: 0.55; color: Qt.alpha("#ffb070", 0.32) }
                GradientStop { position: 0.65; color: Qt.alpha(Theme.rust, 0.25) }
                GradientStop { position: 1; color: "transparent" } }
        }
        Rectangle {   // the foot glows red-hot for a moment as it lands
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 26
            opacity: root.p > 0 ? (1 - root.p) * 0.8 : 0
            gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha("#ff6a2a", 0.5) } }
        }
        Sparks { id: sparksL; x: root.width * 0.18; y: root.height - 2; spread: 30; power: 0.8 }
        Sparks { id: sparksR; x: root.width * 0.82; y: root.height - 2; spread: 30; power: 0.8 }
        Connections { target: root; function onLanded() { if (root.on) { sparksL.hiss(); sparksR.hiss() } } }
    } } }

}
