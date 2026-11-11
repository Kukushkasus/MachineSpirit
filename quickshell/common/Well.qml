// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// A well for a module's glyph: a round glass well (mechanicus), a cut gilt socket (ultramarines), a lit diamond
// (necrons), an octagonal iron socket with a brass ring (khorne). Put the glyph inside; it is not rebuilt.
Item {
    id: root
    property bool lit: false
    readonly property string style: Skin.control
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Well { host: root } }
    Component { id: um; Um.Well { host: root } }
    Component { id: ne; Ne.Well { host: root } }
    Component { id: kh; Kh.Well { host: root } }
    default property alias content: inner.data
    Item { id: inner; anchors.fill: parent }
}
