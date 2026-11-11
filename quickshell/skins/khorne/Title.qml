// [ PURITY SEAL ] Iron does not bend.
import QtQuick
import qs.common

// Khorne title: heavy black-letter in brass between two iron bars, each bar cut into a row of teeth along
// its underside and ending in a blade.
Item {
    id: root
    required property Item host
    // black-letter reads best in mixed case
    readonly property string words: root.host.text.toLowerCase().replace(/(^|\s)\S/g, m => m.toUpperCase())
    Glow {
        id: title
        anchors.centerIn: parent
        text: Skin.display(root.words) === Theme.fontNum ? root.host.text : root.words
        color: Theme.brassHi; halo: 0.35
        font { family: Skin.display(root.words); pixelSize: Math.round(root.host.pixelSize * (Skin.display(root.words) === Theme.fontNum ? 1 : 1.45)); weight: Font.Black; letterSpacing: 1.5 }
    }
    Repeater {
        model: 2
        Poly {
            required property int index
            readonly property bool l: index === 0
            anchors.verticalCenter: parent.verticalCenter
            x: l ? 0 : title.x + title.width + 12
            width: Math.max(0, title.x - 12); height: 9
            points: {
                const w = width, p = l ? [[0, 4], [10, 1], [w, 1], [w, 4]] : [[0, 4], [0, 1], [w - 10, 1], [w, 4]]
                // teeth along the underside, right to left, clear of the blade
                for (let x = l ? w - 3 : w - 13; x - 5 > (l ? 12 : 2); x -= 9) p.push([x, 4], [x - 2.5, 8.5], [x - 5, 4])
                return p
            }
            upper: Theme.brass; lower: Qt.darker(Theme.brassLo, 1.3)
        }
    }
}
