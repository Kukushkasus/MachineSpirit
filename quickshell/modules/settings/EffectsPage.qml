// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

// Ambient life: how much of it, how often, how fast. Readings and controls never wait for an effect.
ColumnLayout {
    id: page
    Layout.minimumWidth: 0
    spacing: 14
    readonly property var d: Settings.draft
    readonly property bool still: !!d.reducedMotion || !!d.lowPower
    DeckCard { title: "Ambient effects"; subtitle: "Sparks, discharges, screen flicker and the faction's own signs of life. They are rare and short at every level."
        DeckSegments { title: "Intensity"; value: "" + (page.d.fxLevel ?? 2); enabled: !page.still; opacity: enabled ? 1 : 0.5
            options: [{id: "0", name: "Off", hint: "No ambient effects at all."}, {id: "1", name: "Subtle", hint: "About half as often."},
                      {id: "2", name: "Normal", hint: "The intended rhythm."}, {id: "3", name: "Lively", hint: "More often. Still one effect at a time."}]
            onChanged: v => Settings.set("fxLevel", Number(v)) }
        DeckRange { title: "How often"; enabled: !page.still && (page.d.fxLevel ?? 2) > 0; opacity: enabled ? 1 : 0.5
            value: page.d.fxFrequency ?? 1; from: 0.5; to: 2; step: 0.1; decimals: 1; unit: "×"; onChanged: v => Settings.set("fxFrequency", Math.round(v * 10) / 10) }
        DeckText { visible: page.still; text: "Paused by Reduced motion or Low power below."; Layout.fillWidth: true; font.pixelSize: 12; color: Theme.hazard }
    }
    DeckCard { title: "Kinds of effect"; subtitle: "Turn off the ones you do not care for."; enabled: !page.still && (page.d.fxLevel ?? 2) > 0; opacity: enabled ? 1 : 0.5
        DeckToggle { title: "Discharges at the bar"; hint: "The faction's energy between the mounts: lightning, pulses, arcs"; checked: page.d.fxDischarge !== false; onChanged: v => Settings.set("fxDischarge", v) }
        DeckDivider {}
        DeckToggle { title: "Life on the screens"; hint: "A rare dip, sweep or shimmer on panels and widgets"; checked: page.d.fxScreens !== false; onChanged: v => Settings.set("fxScreens", v) }
        DeckDivider {}
        DeckToggle { title: "Particles"; hint: "Sparks and drops on notifications, popups and rites"; checked: page.d.fxParticles !== false; onChanged: v => Settings.set("fxParticles", v) }
        DeckDivider {}
        DeckToggle { title: "Atmospheric messages"; hint: "Short lines in the faction's voice after an update, a purge or a start"; checked: page.d.fxMessages !== false; onChanged: v => Settings.set("fxMessages", v) }
    }
    DeckCard { title: "Motion"
        DeckRange { title: "Animation speed"; value: page.d.animSpeed ?? 1; from: 0.5; to: 2; step: 0.1; decimals: 1; unit: "×"; onChanged: v => Settings.set("animSpeed", Math.round(v * 10) / 10) }
        DeckDivider {}
        DeckToggle { title: "Reduced motion"; hint: "No decorative movement, flicker or flashes; transitions are instant"; checked: !!page.d.reducedMotion; onChanged: v => Settings.set("reducedMotion", v) }
        DeckDivider {}
        DeckToggle { title: "Low power mode"; hint: "Pause ambient effects, glow, window animations, blur and shadows"; checked: !!page.d.lowPower; onChanged: v => Settings.set("lowPower", v) }
    }
}
