// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

Basic.Button {
    id: b
    property bool accent: false
    scale: down ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: Theme.dShort; easing.type: Easing.OutCubic } }
    implicitHeight: 38; implicitWidth: Math.max(90, contentItem.implicitWidth + 28)
    hoverEnabled: true; font.family: Theme.fontUi; font.pixelSize: 13
    contentItem: Text { text:b.text; font:b.font; color: !b.enabled ? Theme.outline : b.accent ? (Skin.control === "mechanicus" ? Theme.glass : Theme.glow) : Theme.surfaceOn; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter }
    background: Face { radius:6; solid:true; usePlain:true; hovered:b.hovered; pressed:b.down; on:b.accent || b.activeFocus
        plainColor:b.accent ? (b.down ? Theme.glowDim : b.hovered ? Qt.lighter(Theme.glow, 1.12) : Theme.glow) : b.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow; plainBorder:b.activeFocus ? Theme.glow : b.accent ? Theme.glow : Theme.outlineVariant
        opacity:b.enabled?1:0.5; Behavior on opacity { NumberAnimation { duration:Theme.dShort } } }
}
