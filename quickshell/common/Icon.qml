// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Material Symbols glyph by ligature name, e.g. "volume_up". Grey unless told otherwise.
Text {
    property string name: ""
    property int size: 20
    property bool fill: false
    text: name
    color: Theme.surfaceVariantOn
    font { family: Skin.fontIcon; pixelSize: size; variableAxes: { "FILL": fill ? 1 : 0, "wght": Skin.iconWeight, "opsz": Math.min(48, Math.max(20, size)) } }
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
}
