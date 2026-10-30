// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Text on the type scale. Labels and body use Plex Sans; titles and numbers use Plex Sans Condensed.
//   label, labelStrong, body, bodyStrong, title, headline, number, numberL, numberXL
Text {
    property string role: "body"
    readonly property var scale: ({
        label:       { f: Theme.fontUi,  s: 12, w: Font.Normal },
        labelStrong: { f: Theme.fontUi,  s: 12, w: Font.Medium },
        body:        { f: Theme.fontUi,  s: 14, w: Font.Normal },
        bodyStrong:  { f: Theme.fontUi,  s: 14, w: Font.Medium },
        title:       { f: Theme.fontNum, s: 20, w: Font.DemiBold },
        headline:    { f: Theme.fontNum, s: 26, w: Font.DemiBold },
        number:      { f: Theme.fontNum, s: 15, w: Font.DemiBold },
        numberL:     { f: Theme.fontNum, s: 28, w: Font.DemiBold },
        numberXL:    { f: Theme.fontNum, s: 44, w: Font.Medium }
    })
    readonly property var spec: scale[role] ?? scale.body
    color: Theme.surfaceOn
    renderType: Text.NativeRendering
    font { family: spec.f; pixelSize: spec.s; weight: spec.w }
}
