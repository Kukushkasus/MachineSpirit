// [ PURITY SEAL ] One layout, four liveries.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// panel title between ornaments, drawn by the livery
Item {
    id: root
    property string text: ""
    property int pixelSize: 17
    implicitHeight: pixelSize + 9
    readonly property string style: Skin.type
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Title { host: root } }
    Component { id: um; Um.Title { host: root } }
    Component { id: ne; Ne.Title { host: root } }
    Component { id: kh; Kh.Title { host: root } }
}
