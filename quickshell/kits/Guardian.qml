// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] One layout, many liveries.
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services

// What stands at each side of the command console and holds it (46 x 44, `mirror` for the right side).
//   mechanicus    a servo-skull on a suspensor (common/ServoSkull.qml)
//   ultramarines  a company standard: a gilt pole, a short enamelled banner with a star
//   necrons       a hovering shard of living metal with a lit seam, two motes beneath it
//   khorne        a brazier on a chain, its coals glowing
// `active` lets it live a little; `arrive()` brings it in when the console opens.
Item {
    id: root
    property bool active: false
    property bool mirror: false
    width: 46; height: 44
    visible: Theme.ornaments > 1
    function arrive() { if (Theme.motionEnabled && visible) (Theme.kit === "necrons" ? phaseIn : Theme.kit === "mechanicus" ? null : dropIn)?.restart(); if (Theme.kit === "mechanicus" && loader.item) loader.item.arrive() }
    ParallelAnimation {
        id: dropIn
        YAnimator { target: loader; from: -18; to: 0; duration: Theme.kit === "khorne" ? 380 : 220; easing.type: Theme.kit === "khorne" ? Easing.OutBounce : Easing.OutQuart }
        OpacityAnimator { target: loader; from: 0; to: 1; duration: 160 }
    }
    OpacityAnimator { id: phaseIn; target: loader; from: 0; to: 1; duration: 520; easing.type: Easing.InOutSine }
    Loader {
        id: loader
        width: parent.width; height: parent.height
        sourceComponent: Theme.kit === "ultramarines" ? standard : Theme.kit === "necrons" ? shard : Theme.kit === "khorne" ? brazier : skull
    }
    Component { id: skull; ServoSkull { active: root.active; mirror: root.mirror } }

    Component {
        id: standard
        Item {
            transform: Scale { origin.x: 23; xScale: root.mirror ? -1 : 1 }
            Rectangle { x: 30; y: 20; width: 16; height: 4; radius: 1; gradient: Gradient { GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } }
            Rectangle { x: 42; y: 15; width: 4; height: 14; radius: 1; color: Theme.brass; border { width: 1; color: Qt.darker(Theme.brassLo, 1.3) } }
            Rectangle { x: 27; y: -2; width: 3.5; height: 46; radius: 1.5      // the pole
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 1; color: Theme.brassLo } } }
            Rectangle { x: 24.75; y: -6; width: 8; height: 8; radius: 4; color: Theme.brassHi; border { width: 0.8; color: Theme.brassLo } }
            Rectangle { x: 4; y: 3; width: 26; height: 3; radius: 1.5; color: Theme.brass }
            Shape {   // the banner: square shoulders, a swallow tail
                x: 5; y: 6; width: 22; height: 30
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.brass; strokeWidth: 1; joinStyle: ShapePath.RoundJoin
                    fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: 30; GradientStop { position: 0; color: Theme.metalHi } GradientStop { position: 1; color: Theme.metal } }
                    startX: 0; startY: 0
                    PathLine { x: 22; y: 0 } PathLine { x: 22; y: 28 } PathLine { x: 11; y: 22 } PathLine { x: 0; y: 28 } PathLine { x: 0; y: 0 }
                }
                ShapePath { fillColor: Theme.brassHi; strokeColor: "transparent"
                    PathPolyline { path: { const p = []; for (let i = 0; i <= 10; i++) { const a = i / 10 * Math.PI * 2 - Math.PI / 2, r = i % 2 ? 2.4 : 5.8; p.push(Qt.point(11 + Math.cos(a) * r, 11 + Math.sin(a) * r)) } return p } } }
            }
        }
    }

    Component {
        id: shard
        Item {
            id: sh
            transform: Scale { origin.x: 23; xScale: root.mirror ? -1 : 1 }
            Item {
                id: float
                width: parent.width; height: parent.height
                SequentialAnimation {   // a slow, even drift; an Animator, so it costs the render thread only
                    running: root.active && Theme.motionEnabled; loops: Animation.Infinite
                    YAnimator { target: float; from: 0; to: -2; duration: 2400 + (root.mirror ? 600 : 0); easing.type: Easing.InOutSine }
                    YAnimator { target: float; from: -2; to: 0; duration: 2400 + (root.mirror ? 600 : 0); easing.type: Easing.InOutSine }
                }
                Shape {
                    x: 9; y: 0; width: 22; height: 36
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.metalEdge; strokeWidth: 0.8; joinStyle: ShapePath.RoundJoin
                        fillGradient: LinearGradient { x1: 0; y1: 0; x2: 22; y2: 0; GradientStop { position: 0; color: Theme.metalHi } GradientStop { position: 0.5; color: Theme.metal } GradientStop { position: 1; color: Theme.metalLo } }
                        startX: 11; startY: 0
                        PathLine { x: 21; y: 10 } PathLine { x: 17; y: 30 } PathLine { x: 11; y: 36 } PathLine { x: 5; y: 30 } PathLine { x: 1; y: 10 } PathLine { x: 11; y: 0 }
                    }
                    ShapePath { fillColor: "transparent"; strokeColor: Theme.glow; strokeWidth: 1.3; capStyle: ShapePath.RoundCap
                        startX: 11; startY: 6; PathLine { x: 11; y: 28 }
                        PathMove { x: 7; y: 14 } PathLine { x: 15; y: 14 }
                        PathMove { x: 8.5; y: 19 } PathLine { x: 13.5; y: 19 } }
                }
                Rectangle { x: 13; y: 38; width: 4; height: 4; rotation: 45; color: Qt.alpha(Theme.glow, 0.8) }
                Rectangle { x: 23; y: 39; width: 3; height: 3; rotation: 45; color: Qt.alpha(Theme.glowDim, 0.7) }
            }
            // no arm: the shard holds the console by a thread of light
            Rectangle { x: 30; y: 21; width: 16; height: 1.2; color: Qt.alpha(Theme.glowDim, 0.7) }
            Rectangle { x: 43; y: 18.6; width: 6; height: 6; rotation: 45; color: Theme.metalLo; border { width: 0.8; color: Theme.glowDim } }
        }
    }

    Component {
        id: brazier
        Item {
            transform: Scale { origin.x: 23; xScale: root.mirror ? -1 : 1 }
            Rectangle { x: 30; y: 20; width: 16; height: 4; radius: 1; gradient: Gradient { GradientStop { position: 0; color: Theme.metalEdge } GradientStop { position: 1; color: Theme.metalLo } } }
            Rectangle { x: 42; y: 15; width: 4; height: 14; radius: 1; color: Theme.metalHi; border { width: 1; color: Qt.darker(Theme.metalLo, 1.3) } }
            Shape {   // the chain it hangs by
                x: 0; y: -14; width: 46; height: 30
                preferredRendererType: Shape.CurveRenderer
                ShapePath { strokeColor: Theme.metalEdge; strokeWidth: 3.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap; strokeStyle: ShapePath.DashLine; dashPattern: [0.5, 1.7]
                    startX: 18; startY: 0; PathLine { x: 18; y: 26 } }
            }
            Rectangle {   // the glow of the coals
                id: coals
                x: 3; y: 10; width: 30; height: 14; radius: 7
                gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.alpha(Theme.spark, 0.55) } }
                SequentialAnimation {
                    running: root.active && Theme.motionEnabled; loops: Animation.Infinite
                    OpacityAnimator { target: coals; from: 0.75; to: 1; duration: 1500 + (root.mirror ? 400 : 0); easing.type: Easing.InOutSine }
                    OpacityAnimator { target: coals; from: 1; to: 0.75; duration: 1900; easing.type: Easing.InOutSine }
                }
            }
            Shape {   // the bowl
                x: 2; y: 20; width: 32; height: 20
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.darker(Theme.brassLo, 1.5); strokeWidth: 0.8
                    fillGradient: LinearGradient { x1: 0; y1: 0; x2: 0; y2: 18; GradientStop { position: 0; color: Theme.brassHi } GradientStop { position: 0.4; color: Theme.brass } GradientStop { position: 1; color: Theme.brassLo } }
                    startX: 0; startY: 2
                    PathLine { x: 32; y: 2 } PathQuad { x: 20; y: 16; controlX: 30; controlY: 13 } PathLine { x: 19; y: 19 } PathLine { x: 13; y: 19 } PathLine { x: 12; y: 16 }
                    PathQuad { x: 0; y: 2; controlX: 2; controlY: 13 }
                }
                ShapePath { fillColor: Qt.darker(Theme.rust, 1.1); strokeColor: "transparent"
                    startX: 3; startY: 2; PathLine { x: 29; y: 2 } PathLine { x: 27; y: 4.5 } PathLine { x: 5; y: 4.5 } PathLine { x: 3; y: 2 } }
            }
            Repeater { model: 3; Rectangle { required property int index; x: 8 + index * 9; y: 23; width: 3; height: 3; rotation: 45; color: Theme.brassLo } }
        }
    }
}
