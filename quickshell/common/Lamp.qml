// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// Indicator lamp: a lit bead with a soft halo; warms up with a short flicker when it comes on.
Item {
    id: root
    property bool lit: false
    property color tone: Theme.glow
    property int size: 8
    width: size + 8; height: size + 8
    Rectangle { anchors.centerIn: parent; width: root.size + 8; height: width; radius: width / 2; color: root.tone; opacity: root.lit ? 0.22 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } } }
    Rectangle {
        id: bead
        anchors.centerIn: parent; width: root.size; height: width; radius: width / 2
        color: root.lit ? root.tone : Qt.alpha(root.tone, 0.16)
        border { width: 1; color: Qt.alpha(root.tone, root.lit ? 0.9 : 0.35) }
        Rectangle { x: parent.width * 0.22; y: parent.height * 0.18; width: parent.width * 0.32; height: width; radius: width / 2; color: Qt.rgba(1, 1, 1, root.lit ? 0.55 : 0.12) }
    }
    onLitChanged: if (lit && !Theme.lowPower) warm.restart()
    SequentialAnimation {
        id: warm
        OpacityAnimator { target: bead; from: 0.3; to: 1; duration: 60 }
        OpacityAnimator { target: bead; from: 1; to: 0.55; duration: 50 }
        OpacityAnimator { target: bead; from: 0.55; to: 1; duration: 120 }
    }
}
