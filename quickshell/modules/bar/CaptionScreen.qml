// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common

// What has focus: the machine's name above, its title below. No screen, just engraved text by the cog.
Item {
    id: root
    readonly property var win: ToplevelManager.activeToplevel
    readonly property bool hasWin: (win?.title ?? "") !== ""
    readonly property var numerals: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
    property int maxWidth: 300
    implicitWidth: Math.min(maxWidth, Math.max(top.implicitWidth, bottom.implicitWidth))
    implicitHeight: 28
    // one line in the faction's voice when the shell starts, for a few seconds; then the caption is the caption again
    property bool greet: false
    readonly property string greeting: greet ? Theme.lex("greeting", "") : ""
    // a moment after start, when the pack has been read
    Timer { interval: 1500; running: true; onTriggered: if (Theme.fxOn("messages")) { root.greet = true; greetOff.start() } }
    Timer { id: greetOff; interval: 6000; onTriggered: root.greet = false }
    Glow {
        id: top
        y: -1; width: root.width; elide: Text.ElideRight
        halo: 0; color: Theme.glowDim
        font { family: Theme.fontNum; pixelSize: 11; weight: Font.DemiBold }
        text: root.hasWin ? (root.win.appId || "machine") : "Sector " + root.numerals[Math.max(0, (Hyprland.focusedWorkspace?.id ?? 1) - 1)]
    }
    Glow {
        id: bottom
        y: 12; width: root.width; elide: Text.ElideRight
        halo: 0
        font { family: Theme.fontNum; pixelSize: 13; weight: Font.Medium }
        textFormat: Text.PlainText
        text: root.greeting !== "" ? root.greeting : root.hasWin ? root.win.title : Theme.kit === "mechanicus" ? "No machine in focus" : "Nothing in focus"
    }
}
