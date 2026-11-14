// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services

Item {
    id: root
    property string title: ""
    property string serial: ""
    property real corner: 12
    property bool quiet: false
    property string housing: "screen"
    property bool loadNoise: false
    default property alias contents: body.data
    Bezel { anchors.fill: parent; radius: root.corner; inset: 0; bolts: false; role: "instrument" }
    CrtScreen { anchors { fill: parent; margins: 5 } radius: Math.max(3, root.corner - 5); padding: 0; ambient: false; loadNoise: root.loadNoise }
    // the mark before the title: an indicator bead, a rank chevron, a lit lozenge, a brass stud
    readonly property string kit: Skin.instrument
    Rectangle { visible: root.kit === "mechanicus"; x: 16; y: 17; width: 4; height: 4; radius: 2; color: Theme.glow }
    Repeater { model: root.kit === "ultramarines" ? 2 : 0
        Rectangle { required property int index; x: 14 + index * 4; y: 15; width: 2; height: 8; rotation: -24; antialiasing: true; color: Theme.brassHi } }
    Rectangle { visible: root.kit === "necrons"; x: 15; y: 16; width: 6; height: 6; rotation: 45; color: "transparent"; border { width: 1; color: Theme.glow }
        Rectangle { anchors.centerIn: parent; width: 2; height: 2; color: Theme.glow } }
    Rectangle { visible: root.kit === "khorne"; x: 15; y: 16; width: 6; height: 6; rotation: 45; color: Theme.brass; border { width: 0.6; color: Theme.brassLo } }
    // the heading in the faction's hand: plain condensed capitals, gold Roman capitals, wide lit letters, brass black-letter
    Text { x: 27; y: root.kit === "khorne" ? 8 : 11; text: root.kit === "khorne" ? root.title : root.title.toUpperCase(); renderType: Text.NativeRendering
        color: root.kit === "ultramarines" || root.kit === "khorne" ? Theme.brassHi : root.kit === "necrons" ? Theme.glow : Theme.glowDim
        font { family: root.kit === "mechanicus" ? Theme.fontNum : Skin.display(root.title); pixelSize: root.kit === "khorne" ? 15 : root.kit === "necrons" ? 9 : 11
               weight: root.kit === "khorne" ? Font.Black : root.kit === "ultramarines" ? Font.Bold : Font.Normal; letterSpacing: root.kit === "khorne" ? 0.5 : 1.6 } }
    // The serial plate is decoration, so this is where the faction's rare signs appear: for a second or two
    // the mechanicus plate shows a burst of binary, the necron one lets a small sign drift up past it.
    property string sign: ""
    Text { id: serialText; anchors { right: parent.right; rightMargin: 17; top: parent.top; topMargin: 11 } textFormat: Text.PlainText
        text: root.sign !== "" ? root.sign : root.serial; color: root.sign !== "" ? Theme.glowDim : Theme.glowFaint; font { family: Theme.fontNum; pixelSize: 11 } }
    Rectangle { id: mote; visible: moteAnim.running; x: serialText.x - 12; y: 14; width: 5; height: 5; rotation: 45; opacity: 0; color: "transparent"; border { width: 1; color: Theme.glow } }
    ParallelAnimation {
        id: moteAnim
        YAnimator { target: mote; from: 20; to: 8; duration: 2200; easing.type: Easing.InOutSine }
        SequentialAnimation { OpacityAnimator { target: mote; from: 0; to: 0.9; duration: 700 } PauseAnimation { duration: 700 } OpacityAnimator { target: mote; from: 0.9; to: 0; duration: 800 } }
    }
    Timer { id: signOff; interval: 1500; onTriggered: root.sign = "" }
    Timer {
        interval: Theme.fxDelay("glyphs", 90, 240); repeat: true
        running: root.visible && !root.quiet && (root.kit === "mechanicus" || root.kit === "necrons") && Theme.fxOn("glyphs") && Theme.fxOn("messages") && Theme.ornaments > 0 && !DesktopWidgets.editing
        onTriggered: {
            interval = Theme.fxDelay("glyphs", 90, 240)
            if (!Theme.fxClaim(root.kit === "necrons" ? 2200 : 1500)) return
            if (root.kit === "necrons") moteAnim.restart()
            else { let b = ""; for (let i = 0; i < 8; i++) b += Math.random() < 0.5 ? "0" : "1"; root.sign = b; signOff.restart() }
        }
    }
    // the rule under the heading
    Rectangle { x: 16; y: 32; width: parent.width - 32; height: 1
        color: root.kit === "ultramarines" ? Qt.alpha(Theme.brass, 0.55) : root.kit === "khorne" ? Qt.alpha(Theme.brass, 0.35) : Qt.alpha(Theme.glow, root.kit === "necrons" ? 0.4 : 0.16) }
    Rectangle { visible: root.kit === "ultramarines"; x: 16; y: 34; width: 42; height: 1; color: Qt.alpha(Theme.brass, 0.4) }
    Repeater { model: root.kit === "necrons" ? 2 : 0
        Rectangle { required property int index; x: index ? root.width - 19 : 14; y: 30; width: 5; height: 5; rotation: 45; color: Theme.glass; border { width: 1; color: Theme.glowDim } } }
    // necrons: a conduit down the left edge of the glass, lit part of the way
    Rectangle { visible: root.kit === "necrons" && Theme.ornaments > 0; x: 9; y: 44; width: 1.5; height: Math.max(0, root.height * 0.45 - 30); color: Qt.alpha(Theme.glowDim, 0.6) }
    // khorne: wear. Three dragged streaks in a lower corner, dark and faint, under the readings' margin.
    Item {
        visible: root.kit === "khorne" && Theme.ornaments > 1
        readonly property bool onLeft: (root.title.length % 2) === 0
        x: onLeft ? 10 : root.width - 58; y: root.height - 22; width: 48; height: 14; opacity: 0.16; clip: true
        Repeater { model: 3
            Rectangle { required property int index; x: 2 + index * 5; y: 1 + index * 3.6; width: 30 - index * 6; height: 2.6; radius: 1.3; rotation: -7; antialiasing: true; color: Theme.rust } }
    }
    Item { id: body; anchors { fill: parent; leftMargin: 18; rightMargin: 18; topMargin: 42; bottomMargin: 15 } }
    // vents on the receiver, tape feed on the memorandum
    Repeater {
        model: root.housing === "receiver" ? 12 : 0
        Rectangle { required property int index; x: 8; y: 48 + index * 11; width: 3; height: 6; radius: 1; color: Theme.metalLo }
    }
    Repeater {
        model: root.housing === "tape" ? 2 : 0
        Rectangle { required property int index; x: 5; y: index === 0 ? 34 : root.height - 12; width: root.width - 10; height: 5; radius: 2
            color: Theme.metalLo
            Rectangle { x: 9; y: 1; width: parent.width - 18; height: 1; color: Theme.metalHi }
        }
    }
    // a faint scan every minute or two, not over the note while typing
    Rectangle {
        id: scan; x: 7; y: -20; width: parent.width - 14; height: 16
        visible: sweep.running; color: Qt.alpha(Theme.glow, 0.025)
    }
    NumberAnimation { id: sweep; target: scan; property: "y"; from: 35; to: root.height - 22; duration: 650 }
    Timer { interval: 60000 + Math.random() * 60000; repeat: true; running: root.visible && !root.quiet && Theme.fxOn("screenLife") && Settings.data.widgetScan !== false && !DesktopWidgets.editing
        onTriggered: { if (Theme.fxClaim(650)) sweep.restart(); interval = 60000 + Math.random() * 60000 } }
}
