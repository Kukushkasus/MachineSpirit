// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// A section on a panel. `glow` marks it engaged. `tab` hangs a title over the top left edge; `plate` sets
// readings into the top edge on the right. The livery (Skin.card) draws the section, its title and the plate
// behind the readings: a rounded glass well with an engraved plate (mechanicus), a cut plate with a gold
// ribbon (ultramarines), corner brackets and a lit channel (necrons), riveted iron with a forged tag (khorne).
// What sits inside it and on the plate stays where it is when the livery changes.
Item {
    id: root
    property real radius: 10
    // a brief charge through the plates when the panel opens: current, a glint, a pulse or a flare
    property real surge: 0
    function energise() { if (Theme.motionEnabled && tab !== "") surgeAnim.restart() }
    SequentialAnimation { id: surgeAnim
        NumberAnimation { target: root; property: "surge"; from: 0; to: 1; duration: 70 }
        NumberAnimation { target: root; property: "surge"; to: 0; duration: Skin.card === "necrons" || Skin.card === "khorne" ? 620 : 300; easing.type: Easing.OutQuad } }
    property color fill: Qt.alpha(Theme.glass, 0.82)
    property color rim: Qt.alpha(Theme.metalEdge, 0.5)
    property bool glow: false
    property string tab: ""
    property string tabIcon: ""
    property real tabHeight: 26
    readonly property real frameTop: tab !== "" ? tabHeight / 2 : 0     // where the frame itself starts
    default property alias content: holder.data
    property alias plate: plateRow.data     // what rides on the top edge at the right, in a plate of its own
    readonly property alias plateBox: plateBox
    readonly property string style: Skin.card

    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.style === "ultramarines" ? um : root.style === "necrons" ? ne : root.style === "khorne" ? kh : me
    }
    Component { id: me; Me.Section { host: root } }
    Component { id: um; Um.Section { host: root } }
    Component { id: ne; Ne.Section { host: root } }
    Component { id: kh; Kh.Section { host: root } }
    Item {   // the readings on the right; the livery draws the plate behind this box
        id: plateBox
        visible: plateRow.implicitWidth > 0
        anchors { right: parent.right; rightMargin: 12 }
        width: plateRow.implicitWidth + 20; height: Math.max(22, plateRow.implicitHeight + 6)
        y: (root.tabHeight - height) / 2
        Row { id: plateRow; anchors.centerIn: parent; spacing: 10 }
    }
    Item { id: holder; anchors { fill: parent; topMargin: root.frameTop } }
}
