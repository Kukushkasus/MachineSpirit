// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// A level strip: the volume, microphone and brightness faders. Segments in a dark well (mechanicus), a ruled
// gauge with a gold cap (ultramarines), leaning cells of light (necrons), heavy notched blocks (khorne).
// The input (drag, click, wheel) belongs to the caller; this only shows `level`.
Item {
    id: root
    property real level: 0
    property bool off: false
    property bool hovered: false
    readonly property string style: Skin.control
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Track { host: root } }
    Component { id: um; Um.Track { host: root } }
    Component { id: ne; Ne.Track { host: root } }
    Component { id: kh; Kh.Track { host: root } }
}
