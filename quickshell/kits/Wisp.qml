// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common

// A wisp of smoke or steam: one soft puff that rises, spreads and is gone in about a second.
// Two animators on one rectangle; nothing runs between puffs.
Item {
    id: root
    property color tint: Theme.metalEdge
    width: 1; height: 1
    function rise(px, py) {
        if (!Theme.fxOn("particles") || anim.running) return
        x = px; y = py; anim.restart()
    }
    Shape {   // soft at the edge: a radial falloff, not a disc
        id: puff; x: -6; y: -6; width: 12; height: 12; opacity: 0; visible: anim.running
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient { centerX: 6; centerY: 6; centerRadius: 6; focalX: 6; focalY: 6
                GradientStop { position: 0; color: Qt.alpha(root.tint, 0.55) } GradientStop { position: 1; color: Qt.alpha(root.tint, 0) } }
            PathAngleArc { centerX: 6; centerY: 6; radiusX: 6; radiusY: 6; startAngle: 0; sweepAngle: 360 }
        }
    }
    ParallelAnimation {
        id: anim
        YAnimator { target: puff; from: -6; to: -26; duration: 1100; easing.type: Easing.OutQuad }
        ScaleAnimator { target: puff; from: 0.8; to: 3.2; duration: 1100; easing.type: Easing.OutQuad }
        SequentialAnimation {
            OpacityAnimator { target: puff; from: 0; to: 0.5; duration: 160 }
            OpacityAnimator { target: puff; from: 0.5; to: 0; duration: 940 }
        }
    }
}
