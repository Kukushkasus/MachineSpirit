// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// key face behind a glyph or label: rest, hover, pressed, engaged. Mechanicus draws `level`/`edge` as given,
// other liveries read the states and draw their own. MouseArea and content stay with the caller
Item {
    id: root
    property color tone: Theme.glow
    property real level: 0          // mechanicus: wash strength
    property real edge: 0           // mechanicus: rim strength
    property real edgeWidth: 1
    property real radius: 6
    property bool round: false      // mechanicus: a round key
    property bool hovered: false
    property bool pressed: false
    property bool on: false
    property bool danger: false
    // a key that always shows its body (buttons, fields, choices), not only under the pointer
    property bool solid: false
    // mechanicus only: paint exactly these instead of the phosphor wash (the settings deck's own colours)
    property bool usePlain: false
    property color plainColor: "transparent"
    property color plainBorder: "transparent"
    property real plainBorderWidth: 1
    readonly property string style: Skin.control
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Face { host: root } }
    Component { id: um; Um.Face { host: root } }
    Component { id: ne; Ne.Face { host: root } }
    Component { id: kh; Kh.Face { host: root } }
}
