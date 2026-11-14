// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.skins.mechanicus as Me
import qs.skins.ultramarines as Um
import qs.skins.necrons as Ne
import qs.skins.khorne as Kh

// the glass inside a housing, put glowing content inside. The livery (Skin.screen) draws it in two layers,
// under and over the content, so the content is never rebuilt
Item {
    id: root
    default property alias content: inner.data
    property real radius: 6
    property real padding: 8
    property bool scanlines: true
    property bool bootOnLoad: true     // play the power-on effect when created
    readonly property alias inner: inner
    // a live screen: now and then it flickers like a lamp or a scan wave rolls down it. Turn off where the
    // screen is only a background and a Flicker sits on top of the content instead.
    property bool ambient: true
    // the Cogitator's own screens set this: their noise follows the real processor load
    property bool loadNoise: false

    // power-on: the picture opens from a bright horizontal line, then a scanline sweeps down
    property real boot: 1
    property real sweep: 1
    readonly property bool booting: bootAnim.running
    readonly property string kit: Skin.screen
    function powerOn() { if (!Theme.motionEnabled) return; bootAnim.restart() }
    Component.onCompleted: if (bootOnLoad) powerOn()
    SequentialAnimation {
        id: bootAnim
        NumberAnimation { target: root; property: "boot"; from: 0; to: 1
            duration: root.kit === "necrons" ? 420 : root.kit === "khorne" ? 380 : root.kit === "ultramarines" ? 200 : 300
            easing.type: root.kit === "necrons" ? Easing.InOutSine : root.kit === "khorne" ? Easing.OutQuint : Easing.OutCubic }
        NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: root.kit === "mechanicus" ? 380 : root.kit === "ultramarines" ? 260 : 1; easing.type: Easing.InOutSine }
    }

    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.kit === "ultramarines" ? umU : root.kit === "necrons" ? neU : root.kit === "khorne" ? khU : meU
    }
    Item {
        id: inner
        anchors { fill: parent; margins: root.padding }
        opacity: root.kit === "mechanicus" ? Math.min(1, root.boot * 1.6) : root.boot
        transform: Scale { origin.x: inner.width / 2; origin.y: inner.height / 2
            xScale: root.kit === "khorne" ? 1.03 - 0.03 * root.boot : 1
            yScale: root.kit === "mechanicus" ? Math.max(0.02, root.boot) : root.kit === "khorne" ? 1.03 - 0.03 * root.boot : 1 }
    }
    Loader {
        anchors.fill: parent; enabled: false
        sourceComponent: root.kit === "ultramarines" ? umO : root.kit === "necrons" ? neO : root.kit === "khorne" ? khO : meO
    }
    Flicker { anchors.fill: parent; radius: root.radius; active: root.ambient }
    Component { id: meU; Me.Glass { host: root; over: false } }
    Component { id: meO; Me.Glass { host: root; over: true } }
    Component { id: umU; Um.Glass { host: root; over: false } }
    Component { id: umO; Um.Glass { host: root; over: true } }
    Component { id: neU; Ne.Glass { host: root; over: false } }
    Component { id: neO; Ne.Glass { host: root; over: true } }
    Component { id: khU; Kh.Glass { host: root; over: false } }
    Component { id: khO; Kh.Glass { host: root; over: true } }
}
