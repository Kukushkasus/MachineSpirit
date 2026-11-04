// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

RowLayout {
    id:t; property string title:""; property string hint:""; property bool checked:false; signal changed(bool value)
    Layout.fillWidth:true; spacing:16
    ColumnLayout { spacing:3; Layout.fillWidth:true
        DeckText { text:t.title; Layout.fillWidth:true }
        DeckText { text:t.hint; visible:text!==""; color:Theme.surfaceVariantOn; font.pixelSize:12; Layout.fillWidth:true }
    }
    Basic.Switch {
        id:sw; checked:t.checked; implicitWidth:46; implicitHeight:30; padding:0; onToggled:t.changed(checked)
        indicator:Rectangle { width:46;height:26;y:2;radius:13;color:sw.checked?Qt.alpha(Theme.glow,0.25):Theme.surfaceContainerHighest;border.color:sw.checked?Theme.glowDim:Theme.outlineVariant
            Rectangle { width:18;height:18;radius:9;y:4;x:sw.checked?24:4;color:sw.checked?Theme.glow:Theme.outline;Behavior on x { NumberAnimation {duration:Theme.dShort} } }
        }
        background:Rectangle { color:"transparent";radius:15;border.color:sw.activeFocus?Theme.glow:"transparent" }
    }
}
