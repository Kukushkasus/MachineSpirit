// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

Basic.ComboBox {
    id:c; implicitHeight:40; implicitWidth:230
    font.family:Theme.fontUi; font.pixelSize:13
    palette.button:Theme.surfaceContainerLow; palette.buttonText:Theme.surfaceOn; palette.base:Theme.glass; palette.text:Theme.surfaceOn; palette.highlight:Theme.primaryContainer; palette.highlightedText:Theme.primaryContainerOn
    delegate: Basic.ItemDelegate {
        required property int index
        width: c.width - 10
        height: 40
        highlighted: c.highlightedIndex === index
        contentItem: Text {
            text: c.textAt(parent.index)
            font: c.font
            color: parent.highlighted ? Theme.glow : Theme.surfaceOn
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Face {
            radius: 4
            level: parent.highlighted ? 0.14 : 0; on: parent.highlighted
        }
    }
    popup: Basic.Popup {
        y: c.height + 5
        width: c.width
        padding: 5
        implicitHeight: Math.min(contentItem.implicitHeight + 10, 300)
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: c.popup.visible ? c.delegateModel : null
            currentIndex: c.highlightedIndex
            ScrollIndicator.vertical: Basic.ScrollIndicator {}
        }
        background: Outline { fill: Skin.control === "mechanicus" ? Theme.surfaceContainerLow : Qt.darker(Theme.glass, 1.1); radius: 7; style: Skin.control; color: Skin.control === "ultramarines" || Skin.control === "khorne" ? Theme.brass : Theme.outlineVariant }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dShort } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dShort } }
    }
    background:Face { radius:6; solid:true; usePlain:true; hovered:c.hovered; on:c.activeFocus || c.popup.visible
        plainColor:c.hovered?Theme.surfaceContainerHigh:Theme.surfaceContainerLow; plainBorder:c.activeFocus?Theme.glow:Theme.outlineVariant }
}
