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
    color:Qt.alpha(Theme.surfaceContainerLow,0.34); radius:10; border.color:Qt.alpha(Theme.outlineVariant,0.65)
    ColumnLayout {
        id:content; anchors { left:parent.left; right:parent.right; top:parent.top; margins:18 } spacing:14
        ColumnLayout { Layout.fillWidth:true; spacing:4; visible:card.title!==""
            DeckText { text:card.title; font.pixelSize:16; font.weight:Font.DemiBold; Layout.fillWidth:true }
            DeckText { text:card.subtitle; visible:text!==""; color:Theme.surfaceVariantOn; font.pixelSize:12; Layout.fillWidth:true }
        }
        ColumnLayout { id:body; Layout.fillWidth:true; spacing:14 }
    }
}
