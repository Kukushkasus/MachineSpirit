// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services
import Quickshell

// Notifications. Quiet mode itself has one switch, on the control desk; here is how messages behave around it.
ColumnLayout {
    id: page
    Layout.minimumWidth: 0
    spacing: 14
    readonly property var d: Settings.draft
    DeckCard { title: "Pop-ups"
        DeckRange { title: "Stay on screen"; value: page.d.toastSeconds ?? 6; from: 2; to: 30; unit: " s"; onChanged: v => Settings.set("toastSeconds", Math.round(v)) }
        DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn; text: "Used when the application does not ask for its own time." }
        DeckDivider {}
        DeckRange { title: "At most at once"; value: page.d.toastMax ?? 4; from: 1; to: 6; onChanged: v => Settings.set("toastMax", Math.round(v)) }
    }
    DeckCard { title: "Quiet mode"; subtitle: "Switched on the control desk (" + (Notifs.dnd ? "on now" : "off now") + "). Messages are still kept in the log."
        DeckToggle { title: "Urgent messages break through"; hint: "Critical notifications still pop up while quiet mode is on"; checked: page.d.urgentThroughQuiet !== false; onChanged: v => Settings.set("urgentThroughQuiet", v) }
    }
    DeckCard { title: "Log"
        DeckRange { title: "Messages kept"; value: page.d.historyLimit ?? 100; from: 10; to: 300; step: 10; onChanged: v => Settings.set("historyLimit", Math.round(v)) }
        DeckText { Layout.fillWidth: true; font.pixelSize: 12; color: Theme.surfaceVariantOn; text: "When the log is full the oldest message leaves. " + Notifs.all.length + " kept now." }
        DeckButton { text: "Send a test message"; onClicked: Quickshell.execDetached(["notify-send", "-a", "MachineSpirit", "Test message", "This is how a notification looks."]) }
    }
}
