// [ PURITY SEAL ] Knowledge opens the sealed machine.
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
Variants {
    model: Quickshell.screens
PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property bool mine: Settings.open && (Settings.primary()?.name ?? "") === modelData.name
    visible: mine
    onMineChanged: if (mine) Qt.callLater(() => { load(); focus.forceActiveFocus() })
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "machinespirit-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    component ComboBox: Basic.ComboBox {
        implicitHeight: 36; implicitWidth: 220
        font.family: Theme.fontUi; font.pixelSize: 15
        palette.button: Theme.glassHi; palette.buttonText: Theme.glow
        palette.base: Theme.glass; palette.text: Theme.glow
        palette.highlight: Theme.metal; palette.highlightedText: Theme.glow
    }
    component SpinBox: Basic.SpinBox {
        implicitHeight: 36; font.family: Theme.fontUi; font.pixelSize: 15
        palette.button: Theme.glassHi; palette.buttonText: Theme.glow
        palette.base: Theme.glass; palette.text: Theme.glow
    }
    component Label: Basic.Label { font.family: Theme.fontUi; font.pixelSize: 15 }
    component Button: Basic.Button {
        id: ctl
        implicitHeight: 36; implicitWidth: Math.max(100, contentItem.implicitWidth + 28)
        font.family: Theme.fontUi; font.pixelSize: 14
        contentItem: Text { text: ctl.text; color: ctl.enabled ? Theme.glow : Theme.glowFaint; font: ctl.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 5; color: ctl.down ? Theme.metal : ctl.hovered || ctl.highlighted ? Theme.glassHi : Theme.glass; border.color: ctl.highlighted ? Theme.glow : Theme.metalEdge; Behavior on color { ColorAnimation { duration: Theme.dShort } } }
    }
    component TextField: Basic.TextField {
        id: field
        implicitHeight: 38; leftPadding: 12; rightPadding: 12
        font.family: Theme.fontUi; font.pixelSize: 15; color: Theme.glow; placeholderTextColor: Theme.glowFaint
        background: Rectangle { color: Theme.glass; radius: 5; border.color: field.activeFocus ? Theme.glow : Theme.metalHi }
    }
    component CheckBox: Basic.CheckBox {
        id: check
        implicitHeight: 36; spacing: 12
        contentItem: Text { text: check.text; color: Theme.glow; font.family: Theme.fontUi; font.pixelSize: 15; leftPadding: 34; verticalAlignment: Text.AlignVCenter }
        indicator: Rectangle { x: 0; y: (check.height-height)/2; width: 22; height: 22; radius: 4; color: check.checked ? Theme.glowDim : Theme.glass; border.color: Theme.metalEdge; Text { anchors.centerIn: parent; text: check.checked ? "✓" : ""; color: Theme.glass } }
    }
    property var draft: ({})
    property int tab: 0
    function load() { draft = JSON.parse(JSON.stringify(Settings.data)); layouts.text = (draft.layouts || ["us"]).join(","); switcher.text = draft.layoutSwitch || "grp:alt_shift_toggle" }
    Connections { target: Settings; function onDataChanged() { win.load() } function onOpenChanged() { if (win.mine) { win.load(); focus.forceActiveFocus() } } }
    Rectangle { anchors.fill: parent; color: "#b0080c0a"; MouseArea { anchors.fill: parent; onClicked: Settings.open = false } }
    FocusScope {
        id: focus; anchors.fill: parent
        Keys.onEscapePressed: Settings.open = false
        Bezel {
            anchors.centerIn: parent
            width: Math.min(900, parent.width - 32); height: Math.min(720, parent.height - 70)
            inset: 8; radius: 14
            Rectangle { anchors.fill: parent; color: Theme.glass; radius: 9 }
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 12
                RowLayout {
                    Label { text: Settings.manual ? "THE INSTRUMENT MANUAL" : "COGITATOR SETTINGS"; color: Theme.glow; font.family: Theme.fontUi; font.pixelSize: 24; Layout.fillWidth: true }
                    Button { text: "Close · Esc"; onClicked: Settings.open = false }
                }
                Label { text: Settings.manual ? "Search the active bindings of this session" : "Your configuration survives updates"; color: Theme.glowDim }
                RowLayout {
                    visible: !Settings.manual
                    Repeater { model: ["General", "Displays", "Keybindings"]
                        Button { required property string modelData; required property int index; text: modelData; highlighted: win.tab === index; onClicked: win.tab = index }
                    }
                    Item { Layout.fillWidth: true }
                }
                ComboBox {
                    id: category; visible: Settings.manual
                    model: ["All categories"].concat([...new Set(Settings.bindings.map(b => b.description.split(":")[0]))].sort())
                    Layout.fillWidth: true
                }
                TextField { id: search; visible: Settings.manual || win.tab === 2; Layout.fillWidth: true; placeholderText: "Search action or shortcut…" }
                        ColumnLayout {
                            visible: !Settings.manual && win.tab === 2
                            Label { text: "Remap a shortcut (use its original Lua key spelling). Empty replacement disables it."; color: Theme.glowDim; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            TextField { id: original; placeholderText: "SUPER + E"; Layout.fillWidth: true }
                            TextField { id: replacement; placeholderText: "SUPER + ALT + E"; Layout.fillWidth: true }
                            Button { text: "Add override"; onClicked: { win.draft.bindings[original.text] = replacement.text; Settings.status = "Override added to draft" } }
                            Button { text: "Reset shortcut overrides"; onClicked: { win.draft.bindings = {}; Settings.status = "Overrides cleared in draft" } }
                        }
                ScrollView {
                    id: scroll
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        width: scroll.availableWidth; spacing: 12
                        ColumnLayout {
                            visible: !Settings.manual && win.tab === 0; Layout.fillWidth: true
                            Label { text: "Keyboard layouts (XKB names, comma separated)"; color: Theme.glow }
                            TextField { id: layouts; Layout.fillWidth: true; placeholderText: "us,ru" }
                            Label { text: "Layout switching option"; color: Theme.glow }
                            TextField { id: switcher; Layout.fillWidth: true }
                            CheckBox { text: "Reduce motion"; checked: !!win.draft.reducedMotion; onToggled: win.draft.reducedMotion = checked }
                            CheckBox { text: "Low power mode"; checked: !!win.draft.lowPower; onToggled: win.draft.lowPower = checked }
                            CheckBox { text: "Window blur"; checked: !!win.draft.blur; onToggled: win.draft.blur = checked }
                            RowLayout {
                                Label { text: "Lock after (seconds)"; color: Theme.glow }
                                SpinBox { from: 30; to: 86400; editable: true; value: win.draft.lockSeconds || 600; onValueModified: win.draft.lockSeconds = value }
                            }
                            RowLayout {
                                Label { text: "Screen off after (seconds)"; color: Theme.glow }
                                SpinBox { from: 30; to: 86400; editable: true; value: win.draft.screenOffSeconds || 900; onValueModified: win.draft.screenOffSeconds = value }
                            }
                            Button { text: "Edit desktop instruments"; onClicked: { Settings.open = false; DesktopWidgets.toggle() } }
                        }
                        ColumnLayout {
                            visible: !Settings.manual && win.tab === 1; Layout.fillWidth: true
                            Label { text: "Primary output (panels stay on this screen)"; color: Theme.glow }
                            ComboBox { model: ["Automatic"].concat(Settings.monitors.map(m => m.name)); currentIndex: Math.max(0, model.indexOf(win.draft.primaryOutput || "Automatic")); onActivated: win.draft.primaryOutput = currentIndex ? currentText : "" }
                            Label { text: "Modes are previewed for 15 seconds. Confirm to keep them."; color: Theme.glowDim }
                            Repeater {
                                model: Settings.monitors
                                ColumnLayout {
                                    id: display
                                    required property var modelData
                                    Layout.fillWidth: true
                                    property var saved: (win.draft.monitors || []).find(m => m.output === modelData.name) || ({output:modelData.name, mode:"preferred",position:modelData.x+"x"+modelData.y,scale:modelData.scale,transform:modelData.transform,disabled:!!modelData.disabled})
                                    function update(k,v) { const m = Object.assign({}, saved); m[k]=v; saved=m; win.draft.monitors=(win.draft.monitors || []).filter(x => x.output !== modelData.name).concat([m]) }
                                    Label { text: display.modelData.name + " · " + display.modelData.description; color: Theme.glow; font.bold: true }
                                    RowLayout {
                                        CheckBox { text: "Enabled"; checked: !display.saved.disabled; onToggled: display.update("disabled", !checked) }
                                        ComboBox { Layout.fillWidth: true; model: ["preferred"].concat((display.modelData.availableModes || []).map(x => x.replace("Hz",""))); currentIndex: Math.max(0,model.indexOf(display.saved.mode)); onActivated: display.update("mode",currentText) }
                                    }
                                    RowLayout {
                                        Label { text: "Position"; color: Theme.glowDim }
                                        TextField { text: display.saved.position; placeholderText: "1920x0"; onEditingFinished: display.update("position",text); Layout.preferredWidth: 120 }
                                        Label { text: "Scale"; color: Theme.glowDim }
                                        TextField { text: String(display.saved.scale); onEditingFinished: display.update("scale",Number(text)); Layout.preferredWidth: 70 }
                                        ComboBox { model: ["Normal","90°","180°","270°","Flipped","Flipped 90°","Flipped 180°","Flipped 270°"]; currentIndex: display.saved.transform || 0; onActivated: display.update("transform",currentIndex) }
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: Settings.manual || win.tab === 2 ? Settings.bindings.filter(b => (b.keys + " " + b.description).toLowerCase().includes(search.text.toLowerCase()) && (!Settings.manual || category.currentIndex <= 0 || b.description.split(":")[0] === category.currentText)).sort((a,b) => a.description.localeCompare(b.description)) : []
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Button { visible: !Settings.manual; text: "Remap"; onClicked: { original.text = modelData.original || modelData.keys; replacement.text = modelData.keys } }
                                Label { text: modelData.keys || "Disabled"; color: Theme.glow; font.bold: true; wrapMode: Text.WrapAnywhere; Layout.preferredWidth: Math.min(300, scroll.availableWidth * 0.44) }
                                Label { text: modelData.description; color: Theme.glowDim; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            }
                        }

                    }
                }
                Label { text: Settings.error || Settings.status; color: Settings.error ? Theme.rustText : Theme.glowDim; wrapMode: Text.Wrap; Layout.fillWidth: true }
                RowLayout {
                    visible: !Settings.manual
                    Button { text: "Save and apply"; enabled: Settings.countdown === 0; onClicked: { win.draft.layouts = layouts.text.split(",").map(x => x.trim()).filter(x => x); win.draft.layoutSwitch = switcher.text.trim(); Settings.run("write", win.draft) } }
                    Button { visible: Settings.countdown > 0; text: "Keep displays · " + Settings.countdown; onClicked: Settings.run("confirm") }
                    Button { visible: Settings.countdown > 0; text: "Revert"; onClicked: Settings.run("revert") }
                }
            }
        }
    }
}
}
