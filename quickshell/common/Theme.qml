pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

// Design tokens. Colour roles follow Material 3 and come from the wallpaper (`ms-theme`, matugen),
// picked up live from colors.json. QML reserves on<Name>, so "on_primary" is exposed as primaryOn.
Singleton {
    id: root

    // ---- colour roles
    property color background: "#080604"
    property color surface: "#080604"
    property color surfaceDim: "#080604"
    property color surfaceBright: "#342e27"
    property color surfaceContainerLowest: "#010000"
    property color surfaceContainerLow: "#120e0b"
    property color surfaceContainer: "#18130f"
    property color surfaceContainerHigh: "#241d19"
    property color surfaceContainerHighest: "#302823"
    property color surfaceVariant: "#463a32"
    property color surfaceTint: "#f8b473"
    property color backgroundOn: "#edded3"
    property color surfaceOn: "#edded3"
    property color surfaceVariantOn: "#d1c0b3"
    property color outline: "#97887b"
    property color outlineVariant: "#463a32"
    property color primary: "#f8b473"
    property color primaryOn: "#341c00"
    property color primaryContainer: "#573100"
    property color primaryContainerOn: "#fddabd"
    property color primaryFixed: "#fddabd"
    property color primaryFixedDim: "#f8b473"
    property color secondary: "#debca1"
    property color secondaryOn: "#312112"
    property color secondaryContainer: "#4c3826"
    property color secondaryContainerOn: "#fddabd"
    property color tertiary: "#bdc896"
    property color tertiaryOn: "#1e240a"
    property color tertiaryContainer: "#363e1d"
    property color tertiaryContainerOn: "#dae5b2"
    property color error: "#fbb1a8"
    property color errorOn: "#490003"
    property color errorContainer: "#760008"
    property color errorContainerOn: "#fdd8d4"
    property color inverseSurface: "#edded3"
    property color inverseOnSurface: "#2a241f"
    property color inversePrimary: "#774a16"
    property color scrim: "#000000"
    property color shadow: "#000000"
    property color sourceColor: "#b0702a"

    // ---- forge materials (also generated from the wallpaper by ms-theme)
    property color metalLo: "#1f1b10"
    property color metal: "#353024"
    property color metalHi: "#585244"
    property color metalEdge: "#979080"
    property color brassLo: "#5a3d00"
    property color brass: "#b88a3e"
    property color brassHi: "#f0c37c"
    property color glass: "#13110c"
    property color glassHi: "#1e1b16"
    property color glow: "#ffe07f"
    property color glowDim: "#c9a82f"
    property color glowFaint: "#725c00"

    // the whole shell fades into a new scheme instead of snapping
    Behavior on background { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surface { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceDim { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceBright { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainerLowest { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainerLow { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainer { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainerHigh { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceContainerHighest { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceVariant { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceTint { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on backgroundOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on surfaceVariantOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on outline { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on outlineVariant { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on primary { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on primaryOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on primaryContainer { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on primaryContainerOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on primaryFixed { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on primaryFixedDim { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on secondary { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on secondaryOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on secondaryContainer { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on secondaryContainerOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on tertiary { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on tertiaryOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on tertiaryContainer { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on tertiaryContainerOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on error { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on errorOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on errorContainer { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on errorContainerOn { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on inverseSurface { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on inverseOnSurface { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on inversePrimary { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on scrim { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on shadow { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on sourceColor { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on metalLo { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on metal { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on metalHi { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on metalEdge { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on brassLo { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on brass { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on brassHi { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on glass { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on glassHi { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on glow { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on glowDim { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on glowFaint { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }

    // ---- identity anchors: never follow the wallpaper
    readonly property color spark: "#5ab8ff"        // lightning on the conduit
    readonly property color rust: "#9a2a1a"         // power, destructive actions
    readonly property color rustText: "#ef6a50"     // rust readable on dark surfaces
    readonly property color hazard: "#e0a800"       // warning stripes
    readonly property color wax: "#8e1b14"          // purity seals
    readonly property color brassLight: "#f0cf7a"   // the cog
    readonly property color brassDark: "#8d6a27"

    // ---- shape: radius grows with the size of the thing
    readonly property int rPill: 999
    readonly property int r8: 8
    readonly property int r14: 14
    readonly property int r20: 20
    readonly property int r28: 28

    // ---- motion (Material 3)
    readonly property int dShort: Settings.data.reducedMotion ? 0 : 120
    readonly property int dMedium: Settings.data.reducedMotion ? 0 : 200
    readonly property int dLong: Settings.data.reducedMotion ? 0 : 280
    readonly property var easeStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var easeDecel: [0.05, 0.7, 0.1, 1, 1, 1]

    // ---- state layers
    readonly property real hoverLayer: 0.08
    readonly property real pressLayer: 0.12

    // ---- type: one family, two widths. Condensed carries numbers and headings.
    readonly property string fontUi: "IBM Plex Sans"
    readonly property string fontNum: "IBM Plex Sans Condensed"
    readonly property string fontGothic: "UnifrakturCook"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontIcon: "Material Symbols Outlined"

    readonly property int workspaces: 10
    readonly property int barMargin: 8
    // FX.low_power in hypr/local.lua: no continuous animation
    readonly property bool motionEnabled: !lowPower && !Settings.data.reducedMotion
    readonly property bool lowPower: Quickshell.env("MS_LOW_POWER") === "1" || !!Settings.data.lowPower

    // ---- wallpaper / theme metadata
    property string wallpaper: ""
    property string sourceWallpaper: ""
    property int stamp: 0

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/machinespirit"

    function toCamel(k) {
        const on = k.startsWith("on_")
        const camel = (on ? k.slice(3) : k).replace(/_([a-z])/g, (m, c) => c.toUpperCase())
        return on ? camel + "On" : camel
    }
    function applyColors(text) {
        try {
            const j = JSON.parse(text)
            for (const k in j) {
                const p = toCamel(k)
                if (root[p] !== undefined) root[p] = j[k]
            }
        } catch (e) { console.warn("theme: bad colors.json", e) }
    }

    FileView {
        path: root.stateDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyColors(text())
    }
    FileView {
        path: root.stateDir + "/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const j = JSON.parse(text())
                root.wallpaper = j.wallpaper || ""
                root.sourceWallpaper = j.source_wallpaper || ""
                root.stamp = j.stamp || 0
            } catch (e) {}
        }
    }
}
