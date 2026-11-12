// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

// Theme packs. A preview dresses the running shell for a short while and saves nothing; keeping it applies the
// pack for good. Packs never change the wallpaper: recommended ones are offered separately below.
ColumnLayout {
    id: page
    Layout.minimumWidth: 0
    spacing: 14
    property string mode: ThemePacks.mode          // the colour mode chosen here, used by Preview and Apply
    Connections { target: ThemePacks; function onModeChanged() { page.mode = ThemePacks.mode } }
    readonly property var shown: ThemePacks.pack(ThemePacks.previewId || ThemePacks.active)
    readonly property var good: ThemePacks.packs.filter(p => p.ok)
    readonly property var bad: ThemePacks.packs.filter(p => !p.ok)
    onVisibleChanged: if (visible) ThemePacks.refresh()

    // while a preview runs: what is showing, how long is left, and the two ways out
    Rectangle {
        visible: ThemePacks.previewing
        Layout.fillWidth: true; implicitHeight: bannerRow.implicitHeight + 28; radius: 10
        color: Qt.alpha(Theme.hazard, 0.10); border.color: Qt.alpha(Theme.hazard, 0.7)
        RowLayout {
            id: bannerRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 } spacing: 12
            ColumnLayout { Layout.fillWidth: true; spacing: 3
                DeckText { Layout.fillWidth: true; font.pixelSize: 16; font.weight: Font.DemiBold
                    text: "Previewing " + ((ThemePacks.pack(ThemePacks.previewId) || {}).name || ThemePacks.previewId) }
                DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn
                    text: "Nothing is saved yet. The previous theme returns in " + ThemePacks.countdown + " s unless you keep this one." }
            }
            DeckButton { text: "Cancel"; onClicked: ThemePacks.cancel() }
            DeckButton { text: "Keep this theme"; accent: true; enabled: !ThemePacks.busy; onClicked: ThemePacks.apply("", "") }
        }
    }

    DeckCard {
        title: "Colours"; subtitle: "How much the wallpaper decides. A faction keeps its marks and materials in every mode."
        DeckSegments { options: ThemePacks.modes; value: page.mode; onChanged: v => page.mode = v }
        DeckButton { visible: page.mode !== ThemePacks.mode && !ThemePacks.previewing; text: "Use this colour mode now"; enabled: !ThemePacks.busy
            onClicked: ThemePacks.apply(ThemePacks.active, page.mode) }
    }

    GridLayout {
        Layout.fillWidth: true; columns: page.width > 620 ? 2 : 1; columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: page.good
            Rectangle {
                id: card
                required property var modelData
                readonly property bool active: ThemePacks.active === modelData.id
                readonly property bool previewed: ThemePacks.previewId === modelData.id
                Layout.fillWidth: true; Layout.preferredWidth: 10; implicitHeight: col.implicitHeight + 28; radius: 10
                color: Qt.alpha(Theme.surfaceContainerLow, 0.4)
                border.width: active || previewed ? 2 : 1
                border.color: previewed ? Theme.hazard : active ? Theme.glowDim : Qt.alpha(Theme.outlineVariant, 0.7)
                ColumnLayout {
                    id: col
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 } spacing: 10
                    // the pack's own picture, or its materials when it ships none
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 132; radius: 7; clip: true; color: card.modelData.materials.glass || "#0c0c0c"
                        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
                        Image { anchors.fill: parent; visible: card.modelData.preview !== ""; source: card.modelData.preview ? "file://" + card.modelData.preview : ""
                            fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 640 }
                        Row { visible: card.modelData.preview === ""; anchors.centerIn: parent; spacing: 8
                            Repeater { model: [card.modelData.seed, card.modelData.anchors.energy, card.modelData.anchors.trimLight, card.modelData.anchors.danger, card.modelData.anchors.warn]
                                Rectangle { required property string modelData; width: 34; height: 34; radius: 8; color: modelData; border.color: Qt.rgba(1, 1, 1, 0.18) } } }
                    }
                    RowLayout { Layout.fillWidth: true; spacing: 8
                        DeckText { text: card.modelData.name; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                        // one mark of state, only on the pack it belongs to
                        Rectangle { visible: card.active || card.previewed; implicitWidth: chip.implicitWidth + 16; implicitHeight: 22; radius: 11
                            color: Qt.alpha(card.previewed ? Theme.hazard : Theme.glow, 0.14)
                            DeckText { id: chip; anchors.centerIn: parent; font.family: Theme.fontMono; font.pixelSize: 11; font.letterSpacing: 1
                                text: card.previewed ? "PREVIEW" : "ACTIVE"; color: card.previewed ? Theme.hazard : Theme.glow } }
                    }
                    DeckText { text: card.modelData.tagline; Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn; maximumLineCount: 3; elide: Text.ElideRight }
                    DeckText { visible: !card.modelData.builtin; text: "Your pack · by " + card.modelData.author; Layout.fillWidth: true; font.pixelSize: 11; color: Theme.outline }
                    RowLayout { Layout.fillWidth: true; spacing: 8
                        DeckButton { text: card.previewed ? "Previewing…" : "Preview"; Layout.fillWidth: true; implicitHeight: 42
                            enabled: !ThemePacks.busy && !card.previewed && !(card.active && page.mode === ThemePacks.mode)
                            onClicked: ThemePacks.preview(card.modelData.id, page.mode) }
                        DeckButton { text: card.previewed ? "Keep" : "Apply"; accent: true; Layout.fillWidth: true; implicitHeight: 42
                            enabled: !ThemePacks.busy && (card.previewed || !card.active || page.mode !== ThemePacks.mode)
                            onClicked: ThemePacks.apply(card.modelData.id, page.mode) }
                    }
                }
            }
        }
    }

    DeckCard {
        visible: !!page.shown && page.shown.wallpapers.length > 0
        title: "Wallpapers for " + (page.shown ? page.shown.name : ""); subtitle: "A theme never replaces your wallpaper by itself. Pick one here if you want it."
        Flow {
            Layout.fillWidth: true; spacing: 10
            Repeater {
                model: page.shown ? page.shown.wallpapers : []
                Rectangle {
                    id: wp
                    required property var modelData
                    width: 208; height: 150; radius: 8; color: Theme.surfaceContainerLowest; border.color: wpHover.hovered ? Theme.glowDim : Theme.outlineVariant; clip: true
                    HoverHandler { id: wpHover }
                    Image { x: 1; y: 1; width: parent.width - 2; height: 116; source: "file://" + wp.modelData.file; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 416 }
                    DeckText { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 9 } font.pixelSize: 12; elide: Text.ElideRight; wrapMode: Text.NoWrap
                        text: wp.modelData.name + (wp.modelData.draft ? " · draft" : ""); color: Theme.surfaceVariantOn }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: Walls.applying === "" && !ThemePacks.previewing
                        onClicked: Walls.apply({id: wp.modelData.file, full: wp.modelData.file, local: true}) }
                }
            }
        }
        DeckText { visible: ThemePacks.previewing; text: "Keep or cancel the preview before changing the wallpaper."; Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn }
    }

    DeckCard {
        title: "Way back"
        RowLayout { Layout.fillWidth: true; spacing: 8
            DeckButton { text: "Return to the previous theme"; Layout.fillWidth: true; enabled: !ThemePacks.busy && !ThemePacks.locked; onClicked: ThemePacks.revert() }
            DeckButton { text: "Reset to Adeptus Mechanicus"; Layout.fillWidth: true; enabled: !ThemePacks.busy && ThemePacks.active !== "mechanicus"; onClicked: ThemePacks.apply("mechanicus", ThemePacks.mode) }
        }
        DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: ThemePacks.error ? Theme.rustText : Theme.surfaceVariantOn
            text: ThemePacks.error || ThemePacks.status || "If a theme cannot be applied, the one before it stays in place." }
    }

    DeckCard {
        visible: page.bad.length > 0
        title: "Packs that cannot be used"; subtitle: "Found in your themes folder, but not loaded."
        Repeater { model: page.bad
            RowLayout { required property var modelData; Layout.fillWidth: true; spacing: 10
                Icon { name: "block"; size: 18; color: Theme.rustText }
                DeckText { text: modelData.id; font.family: Theme.fontMono; font.pixelSize: 12 }
                DeckText { text: modelData.error; Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn }
            }
        }
    }
    DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.outline
        text: "Your own packs live in ~/.local/share/machinespirit/themes/<id>/. A pack is a theme.json and pictures; it cannot run code." }
}
