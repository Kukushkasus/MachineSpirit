// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

// The bar: which modules it carries, in what order, on which screens.
ColumnLayout {
    id: page
    Layout.minimumWidth: 0
    spacing: 14
    readonly property var d: Settings.draft
    readonly property var names: ({clock: "Clock and date", instruments: "Processor, memory, network", caption: "Focused window", media: "Player", tray: "System tray"})
    readonly property var hints: ({clock: "Opens the calendar", instruments: "Opens the resource and network panels", caption: "The sector and the window in focus", media: "Shown while something plays", tray: "Shown while applications use it"})
    function order(key, all) { const on = page.d[key] || all; return on.concat(all.filter(k => !on.includes(k))) }
    function setOn(key, all, name, value) { const cur = (page.d[key] || all).slice(); Settings.set(key, value ? page.order(key, all).filter(k => cur.includes(k) || k === name) : cur.filter(k => k !== name)) }
    function move(key, all, name, by) {
        const cur = (page.d[key] || all).slice(), i = cur.indexOf(name), j = i + by
        if (i < 0 || j < 0 || j >= cur.length) return
        cur.splice(i, 1); cur.splice(j, 0, name); Settings.set(key, cur)
    }
    component ModuleList: ColumnLayout {
        id: list
        property string key: ""
        property var all: []
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: page.order(list.key, list.all)
            Rectangle {
                id: row
                required property string modelData
                readonly property bool on: (page.d[list.key] || list.all).includes(modelData)
                readonly property int at: (page.d[list.key] || list.all).indexOf(modelData)
                Layout.fillWidth: true; implicitHeight: 60; radius: 8; color: Qt.alpha(Theme.surfaceContainerLow, 0.5); border.color: Qt.alpha(Theme.outlineVariant, 0.6)
                RowLayout { anchors { fill: parent; leftMargin: 12; rightMargin: 12 } spacing: 8
                    DeckButton { text: "↑"; implicitWidth: 40; implicitHeight: 40; enabled: row.on && row.at > 0; onClicked: page.move(list.key, list.all, row.modelData, -1); ToolTip.visible: hovered; ToolTip.text: "Earlier on the bar" }
                    DeckButton { text: "↓"; implicitWidth: 40; implicitHeight: 40; enabled: row.on && row.at < (page.d[list.key] || list.all).length - 1; onClicked: page.move(list.key, list.all, row.modelData, 1); ToolTip.visible: hovered; ToolTip.text: "Later on the bar" }
                    DeckToggle { title: page.names[row.modelData]; hint: page.hints[row.modelData]; checked: row.on; onChanged: v => page.setOn(list.key, list.all, row.modelData, v) }
                }
            }
        }
    }
    DeckCard { title: "Left side"; subtitle: "After the cog. Top of the list sits nearest the screen edge."
        ModuleList { key: "barLeft"; all: ["clock", "instruments", "caption"] }
        DeckDivider {}
        DeckToggle { title: "Weather beside the clock"; hint: "Shown when the weather is known"; checked: page.d.barWeather !== false; enabled: (page.d.barLeft || ["clock"]).includes("clock"); onChanged: v => Settings.set("barWeather", v) }
        DeckDivider {}
        DeckToggle { title: "Network rate in figures"; hint: "Off leaves only the network mark"; checked: page.d.barNetRate !== false; enabled: (page.d.barLeft || ["instruments"]).includes("instruments"); onChanged: v => Settings.set("barNetRate", v) }
    }
    DeckCard { title: "Right side"; subtitle: "Before the controls, which always close the bar."
        ModuleList { key: "barRight"; all: ["media", "tray"] }
    }
    DeckCard { title: "Screens & density"
        DeckToggle { title: "Bar on every screen"; hint: "Off keeps it on the screen that hosts the panels (Displays)"; checked: page.d.barAllScreens !== false; onChanged: v => Settings.set("barAllScreens", v) }
        DeckDivider {}
        DeckSegments { title: "Density"; value: page.d.density || "comfortable"; onChanged: v => Settings.set("density", v)
            options: [{id: "comfortable", name: "Comfortable", hint: "Room between the bar's groups; the control desk shows its full rows."},
                      {id: "compact", name: "Compact", hint: "Tighter bar groups and a denser control desk. Controls keep their size."}] }
    }
}
