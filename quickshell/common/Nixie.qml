// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Nixie-tube style readout: unlit ghost digits behind lit ones, warm halo.
Item {
    id: root
    property string text: "00:00"
    property int size: 22
    // shown text; on change the cathodes flicker through a few digits first
    property string shownText: text
    property int flick: 0
    onTextChanged: {
        // only flicker when more than the last digit moved (minutes, not every second)
        let diff = 0
        for (let i = 0; i < text.length; i++) if (text[i] !== shownText[i]) diff = text.length - i
        if (Theme.lowPower || diff <= 1) { flicker.stop(); shownText = text; return }
        flick = 3; flicker.restart()
    }
    Timer {
        id: flicker; interval: 40; repeat: true
        onTriggered: {
            if (root.flick-- <= 0) { root.shownText = root.text; stop(); return }
            let s = ""
            for (let i = 0; i < root.text.length; i++) {
                const c = root.text[i], o = root.shownText[i] ?? c
                s += (/[0-9]/.test(c) && c !== o) ? String(Math.floor(Math.random() * 10)) : c
            }
            root.shownText = s
        }
    }
    implicitWidth: lit.implicitWidth
    implicitHeight: lit.implicitHeight

    Text {   // unlit cathodes
        anchors.fill: lit
        text: root.text.replace(/[0-9]/g, "8")
        color: Qt.alpha(Theme.glowFaint, 0.35)
        font: lit.font
        renderType: Text.NativeRendering
    }
    Glow {
        id: lit
        text: root.shownText
        halo: 0.9
        font { family: Theme.fontNum; pixelSize: root.size; weight: Font.Medium; letterSpacing: 1 }
    }
}
