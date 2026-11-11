// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

// Desktop instruments. These are saved at once (they have their own state file), unlike the rest of Settings.
ColumnLayout {
    id: page
    Layout.minimumWidth: 0
    spacing: 14
    readonly property var d: Settings.draft
    DeckCard { title: "Instruments on the desktop"; subtitle: "Changes here take effect immediately."
        Repeater {
            model: DesktopWidgets.catalog
            ColumnLayout {
                id: w
                required property var modelData
                required property int index
                readonly property var cfg: DesktopWidgets.state.widgets[modelData.key] || ({enabled: false, scale: 1})
                Layout.fillWidth: true; spacing: 10
                DeckDivider { visible: w.index > 0 }
                DeckToggle { title: Theme.lex(w.modelData.key, w.modelData.name); hint: ({clock: "Time and date", weather: "Weather now and ahead", resources: "Processor, memory and network traces", media: "What is playing", notes: "A note that stays on the desk"})[w.modelData.key]
                    checked: !!w.cfg.enabled; enabled: DesktopWidgets.loaded && !DesktopWidgets.blocked; onChanged: v => DesktopWidgets.change(w.modelData.key, {enabled: v}) }
                DeckRange { visible: !!w.cfg.enabled; title: "Size"; value: Math.round((w.cfg.scale ?? 1) * 100); from: 70; to: 150; step: 5; unit: "%"
                    onChanged: v => DesktopWidgets.change(w.modelData.key, {scale: Math.round(v) / 100}) }
            }
        }
        DeckDivider {}
        DeckToggle { title: "Seconds on the clock"; checked: !!DesktopWidgets.state.seconds; onChanged: v => DesktopWidgets.seconds(v) }
        DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: DesktopWidgets.error ? Theme.rustText : Theme.surfaceVariantOn; text: DesktopWidgets.status }
    }
    DeckCard { title: "Arrangement"
        RowLayout { Layout.fillWidth: true; spacing: 8
            DeckButton { text: "Arrange on the desktop ↗"; Layout.fillWidth: true; implicitHeight: 42; onClicked: { if (Settings.dirty) Settings.requestClose(); else { Settings.open = false; DesktopWidgets.toggle() } } }
            DeckButton { text: "Default places"; Layout.fillWidth: true; implicitHeight: 42; enabled: DesktopWidgets.loaded && !DesktopWidgets.blocked; onClicked: DesktopWidgets.reset() }
        }
        DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn; text: "Drag instruments where you want them. Super+Alt+W opens the same editor." }
    }
    DeckCard { title: "Finish"; subtitle: "Applied with the rest of Settings."
        DeckToggle { title: "Scan line"; hint: "A faint sweep across an instrument every minute or two"; checked: page.d.widgetScan !== false; onChanged: v => Settings.set("widgetScan", v) }
    }
}
