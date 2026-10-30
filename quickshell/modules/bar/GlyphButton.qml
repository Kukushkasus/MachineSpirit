// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Plain engraved glyph on the housing: brass at rest, glowing when on or hovered. A small lamp may sit beside it.
BarButton {
    id: root
    property string icon: ""
    property bool on: false            // lit glyph (a toggle that is on)
    property bool lamp: false
    property bool lit: false
    property color tint: Theme.glowDim
    interactive: true
    implicitWidth: 26; implicitHeight: 28
    Icon {
        anchors.centerIn: parent
        name: root.icon; size: 17
        color: root.on || root.hovered || root.active ? Theme.glow : root.tint
        scale: root.pressed ? 0.86 : 1
        Behavior on color { ColorAnimation { duration: Theme.dShort } }
        Behavior on scale { NumberAnimation { duration: 90 } }
    }
    Rectangle {
        id: lampDot
        visible: root.lamp
        x: root.width - 7; y: 3; width: 5; height: 5; radius: 2.5
        color: root.lit ? Theme.glow : Theme.metalLo
        border { width: 1; color: Theme.metalLo }
        Behavior on color { SequentialAnimation {
            ColorAnimation { duration: 90 }
            NumberAnimation { target: lampDot; property: "opacity"; to: 0.35; duration: 60 }
            NumberAnimation { target: lampDot; property: "opacity"; to: 1; duration: 140 }
        } }
    }
}
