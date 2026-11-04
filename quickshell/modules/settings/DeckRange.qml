// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

ColumnLayout {
    id:r; property string title:""; property string unit:""; property real value:0; property real from:0; property real to:30; property real step:1; property int decimals:0; signal changed(real value)
    Layout.fillWidth:true; spacing:3
    RowLayout { Layout.fillWidth:true
        DeckText { text:r.title;Layout.fillWidth:true }
        DeckText { text:r.value.toFixed(r.decimals)+r.unit;color:Theme.glow;font.family:Theme.fontMono;font.pixelSize:12 }
    }
    Basic.Slider {
        id:sl; Layout.fillWidth:true;from:r.from;to:r.to;stepSize:r.step;value:r.value;implicitHeight:26;onMoved:r.changed(value)
        background:Rectangle { x:sl.leftPadding;y:sl.topPadding+sl.availableHeight/2-2;width:sl.availableWidth;height:4;radius:2;color:Theme.surfaceContainerHighest
            Rectangle {width:sl.visualPosition*parent.width;height:4;radius:2;color:Theme.glowDim}
        }
        handle:Rectangle {x:sl.leftPadding+sl.visualPosition*(sl.availableWidth-width);y:sl.topPadding+sl.availableHeight/2-height/2;width:16;height:16;radius:5;color:sl.pressed?Theme.glow:Theme.surfaceOn;border.width:sl.activeFocus?2:1;border.color:Theme.glowDim}
    }
}
