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
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: s.options
            Basic.Button {
                id: b
                required property var modelData
                readonly property bool chosen: s.value === modelData.id
                Layout.fillWidth: true; Layout.preferredWidth: 10; implicitHeight: 46; hoverEnabled: true
                onClicked: s.changed(modelData.id)
                contentItem: DeckText { text: b.modelData.name; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; wrapMode: Text.NoWrap
                    color: b.chosen ? Theme.glow : Theme.surfaceVariantOn; font.weight: b.chosen ? Font.DemiBold : Font.Normal }
                background: Face { radius: 7; solid: true; usePlain: true; hovered: b.hovered; pressed: b.down; on: b.chosen
                    plainColor: b.chosen ? Qt.alpha(Theme.glow, 0.12) : b.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                    plainBorder: b.activeFocus ? Theme.glow : b.chosen ? Theme.glowDim : Theme.outlineVariant }
            }
        }
    }
    DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn
        text: (s.options.find(o => o.id === s.value) || {}).hint || s.hint; visible: text !== "" }
}
