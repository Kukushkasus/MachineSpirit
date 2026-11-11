// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

Rectangle {
    id:card
    property string title:""
    property string subtitle:""
    default property alias contents:body.data
    Layout.fillWidth:true; Layout.minimumWidth:0; implicitHeight:content.implicitHeight+36
    readonly property bool plain: Skin.card === "mechanicus"
    color:plain?Qt.alpha(Theme.surfaceContainerLow,0.34):"transparent"; radius:10; border.color:plain?Qt.alpha(Theme.outlineVariant,0.65):"transparent"
    // other liveries draw the card as their own section
    SectionFrame { anchors.fill:parent; visible:!card.plain; fill:Qt.alpha(Theme.glass,0.5); rim:Qt.alpha(Theme.outlineVariant,0.65) }
    ColumnLayout {
        id:content; anchors { left:parent.left; right:parent.right; top:parent.top; margins:18 } spacing:14
        ColumnLayout { Layout.fillWidth:true; spacing:4; visible:card.title!==""
            DeckText { text:card.title; font.family:card.plain?Theme.fontUi:Skin.display(card.title); font.pixelSize:card.plain?16:Skin.type==="necrons"?13:Skin.type==="khorne"?20:16
                font.weight:card.plain?Font.DemiBold:Skin.titleWeight; font.letterSpacing:card.plain?0:Skin.type==="khorne"?0.5:1.5; font.capitalization:card.plain||Skin.type==="khorne"?Font.MixedCase:Font.AllUppercase
                color:card.plain?Theme.surfaceOn:Skin.type==="ultramarines"||Skin.type==="khorne"?Theme.brassHi:Theme.glow; Layout.fillWidth:true }
            DeckText { text:card.subtitle; visible:text!==""; color:Theme.surfaceVariantOn; font.pixelSize:12; Layout.fillWidth:true }
        }
        ColumnLayout { id:body; Layout.fillWidth:true; spacing:14 }
    }
}
