// SPDX-License-Identifier: GPL-3.0-only
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.common
import qs.services

// one monitor's lock view: dimmed blurred wallpaper behind a riveted housing with nixie tubes and a phosphor
// input. Short fade in, shakes once on a wrong passphrase
Item {
    id: surface
    required property var owner
    readonly property real u: Math.max(0.7, Math.min(height / 1080, 2.2))
    readonly property string wallpaperSource: Theme.wallpaper !== "" ? "file://" + Theme.wallpaper
        : "file://" + (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/machinespirit/wallpaper.png"

    clip: true
    Rectangle { anchors.fill: parent; color: Theme.surface }
    // blur fades to transparent at the picture's edge, which showed as a dark rounded frame. So the picture is
    // drawn bigger than the screen by more than the blur radius and clipped
    readonly property real blurReach: 48
    Image {
        id: wall
        anchors { fill: parent; margins: Theme.lowPower ? 0 : -surface.blurReach * 1.5 }
        source: surface.wallpaperSource; fillMode: Image.PreserveAspectCrop; asynchronous: true
        sourceSize: Qt.size(Math.ceil(surface.width / 2), Math.ceil(surface.height / 2))   // blurred anyway: half size is enough
        opacity: Theme.lowPower ? 0.35 : 1
        layer.enabled: !Theme.lowPower   // blurred and darkened; with low power the plain wallpaper is only dimmed
        layer.effect: MultiEffect { autoPaddingEnabled: false; blurEnabled: true; blur: 1.0; blurMax: surface.blurReach
            brightness: Skin.frame === "khorne" ? -0.22 : -0.28; saturation: Skin.frame === "khorne" ? 0.05 : -0.15 }
    }
    Rectangle { anchors.fill: parent; color: Qt.alpha(Theme.surface, 0.4) }
    Shape {   // a vignette: the edges sink, the light gathers behind the housing; Khorne glows from below like a forge
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: surface.width / 2; centerY: surface.height * (Skin.frame === "khorne" ? 0.62 : 0.5)
                centerRadius: Math.hypot(surface.width, surface.height) * 0.62
                focalX: centerX; focalY: centerY
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.12) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.62) }
            }
            PathRectangle { width: surface.width; height: surface.height }
        }
    }
    Rectangle {   // Khorne: heat rising from the bottom edge, breathing slowly
        visible: Skin.frame === "khorne"
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * 0.42
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Qt.alpha(Theme.rust, 0.26) }
        }
        SequentialAnimation on opacity {
            running: Theme.motionEnabled && Skin.frame === "khorne"; loops: Animation.Infinite
            NumberAnimation { from: 0.7; to: 1; duration: 2600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0.7; duration: 3100; easing.type: Easing.InOutSine }
        }
    }
    Repeater {   // brass hairlines, as on the desktop
        model: [0.07, 0.93]
        Rectangle { x: surface.width * modelData; width: 1; height: surface.height; color: Theme.brass; opacity: 0.18 }
    }
    Repeater {
        model: [0.1, 0.9]
        Rectangle { y: surface.height * modelData; width: surface.width; height: 1; color: Theme.brass; opacity: 0.35 }
    }
    Image { anchors.fill: parent; source: Qt.resolvedUrl("../../assets/scanlines.svg"); fillMode: Image.Tile; opacity: 0.12; smooth: false }
    Txt {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 * surface.u }
        text: "M A C H I N E   S P I R I T  /  F O R G E"; color: Theme.brass; opacity: 0.55; font.pixelSize: 12 * surface.u
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        property real lift: 14 * surface.u
        Component.onCompleted: { if (Theme.motionEnabled) enter.start(); else { opacity = 1; lift = 0 } }
        ParallelAnimation {
            id: enter
            NumberAnimation { target: stage; property: "opacity"; to: 1; duration: Theme.dLong; easing.type: Easing.OutCubic }
            NumberAnimation { target: stage; property: "lift"; to: 0; duration: Theme.dLong; easing.type: Easing.OutCubic }
        }

        Item {
            id: panel
            width: 480 * surface.u; height: column.implicitHeight + 60 * surface.u
            anchors.centerIn: parent; anchors.verticalCenterOffset: stage.lift - 20 * surface.u
            transform: Translate { id: nudge }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: nudge; property: "x"; to: -12 * surface.u; duration: 50 }
                NumberAnimation { target: nudge; property: "x"; to: 10 * surface.u; duration: 70 }
                NumberAnimation { target: nudge; property: "x"; to: -6 * surface.u; duration: 60 }
                NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
            }
            Connections { target: surface.owner; function onErrorChanged() { if (surface.owner.error !== "" && Theme.motionEnabled) shake.restart() } }

            // the housing: Mechanicus keeps its riveted instrument case; the other liveries build it as one of their windows
            readonly property bool plain: Skin.frame === "mechanicus"
            Bezel { visible: !panel.plain; anchors.fill: parent; radius: 16 * surface.u; inset: 0; role: "window"; bolts: false }
            CrtScreen { visible: !panel.plain; anchors { fill: parent; margins: 8 * surface.u } radius: 11 * surface.u; padding: 0; bootOnLoad: false; ambient: false; scanlines: false }
            Rectangle {   // housing
                visible: panel.plain
                anchors.fill: parent; radius: 12 * surface.u; color: Qt.alpha(Theme.surfaceContainer, 0.94)
                border { width: Math.max(2, 3 * surface.u); color: Theme.metalEdge }
            }
            Rectangle { visible: panel.plain; anchors { fill: parent; margins: 6 * surface.u } radius: 8 * surface.u; color: "transparent"; border { width: 1; color: Theme.metal } }
            Repeater {   // rivets
                model: panel.plain ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
                Rectangle {
                    width: 6 * surface.u; height: width; radius: width / 2; color: Theme.metal; border { width: 1; color: Theme.metalEdge }
                    x: modelData[0] ? panel.width - 16 * surface.u : 10 * surface.u; y: modelData[1] ? panel.height - 16 * surface.u : 10 * surface.u
                }
            }

            Column {
                id: column
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30 * surface.u }
                spacing: 12 * surface.u
                Item {
                    width: parent.width; height: head.implicitHeight
                    Txt { id: head; text: "●  SEALED"; color: Theme.glow; font.letterSpacing: 2.5; font.pixelSize: 13 * surface.u }
                    Txt { anchors.right: parent.right; text: "01 / SANCTUM"; color: Theme.outline; font.letterSpacing: 2; font.pixelSize: 12 * surface.u }
                }
                Rectangle { width: parent.width; height: 1; color: Theme.metal }

                CrtScreen {   // the cogitator glass with the time
                    width: parent.width; height: 150 * surface.u; radius: 8 * surface.u; bootOnLoad: false; ambient: false
                    Column {
                        anchors.centerIn: parent; spacing: 2 * surface.u
                        Nixie { anchors.horizontalCenter: parent.horizontalCenter; size: Math.round(84 * surface.u); text: Qt.formatTime(surface.owner.now, "HH:mm") }
                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter; color: Theme.outline; font.letterSpacing: 2.5; font.pixelSize: 12 * surface.u
                            text: Qt.formatDate(surface.owner.now, "dddd  ·  dd MMMM yyyy").toUpperCase()
                        }
                    }
                }

                Item { width: 1; height: 2 * surface.u }
                Txt { text: "OPERATOR"; color: Theme.outline; font.letterSpacing: 3; font.pixelSize: 11 * surface.u }
                Txt { text: Quickshell.env("USER"); color: panel.plain ? Theme.surfaceOn : Skin.type === "necrons" ? Theme.glow : Theme.brassHi
                      font { family: panel.plain ? Theme.fontNum : Skin.display(Quickshell.env("USER")); pixelSize: 26 * surface.u * (panel.plain ? 1 : Skin.titleScale); weight: panel.plain ? Font.DemiBold : Skin.titleWeight } }

                Item {
                    width: parent.width; height: 50 * surface.u
                    Face { anchors.fill: parent; radius: 6 * surface.u; solid: true; usePlain: true; on: field.activeFocus; danger: surface.owner.error !== ""
                        plainColor: Qt.darker(Theme.surface, 1.25); plainBorder: surface.owner.error !== "" ? Theme.error : (field.activeFocus ? Theme.glow : Theme.metal) }
                    Txt { visible: field.text.length === 0 && !surface.owner.checking; anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 16 * surface.u }
                          text: "Enter passphrase"; color: Theme.outline; font.pixelSize: 17 * surface.u }
                    TextInput {
                        id: field
                        anchors { fill: parent; leftMargin: 16 * surface.u; rightMargin: 16 * surface.u }
                        verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password; passwordCharacter: "•"
                        color: Theme.glow; font { family: Theme.fontUi; pixelSize: 21 * surface.u }
                        selectionColor: Theme.glow; selectedTextColor: Theme.surface
                        enabled: !surface.owner.checking; clip: true; focus: true
                        text: surface.owner.password
                        onTextEdited: { surface.owner.password = text; if (surface.owner.error !== "") surface.owner.error = "" }
                        onAccepted: surface.owner.submit()
                        Component.onCompleted: forceActiveFocus()
                    }
                }
                Txt {
                    width: parent.width; wrapMode: Text.WordWrap; font.letterSpacing: 1; font.pixelSize: 13 * surface.u
                    text: surface.owner.checking ? "AUTHENTICATING…" : (surface.owner.error !== "" ? "ACCESS DENIED. " + surface.owner.error : "THE COGITATOR IS SEALED")
                    color: surface.owner.error !== "" ? Theme.error : Theme.outline
                }
            }
        }
    }
}
