// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// Instrument housing. Content goes inside, inset by `inset`. The livery (Skin.frame) decides what it is:
//   mechanicus    forged metal with a bevelled edge and slotted brass bolts
//   ultramarines  an enamelled armour plate with cut corners inside a gold rim
//   necrons       an asymmetric monolith of dark living metal with energy let into its edges
//   khorne        blackened iron under a battered brass lip, riveted, its foot cut into a saw edge
// Only the housing is drawn by the livery; the content stays put when the livery changes.
Item {
    id: root
    default property alias content: inner.data
    property real radius: 8
    property real inset: 4
    property bool bolts: true
    property real boltSize: 5
    // what the housing holds, so a livery can dress a large window more than a small gauge:
    // "window", "toast", "instrument", or "" for a plain part
    property string role: ""
    readonly property alias inner: inner
    readonly property string style: Skin.frame
    // a fixed pseudo-random number per housing size, so wear marks sit differently on each one and never move
    function wear(i) { return Skin.hash(width, height, i) }

    Loader {
        anchors.fill: parent
        enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Housing { host: root } }
    Component { id: um; Um.Housing { host: root } }
    Component { id: ne; Ne.Housing { host: root } }
    Component { id: kh; Kh.Housing { host: root } }
    Item { id: inner; anchors { fill: parent; margins: root.inset } }
}
