// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common
import qs.services

// One choice out of a few, as a row of large buttons. The chosen one is lit; nothing else marks it.
ColumnLayout {
    id: s
    property string title: ""
    property string hint: ""
    property var options: []          // [{id, name, hint}]
    property string value: ""
    signal changed(string value)
    readonly property bool sought: Settings.sought !== "" && Settings.sought === title
    onSoughtChanged: if (sought) Settings.reveal(s)
    Layout.fillWidth: true; spacing: 8
    DeckText { text: s.title; visible: text !== ""; Layout.fillWidth: true; color: s.sought ? Theme.glow : Theme.surfaceOn }
    Item {
        id: seg
        Layout.fillWidth: true; implicitHeight: 46
        readonly property bool any: s.options.some(o => o.id === s.value)
        property real litX: 0
        property real litW: 0
        // the lit plate slides to the chosen option instead of jumping
        Face {
            id: lit
            visible: seg.any && seg.litW > 0
            x: seg.litX; width: seg.litW; height: parent.height
            radius: 7; solid: true; usePlain: true; on: true
            plainColor: Qt.alpha(Theme.glow, 0.12); plainBorder: Theme.glowDim
            Behavior on x { enabled: lit.width > 0; NumberAnimation { duration: Theme.dMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }
            Behavior on width { enabled: lit.width > 0; NumberAnimation { duration: Theme.dMedium; easing.type: Easing.OutCubic } }
        }
        RowLayout {
            anchors.fill: parent; spacing: 8
            Repeater {
                id: reps
                model: s.options
                Basic.Button {
                    id: b
                    required property var modelData
                    readonly property bool chosen: s.value === modelData.id
                    Layout.fillWidth: true; Layout.preferredWidth: 10; Layout.fillHeight: true; hoverEnabled: true
                    onClicked: s.changed(modelData.id)
                    function report() { if (chosen) { seg.litX = x; seg.litW = width } }
                    onChosenChanged: report(); onXChanged: report(); onWidthChanged: report()
                    Component.onCompleted: report()
                    scale: down ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: b.down ? 70 : 240; easing.type: b.down ? Easing.OutQuad : Easing.OutBack; easing.overshoot: 2.5 } }
                    contentItem: DeckText { text: b.modelData.name; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; wrapMode: Text.NoWrap
                        color: b.chosen ? Theme.glow : Theme.surfaceVariantOn; font.weight: b.chosen ? Font.DemiBold : Font.Normal
                        Behavior on color { ColorAnimation { duration: Theme.dMedium } } }
                    background: Face { radius: 7; solid: !b.chosen; usePlain: true; hovered: b.hovered && !b.chosen; pressed: b.down
                        opacity: b.chosen ? 0 : 1
                        plainColor: b.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                        plainBorder: b.activeFocus ? Theme.glow : Theme.outlineVariant }
                }
            }
        }
    }
    DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn
        text: (s.options.find(o => o.id === s.value) || {}).hint || s.hint; visible: text !== "" }
}
