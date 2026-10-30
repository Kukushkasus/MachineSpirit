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
        model: root.count
        Item {
            id: key
            required property int index
            readonly property int wsId: root.first + index
            readonly property bool focused: root.cur === wsId
            readonly property bool occupied: Hyprland.toplevels.values.some(t => (t.workspace?.id ?? -1) === wsId)
            width: 23; height: 24
            onFocusedChanged: if (focused && Theme.motionEnabled) thunk.restart()
            SequentialAnimation { id: thunk
                NumberAnimation { target: key; property: "scale"; to: 0.88; duration: 70 }
                NumberAnimation { target: key; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutBack } }
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {   // only the engaged key has a cap: glass under a brass rim
                anchors.fill: parent
                radius: 5
                color: Theme.glass
                border { width: 1; color: Theme.glow }
                opacity: key.focused ? 1 : (ma.containsMouse ? 0.35 : 0)
                Behavior on opacity { NumberAnimation { duration: Theme.dShort } }
            }
            Glow {
                anchors.centerIn: parent
                text: root.numerals[key.wsId - 1]
                halo: key.focused ? 0.9 : 0
                color: key.focused ? Theme.glow : (key.occupied ? Theme.glowDim : Theme.glowFaint)
                font { family: Theme.fontNum; pixelSize: key.wsId > 6 ? 11 : 13; weight: Font.DemiBold }
            }
            Rectangle {   // something lives here
                visible: key.occupied && !key.focused
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                width: 3; height: 3; radius: 1.5
                color: Theme.glowDim
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
            x: parent.slot * 24 + 7 - root.width
            Behavior on x { enabled: Theme.motionEnabled; SequentialAnimation {
                ScriptAction { script: sparkFade.restart() }
                XAnimator { duration: 240; easing.type: Easing.OutCubic }
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
