// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// what a bar group sits on, so the bar's silhouette. Drawn by the livery (Skin.bar): clamped plate, armour band,
// floating shard or iron slab. `part` is left, heart or right
Item {
    id: root
    property real sr: 10
    property string part: ""
    readonly property string style: Skin.bar
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.BarPlate { host: root } }
    Component { id: um; Um.BarPlate { host: root } }
    Component { id: ne; Ne.BarPlate { host: root } }
    Component { id: kh; Kh.BarPlate { host: root } }
}
