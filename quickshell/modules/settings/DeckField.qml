// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

Basic.TextField {
    id:f; implicitHeight:42; leftPadding:12; rightPadding:12
    color:Theme.surfaceOn; placeholderTextColor:Theme.outline; selectionColor:Theme.primaryContainer; selectedTextColor:Theme.primaryContainerOn
    font.family:Theme.fontUi; font.pixelSize:14
    hoverEnabled:true; opacity:enabled?1:0.5
    Behavior on opacity { NumberAnimation { duration:Theme.dShort } }
    background:Face { radius:6; solid:true; usePlain:true; hovered:f.hovered; on:f.activeFocus
        plainColor:Theme.surfaceContainerLowest; plainBorder:f.activeFocus?Theme.glow:f.hovered?Theme.outline:Theme.outlineVariant }
}
