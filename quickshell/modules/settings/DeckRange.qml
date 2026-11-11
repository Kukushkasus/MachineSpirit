// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
    id:r; property string title:""; property string unit:""; property real value:0; property real from:0; property real to:30; property real step:1; property int decimals:0; signal changed(real value)
    readonly property bool sought: Settings.sought !== "" && Settings.sought === title
    onSoughtChanged: if (sought) Settings.reveal(r)
    Layout.fillWidth:true; spacing:3
    RowLayout { Layout.fillWidth:true
        DeckText { text:r.title;Layout.fillWidth:true;color:r.sought?Theme.glow:Theme.surfaceOn }
        DeckText { text:r.value.toFixed(r.decimals)+r.unit;color:Theme.glow;font.family:Theme.fontMono;font.pixelSize:12 }
    }
    Basic.Slider {
        id:sl; Layout.fillWidth:true;from:r.from;to:r.to;stepSize:r.step;value:r.value;implicitHeight:26;onMoved:r.changed(value)
        background:Item { x:sl.leftPadding;y:sl.topPadding+sl.availableHeight/2-2;width:sl.availableWidth;height:4
          Rectangle { visible:Skin.control==="mechanicus";anchors.fill:parent;radius:2;color:Theme.surfaceContainerHighest
            Rectangle {width:sl.visualPosition*parent.width;height:4;radius:2;color:Theme.glowDim} }
          // other liveries: a ruled channel (gold), a thread of light, an iron groove
          Rectangle { visible:Skin.control!=="mechanicus";y:-1;width:parent.width;height:6;color:Skin.control==="necrons"?"transparent":Qt.darker(Theme.metal,1.4)
            border { width:1; color:Skin.control==="ultramarines"?Qt.alpha(Theme.brass,0.6):Skin.control==="khorne"?Theme.brassLo:Qt.alpha(Theme.glowDim,0.4) }
            Rectangle { x:1;y:Skin.control==="necrons"?2:1;height:Skin.control==="necrons"?2:4;width:sl.visualPosition*(parent.width-2);color:Skin.control==="khorne"?Theme.rustText:Theme.glow } }
        }
        handle:Item {x:sl.leftPadding+sl.visualPosition*(sl.availableWidth-width);y:sl.topPadding+sl.availableHeight/2-height/2;width:16;height:16
          Rectangle { visible:Skin.control==="mechanicus";anchors.fill:parent;radius:5;color:sl.pressed?Theme.glow:Theme.surfaceOn;border.width:sl.activeFocus?2:1;border.color:Theme.glowDim
            Behavior on color { ColorAnimation { duration:Theme.dShort } } }
          Poly { visible:Skin.control!=="mechanicus";anchors.fill:parent
            points:Skin.control==="necrons"?[[8,0],[16,8],[8,16],[0,8]]:Skin.control==="ultramarines"?[[0,0],[16,0],[16,10],[8,16],[0,10]]:Skin.iron(16,16,3,0)
            upper:Skin.control==="ultramarines"?Theme.brassHi:Skin.control==="khorne"?Theme.brass:Theme.glow
            lower:Skin.control==="ultramarines"?Theme.brass:Skin.control==="khorne"?Theme.brassLo:Theme.glowDim
            stroke:sl.activeFocus||sl.pressed?Theme.surfaceOn:"transparent";strokeWidth:1.5 } }
    }
}
