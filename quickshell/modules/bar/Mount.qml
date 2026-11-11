// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// What a group of the bar is seated on, and so the bar's silhouette. The livery (Skin.bar) decides:
//   mechanicus    a plate clamped to the screen edge, shoulders swept into the edge, a CRT let into it
//   ultramarines  a section of one continuous armour band; the centre is a raised command post
//   necrons       a shard floating free of the edge, pointed at both ends, the centre one with a pendant
//   khorne        a slab of iron with a saw-toothed foot and brass spikes at its ends; the centre one has a jaw
// `part` is left, heart or right.
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
