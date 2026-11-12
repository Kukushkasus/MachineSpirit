// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common
import qs.services

RowLayout {
    id:t; property string title:""; property string hint:""; property bool checked:false; signal changed(bool value)
    readonly property bool sought: Settings.sought !== "" && Settings.sought === title
    onSoughtChanged: if (sought) Settings.reveal(t)
    Layout.fillWidth:true; spacing:16
    opacity:enabled?1:0.5
    Behavior on opacity { NumberAnimation { duration:Theme.dShort } }
    ColumnLayout { spacing:3; Layout.fillWidth:true
        DeckText { text:t.title; Layout.fillWidth:true; color:t.sought?Theme.glow:Theme.surfaceOn }
        DeckText { text:t.hint; visible:text!==""; color:Theme.surfaceVariantOn; font.pixelSize:12; Layout.fillWidth:true }
    }
    Basic.Switch {
        id:sw; hoverEnabled:true;checked:t.checked; implicitWidth:46; implicitHeight:30; padding:0; onToggled:t.changed(checked)
        indicator:Item { width:46;height:26;y:2
          // other liveries: a slot with a shaped slider, gold square, lit diamond or iron block
          Item { anchors.fill:parent; visible:Skin.control!=="mechanicus"
            Face { anchors.fill:parent; solid:true; hovered:sw.hovered; on:sw.checked || sw.activeFocus }
            Poly { width:16;height:16;y:5;x:sw.checked?25:5
                Behavior on x { NumberAnimation {duration:Theme.dMedium;easing.type:Easing.BezierSpline;easing.bezierCurve:Theme.easeSpring} }
                points:Skin.control==="necrons"?[[8,0],[16,8],[8,16],[0,8]]:Skin.control==="ultramarines"?Skin.chamfer(16,16,4):Skin.iron(16,16,3,0)
                upper:sw.checked?(Skin.control==="ultramarines"?Theme.brassHi:Skin.control==="khorne"?Qt.lighter(Theme.glow,1.1):Theme.glow):Theme.outline
                lower:sw.checked?(Skin.control==="ultramarines"?Theme.brass:Skin.control==="khorne"?Theme.rust:Theme.glowDim):Qt.darker(Theme.outline,1.3)
                stroke:Skin.control==="khorne"?Theme.brass:"transparent";strokeWidth:1 }
          }
          Rectangle { anchors.fill:parent;visible:Skin.control==="mechanicus";radius:13;color:sw.checked?Qt.alpha(Theme.glow,sw.hovered?0.32:0.25):sw.hovered?Theme.surfaceContainerHigh:Theme.surfaceContainerHighest;border.color:sw.checked?Theme.glowDim:Theme.outlineVariant
            Behavior on color { ColorAnimation { duration:Theme.dShort } }
            Behavior on border.color { ColorAnimation { duration:Theme.dShort } }
            Rectangle { width:18;height:18;radius:9;y:4;x:sw.checked?24:4;color:sw.checked?Theme.glow:Theme.outline;Behavior on x { NumberAnimation {duration:Theme.dMedium;easing.type:Easing.BezierSpline;easing.bezierCurve:Theme.easeSpring} } Behavior on color { ColorAnimation { duration:Theme.dShort } } }
          }
        }
        background:Rectangle { color:"transparent";radius:15;border.color:sw.activeFocus?Theme.glow:"transparent" }
    }
}
