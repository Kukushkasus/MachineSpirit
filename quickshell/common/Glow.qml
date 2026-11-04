// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Effects
import qs.common

// Phosphor text: glow colour plus a soft halo. Use on cogitator screens.
Text {
    textFormat: Text.PlainText
    id: root
    property real halo: 0.6
    color: Theme.glow
    font { family: Theme.fontNum; pixelSize: 14; weight: Font.Medium }
    renderType: Text.NativeRendering
    layer.enabled: halo > 0 && !Theme.lowPower
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.color
        shadowBlur: 0.5
        shadowOpacity: root.halo
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        autoPaddingEnabled: true
    }
}
