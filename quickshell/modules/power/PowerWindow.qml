// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import qs.common
import qs.services
import qs.kits

// The Great Valve: eight rites on the spokes of a valve wheel. Wheel / arrows turn the selection,
// click or Enter performs it. Dangerous rites (hazard ring) must be held until the pressure builds.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        // created lazily: `ready` flips right after creation so the opening animation still runs
        property bool ready: false
        Component.onCompleted: Qt.callLater(() => ready = true)
        readonly property bool mine: ready && Power.open && (Settings.primary()?.name ?? modelData.name) === modelData.name

        readonly property var rites: [
            { icon: "lock",               label: "Lock",            hint: mech ? "Seal the cogitator" : "Lock the screen",        cmd: ["ms-session", "lock"], danger: false },
            { icon: "bedtime",            label: "Sleep",           hint: mech ? "Let the spirit rest" : "Suspend the computer",       cmd: ["systemctl", "suspend"], danger: false },
            { icon: "monitoring",         label: "Settings",        hint: mech ? "Configure the instruments" : "Open settings", cmd: ["quickshell", "ipc", "-c", "machinespirit", "call", "settings", "toggle"], danger: false },
            { icon: "imagesmode",         label: "Wallpapers",      hint: mech ? "Open the pict archive" : "Choose a wallpaper",     cmd: ["quickshell", "ipc", "-c", "machinespirit", "call", "walls", "toggle"], danger: false },
            { icon: "restart_alt",        label: "Reboot",          hint: "Hold to restart",           cmd: ["systemctl", "reboot"], danger: true },
            { icon: "power_settings_new", label: "Shut down",       hint: "Hold to power off",         cmd: ["systemctl", "poweroff"], danger: true },
            { icon: "logout",             label: "Log out",         hint: "Hold to end the session",   cmd: ["hyprctl", "eval", "hl.dispatch(hl.dsp.exit())"], danger: true },
            { icon: "refresh",            label: "Reload shell",    hint: "Restart the shell",         cmd: ["ms-session", "restart"], danger: false }
        ]
        readonly property bool mech: Theme.kit === "mechanicus"
        property int sel: 0
        property real hold: 0          // 0..1 pressure for dangerous rites
        readonly property var cur: rites[sel]

        function step(d) { sel = (sel + d + rites.length) % rites.length; hold = 0; holdAnim.stop() }
        function perform(i) {
            Power.close()
            Quickshell.execDetached(rites[i].cmd)
        }
        function press(i) {
            sel = i
            if (!rites[i].danger) { perform(i); return }
            holdAnim.restart()
        }
        function release() { if (holdAnim.running) { holdAnim.stop(); hold = 0 } }
        NumberAnimation {
            id: holdAnim; target: win; property: "hold"; from: 0; to: 1; duration: Settings.data.holdMs ?? 800
            onFinished: { steam.puff(); win.perform(win.sel) }
        }

        visible: mine || scrim.opacity > 0.01
        WlrLayershell.namespace: "machinespirit-power"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        onMineChanged: if (mine) { sel = 0; hold = 0; keys.forceActiveFocus() }

        Rectangle {
            id: scrim
            anchors.fill: parent
            color: Theme.glass
            opacity: win.mine ? 0.93 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dMedium } }
            MouseArea { anchors.fill: parent; onClicked: Power.close(); onWheel: event => win.step(event.angleDelta.y > 0 ? -1 : 1) }
        }

        FocusScope {
            id: keys
            anchors.fill: parent
            Keys.onPressed: event => {
                const k = event.key
                if (event.isAutoRepeat) { event.accepted = true; return }
                if (k === Qt.Key_Escape) Power.close()
                else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) win.step(1)
                else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_Backtab) win.step(-1)
                else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) win.press(win.sel)
                else return
                event.accepted = true
            }
            Keys.onReleased: event => {
                if (!event.isAutoRepeat && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) win.release()
            }

            Item {
                id: dial
                anchors.centerIn: parent
                width: 560; height: 560
                opacity: win.mine ? 1 : 0
                scale: win.mine ? 1 : 0.92
                Behavior on opacity { NumberAnimation { duration: Theme.dMedium } }
                Behavior on scale { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeDecel } }
                readonly property real ringR: 210
                // the rites deploy from the hub one after another, round the wheel, in the faction's manner
                readonly property string kit: Theme.kit
                property real deploy: 1e6        // ms into the deployment; large = all in place
                readonly property int each: Math.max(1, Math.round(Theme.dEnter * 0.9))
                function riteP(i) { return Math.max(0, Math.min(1, (deploy - i * Theme.dStagger) / each)) }
                function reach(p) {
                    if (p >= 1) return 1
                    const q = p - 1
                    if (kit === "khorne") return q * q * (3.6 * q + 2.6) + 1          // flung out, overshoots hard, settles
                    if (kit === "mechanicus") return q * q * (2.7 * q + 1.7) + 1      // a sprung kick
                    if (kit === "necrons") return 1                                   // they do not travel: they phase in where they stand
                    return 1 - Math.pow(1 - p, 4)                                     // precise
                }
                NumberAnimation { id: deployAnim; target: dial; property: "deploy"; from: 0
                    to: (win.rites.length - 1) * Theme.dStagger + dial.each; duration: to
                    onFinished: dial.deploy = 1e6 }
                Connections { target: win; function onMineChanged() { if (win.mine && Theme.motionEnabled) deployAnim.restart(); else { deployAnim.stop(); dial.deploy = 1e6 } } }
                // Mechanicus: the whole wheel turns into place like a gear meshing
                rotation: kit === "mechanicus" && deploy < 1e6 ? -24 * Math.pow(1 - Math.min(1, deploy / (dial.each + win.rites.length * Theme.dStagger)), 3) : 0

                // spokes from the hub to each rite
                Repeater {
                    model: win.rites.length
                    Rectangle {
                        required property int index
                        readonly property real a: index / win.rites.length * 360 - 90
                        x: dial.width / 2; y: dial.height / 2 - 4
                        width: dial.ringR - 40; height: index === win.sel ? 2 : 1.5; radius: 1
                        transformOrigin: Item.Left
                        rotation: a
                        color: index === win.sel ? Theme.glow : Qt.alpha(Theme.glow, 0.22)
                        Behavior on color { ColorAnimation { duration: Theme.dShort } }
                        Rectangle {   // the chosen line glows
                            visible: index === win.sel
                            anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 7; radius: 3.5
                            color: Qt.alpha(Theme.glow, 0.12)
                        }
                    }
                }
                // the valve wheel at the centre turns towards the chosen rite
                Heart {
                    anchors.centerIn: parent
                    width: 210; height: 210
                    spin: false; large: true; hole: Theme.glass
                    rotation: win.sel * (360 / win.rites.length)
                    Behavior on rotation { RotationAnimation { duration: Theme.dLong; direction: RotationAnimation.Shortest; easing.type: Easing.OutCubic } }
                }
                // hub screen: name and hint of the chosen rite, pressure ring while holding
                CrtScreen {
                    anchors.centerIn: parent
                    width: 132; height: 132; radius: Skin.screen === "mechanicus" ? 66 : 38; padding: 0
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Glow { anchors.horizontalCenter: parent.horizontalCenter; font { pixelSize: 17; weight: Font.DemiBold } halo: 0.8; color: win.cur.danger ? Theme.rustText : Theme.glow; text: win.cur.label }
                        Glow { anchors.horizontalCenter: parent.horizontalCenter; width: 112; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; halo: 0; color: Theme.glowDim; font { family: Theme.fontUi; pixelSize: 11 } text: win.cur.hint }
                    }
                }
                Shape {
                    anchors.centerIn: parent; width: 150; height: 150
                    visible: win.hold > 0
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.rustText; strokeWidth: 6; capStyle: ShapePath.RoundCap; fillColor: "transparent"
                        PathAngleArc { centerX: 75; centerY: 75; radiusX: 71; radiusY: 71; startAngle: -90; sweepAngle: 360 * win.hold }
                    }
                }

                // the rites
                Repeater {
                    model: win.rites
                    Item {
                        id: rite
                        required property var modelData
                        required property int index
                        readonly property real a: (index / win.rites.length * 360 - 90) * Math.PI / 180
                        readonly property bool chosen: win.sel === index
                        width: 92; height: 92
                        readonly property real p: dial.riteP(index)
                        readonly property real r: dial.ringR * Math.max(0.15, dial.reach(p))
                        x: dial.width / 2 + Math.cos(a) * r - width / 2
                        y: dial.height / 2 + Math.sin(a) * r - height / 2
                        opacity: dial.kit === "necrons" ? Math.min(1, p * 1.4) * (p >= 1 ? 1 : 0.7 + 0.3 * Math.cos(p * 30)) : Math.min(1, p * 2.5)
                        scale: (chosen ? 1.08 : 1) * (dial.kit === "necrons" ? 1.15 - 0.15 * p : 0.6 + 0.4 * Math.min(1, p * 1.3))
                        Behavior on scale { enabled: dial.deploy >= 1e6; NumberAnimation { duration: Theme.dShort; easing.type: Easing.OutBack } }

                        readonly property color tone: rite.modelData.danger ? Theme.rustText : Theme.glow
                        // the livery's shape for a rite key: a disc, an octagonal plate, a diamond, an iron octagon
                        readonly property string style: Skin.control
                        function shape(w) { return style === "ultramarines" ? Skin.chamfer(w, w, w * 0.29) : style === "necrons" ? [[w / 2, 0], [w, w / 2], [w / 2, w], [0, w / 2]] : Skin.chamfer(w, w, w * 0.3) }
                        Poly {   // dangerous rites, other liveries: a second rim in rust outside the key
                            visible: rite.modelData.danger && rite.style !== "mechanicus"
                            anchors.centerIn: parent; width: rite.style === "necrons" ? 100 : 90; height: width
                            points: rite.shape(width)
                            stroke: Qt.alpha(Theme.rustText, rite.chosen ? 1 : 0.6); strokeWidth: rite.style === "khorne" ? 3 : 2
                        }
                        Shape {   // dangerous rites: a dashed rust ring, the warning stripes of a screen
                            visible: rite.modelData.danger && rite.style === "mechanicus"
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "transparent"; strokeColor: Qt.alpha(Theme.rustText, rite.chosen ? 1 : 0.7); strokeWidth: 3
                                strokeStyle: ShapePath.DashLine; dashPattern: [2.2, 1.6]; capStyle: ShapePath.FlatCap
                                PathAngleArc { centerX: 46; centerY: 46; radiusX: 44; radiusY: 44; startAngle: 0; sweepAngle: 360 }
                            }
                        }
                        Rectangle {   // halo of the chosen rite
                            visible: rite.chosen && rite.style === "mechanicus"
                            anchors.centerIn: parent; width: 86; height: 86; radius: 43
                            color: Qt.alpha(rite.tone, 0.1)
                        }
                        Poly {   // the key, other liveries
                            visible: rite.style !== "mechanicus"
                            anchors.centerIn: parent; width: rite.style === "necrons" ? 84 : 76; height: width
                            points: rite.shape(width)
                            upper: rite.chosen ? Qt.alpha(rite.tone, 0.2) : rite.style === "khorne" ? Qt.lighter(Theme.metal, 1.05) : Qt.darker(Theme.glass, 1.1)
                            lower: rite.chosen ? Qt.alpha(rite.tone, 0.08) : rite.style === "khorne" ? Qt.darker(Theme.metal, 1.7) : rite.style === "ultramarines" ? Qt.darker(Theme.metal, 1.3) : Qt.darker(Theme.metal, 1.6)
                            stroke: rite.style === "ultramarines" ? (rite.chosen ? Theme.brassHi : Qt.alpha(Theme.brass, 0.6)) : rite.style === "khorne" ? (rite.chosen ? rite.tone : Theme.brass) : (rite.chosen ? rite.tone : Qt.alpha(rite.tone, 0.5))
                            strokeWidth: rite.chosen ? 2.5 : 1.5
                        }
                        Rectangle {   // the disc: dark glass, phosphor rim
                            visible: rite.style === "mechanicus"
                            anchors.centerIn: parent; width: 74; height: 74; radius: 37
                            color: rite.chosen ? Qt.alpha(rite.tone, 0.16) : Theme.glass
                            border { width: rite.chosen ? 2.5 : 1.2; color: rite.chosen ? rite.tone : Qt.alpha(rite.tone, 0.45) }
                            Behavior on color { ColorAnimation { duration: Theme.dShort } }
                        }
                        Icon { anchors.centerIn: parent; name: rite.modelData.icon; size: 32; color: rite.chosen ? rite.tone : Qt.alpha(rite.tone, 0.8) }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: if (!holdAnim.running) win.sel = rite.index
                            onPressed: win.press(rite.index)
                            onReleased: win.release()
                            onWheel: event => win.step(event.angleDelta.y > 0 ? -1 : 1)
                        }
                    }
                }
                Sparks { id: steam; x: dial.width / 2; y: dial.height / 2 - 70; spread: 30; power: 1.4 }
            }

            Column {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: dial.top; bottomMargin: -20 }
                opacity: dial.opacity
                spacing: 6
                ScreenTitle { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.lex("powerTitle", "Rite of Departure"); size: 17 }
            }
            Glow {
                anchors { horizontalCenter: parent.horizontalCenter; top: dial.bottom; topMargin: -16 }
                opacity: dial.opacity
                halo: 0; color: Theme.glowDim
                font { family: Theme.fontUi; pixelSize: 13 }
                text: mech ? "Wheel or arrows turn the valve, click or Enter performs, hold for rites ringed in red, Esc leaves" : "Wheel or arrows choose, click or Enter performs, hold the actions ringed in red, Esc leaves"
            }
        }
    }
}
