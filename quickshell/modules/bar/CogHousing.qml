// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common
import qs.services
import qs.kits

// The machine spirit: the cog turns with load. Click opens the command console (launcher).
BarButton {
    id: root
    interactive: true
    tip: "Command console (Super)"
    implicitWidth: 28
    onClicked: Launcher.toggle()
    Heart { id: cog; anchors.centerIn: parent; width: 22; height: 22
        // a faint phosphor bloom behind the line drawing, brighter on hover
        Rectangle { z: -1; anchors.centerIn: parent; width: 26; height: 26; radius: 13; color: Theme.glow; opacity: root.hovered ? 0.14 : 0.06 } }
}
