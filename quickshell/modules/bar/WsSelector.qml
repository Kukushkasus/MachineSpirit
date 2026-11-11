// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell.Hyprland
import QtQuick
import qs.common

// Selector switch: a row of keys engraved with Roman numerals. The current one is pressed in and lit;
// a dot under a key means windows live there. Click a key or roll the wheel to switch.
Row {
    id: root
    spacing: 1
    property int first: 1
    property int count: Theme.workspaces
    readonly property var numerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    property int cur: Hyprland.focusedWorkspace?.id ?? 1
    property int target: cur
    function go(n) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + n + " })") }
    Timer { id: settle; interval: 700; onTriggered: root.target = root.cur }
    function roll(event) {
        const base = settle.running ? target : cur
        const next = Math.max(1, Math.min(Theme.workspaces, base + (event.angleDelta.y > 0 ? -1 : 1)))
        settle.restart()
        if (next !== base) { target = next; go(next) }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspacev2") {
                root.cur = parseInt(event.data.split(",")[0])
                if (!settle.running) root.target = root.cur
            }
        }
    }

    Repeater {
        id: keys
        model: root.count
        Item {
            id: key
            required property int index
            readonly property int wsId: root.first + index
            readonly property bool focused: root.cur === wsId
            readonly property bool occupied: Hyprland.toplevels.values.some(t => (t.workspace?.id ?? -1) === wsId)
            width: Math.max(23, numeral.implicitWidth + 9); height: 24
            onFocusedChanged: if (focused && Theme.motionEnabled) thunk.restart()
            SequentialAnimation { id: thunk
                NumberAnimation { target: key; property: "scale"; to: 0.88; duration: 70 }
                NumberAnimation { target: key; property: "scale"; to: 1; duration: Theme.dMedium; easing.type: Easing.OutCubic } }
            anchors.verticalCenter: parent.verticalCenter

            Mark { anchors.fill: parent; focused: key.focused; hovered: ma.containsMouse; occupied: key.occupied }
            Glow {
                id: numeral
                anchors.centerIn: parent
                // Roman numerals, except on necron glass, which counts in its own wide figures
                text: Skin.glyph === "necrons" ? String(key.wsId % 10) : root.numerals[key.wsId - 1]
                halo: key.focused && Skin.glyph !== "ultramarines" ? 0.9 : 0
                // the gold shield takes dark engraving
                color: key.focused ? (Skin.glyph === "ultramarines" ? Qt.darker(Theme.brassLo, 1.9) : Skin.glyph === "khorne" ? Theme.brassHi : Theme.glow)
                     : (key.occupied ? Theme.glowDim : Theme.glowFaint)
                font { family: Skin.glyph === "mechanicus" ? Theme.fontNum : Skin.display(numeral.text); pixelSize: Skin.glyph === "necrons" ? 10 : 12
                       weight: Skin.glyph === "khorne" ? Font.Black : Font.DemiBold }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.go(key.wsId); onWheel: event => root.roll(event) }
        }
    }

    // a spark runs along the bottom rim from the old key to the new one
    Item {
        width: 0; height: 24
        anchors.verticalCenter: parent.verticalCenter
        readonly property int slot: root.cur - root.first
        visible: slot >= 0 && slot < root.count
        Rectangle {
            id: spark
            y: parent.height + 2; width: 8; height: 2; radius: 1
            color: Theme.glow
            opacity: 0
            x: (keys.itemAt(parent.slot)?.x ?? 0) + ((keys.itemAt(parent.slot)?.width ?? 23) - width) / 2 - root.width
            Behavior on x { enabled: Theme.motionEnabled; SequentialAnimation {
                ScriptAction { script: sparkFade.restart() }
                XAnimator { duration: Theme.dLong; easing.type: Easing.OutCubic }
            } }
            Rectangle { anchors.centerIn: parent; width: 16; height: 5; radius: 2.5; color: Theme.glow; opacity: 0.25 }
            SequentialAnimation {
                id: sparkFade
                OpacityAnimator { target: spark; from: 0; to: 1; duration: 60 }
                PauseAnimation { duration: 160 }
                OpacityAnimator { target: spark; from: 1; to: 0; duration: 260 }
            }
        }
    }
}
