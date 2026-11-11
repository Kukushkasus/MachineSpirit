// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// The cap of a workspace key and the mark that a workspace is occupied. A glass cap under a phosphor rim
// (mechanicus), a gold shield with a chevron (ultramarines), a leaning lit cell (necrons), a red-hot iron
// block (khorne). The numeral and the key's input stay with WsSelector.
Item {
    id: root
    property bool focused: false
    property bool hovered: false
    property bool occupied: false
    readonly property string style: Skin.glyph
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Mark { host: root } }
    Component { id: um; Um.Mark { host: root } }
    Component { id: ne; Ne.Mark { host: root } }
    Component { id: kh; Kh.Mark { host: root } }
}
