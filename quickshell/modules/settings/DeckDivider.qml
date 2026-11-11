// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import qs.common

// A rule between groups: a faint line (mechanicus), a gilt rule with a lozenge (ultramarines), a thread of light
// with a node (necrons), a brass bar (khorne).
Item {
    Layout.fillWidth: true; implicitHeight: Skin.card === "mechanicus" ? 1 : 7
    Rectangle { visible: Skin.card === "mechanicus"; anchors.fill: parent; color: Theme.outlineVariant; opacity: 0.45 }
    Rectangle { visible: Skin.card !== "mechanicus"; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: Skin.card === "khorne" ? 2 : 1
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Skin.card === "necrons" ? Qt.alpha(Theme.glow, 0.5) : Qt.alpha(Theme.brass, 0.7) }
            GradientStop { position: 1; color: "transparent" } } }
    Rectangle { visible: Skin.card === "ultramarines" || Skin.card === "necrons"; anchors.centerIn: parent; width: 6; height: 6; rotation: 45
        color: Skin.card === "necrons" ? Theme.glow : Theme.brassHi }
}
