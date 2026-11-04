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
    background:Rectangle { radius:6; color:Theme.surfaceContainerLowest; border.color:f.activeFocus?Theme.glow:Theme.outlineVariant }
}
