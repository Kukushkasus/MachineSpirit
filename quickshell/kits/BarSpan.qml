// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services
import qs.modules.bar

// What hangs between two mounts of the bar. The bar only knows this one item; the theme pack's kit decides
// what it is: cables (mechanicus), an armour rail (ultramarines), energy conduits (necrons), a chain (khorne).
// Every kind answers the same three calls, so the bar's timers never care which one is there.
Item {
    id: root
    property real portY: 17
    readonly property var span: loader.item
    visible: Theme.ornaments > 0
    function hasBare() { return visible && !!span && span.hasBare() }
    function strike(quiet) {
        if (!span) return
        span.strike(quiet)
        // mechanicus: scorched insulation smokes a moment after a full strike, now and then
        if (!quiet && Theme.kit === "mechanicus" && Math.random() < 0.4 && span.bare && span.bare[0].length) { smokeAt = (span.bare[0][0][0] + span.bare[0][0][1]) / 2 * width; smoke.restart() }
    }
    property real smokeAt: 0
    Timer { id: smoke; interval: 320; onTriggered: wisp.rise(root.smokeAt, root.portY + 8) }
    Wisp { id: wisp; z: 5; tint: "#b9b2a6" }
    function crackle() { if (span) span.crackle() }
    Loader {
        id: loader
        anchors.fill: parent
        active: root.visible && root.width > 40
        sourceComponent: Theme.kit === "ultramarines" ? armor : Theme.kit === "necrons" ? conduit : Theme.kit === "khorne" ? chain : cables
    }
    Component { id: cables; Cables { portY: root.portY } }
    Component { id: armor; ArmorSpan { portY: root.portY } }
    Component { id: conduit; ConduitSpan { portY: root.portY } }
    Component { id: chain; ChainSpan { portY: root.portY } }
}
