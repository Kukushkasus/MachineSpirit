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

    // ---- identity anchors: never follow the wallpaper. They belong to the theme pack (ms-theme writes them
    // into colors.json); the names are the Mechanicus ones, the roles are the same in every faction.
    property color spark: "#5ab8ff"        // energy: lightning on the conduit
    property color rust: "#9a2a1a"         // danger: power, destructive actions
    property color rustText: "#ef6a50"     // danger readable on dark surfaces
    property color hazard: "#e0a800"       // warning stripes
    property color wax: "#8e1b14"          // seals
    property color brassLight: "#f0cf7a"   // trim: the cog
    property color brassDark: "#8d6a27"
    Behavior on spark { ColorAnimation { duration: 900 } }
    Behavior on rust { ColorAnimation { duration: 900 } }
    Behavior on rustText { ColorAnimation { duration: 900 } }
    Behavior on hazard { ColorAnimation { duration: 900 } }
    Behavior on wax { ColorAnimation { duration: 900 } }

    // ---- the theme pack: a decor kit built into the shell, tuned by the pack's data. A pack is validated
    // by ms-theme before it gets here and holds no code. Until one is read, this is Mechanicus as it always was.
    readonly property var packDefault: ({
        id: "mechanicus", name: "Adeptus Mechanicus", kit: "mechanicus", lexicon: {}, litanies: [],
        motion: {character: "mechanical", scale: 1, overshoot: 2.4},
        effects: {discharge: [3.5, 8.5], screenLife: [40, 120], particles: true, messages: true, glyphs: [90, 240]}
    })
    property var pack: packDefault
    readonly property var kits: ["mechanicus", "ultramarines", "necrons", "khorne"]
    readonly property string kit: kits.includes(pack.kit) ? pack.kit : "mechanicus"
    readonly property bool previewing: previewMeta !== null
    property var previewMeta: null
    // a decorative word from the pack, or the plain one. Never used for functions that must stay clear.
    function lex(key, fallback) { const v = pack.lexicon ? pack.lexicon[key] : undefined; return typeof v === "string" && v !== "" ? v : fallback }
    function litany() { const l = pack.litanies || []; return l.length ? l[Math.floor(Math.random() * l.length)] : "" }

    // ---- effects: how much ambient life the user wants (Settings), and how often the pack's effects come.
    // fxLevel 0 off, 1 subtle, 2 normal, 3 lively. Reduced motion and low power silence all of it.
    readonly property int fxLevel: !motionEnabled ? 0 : Math.max(0, Math.min(3, Settings.data.fxLevel ?? 2))
    readonly property real fxSlow: [1, 2.2, 1, 0.6][fxLevel] / Math.max(0.25, Math.min(2, Settings.data.fxFrequency ?? 1))
    function fxOn(kind) {
        if (fxLevel === 0) return false
        const user = {discharge: "fxDischarge", screenLife: "fxScreens", particles: "fxParticles", messages: "fxMessages", glyphs: "fxMessages"}[kind]
        if (user && Settings.data[user] === false) return false
        const e = pack.effects ? pack.effects[kind] : true
        return e !== false
    }
    // ms until the next occurrence of an ambient effect, from the pack's [min, max] seconds
    function fxDelay(kind, lo, hi) {
        const e = pack.effects ? pack.effects[kind] : null
        const a = Array.isArray(e) ? e[0] : lo, b = Array.isArray(e) ? e[1] : hi
        return (a + Math.random() * (b - a)) * 1000 * fxSlow
    }
    // One decorative effect at a time per screen-wide scheduler: ask before starting, so effects never pile up.
    property real fxBusyUntil: 0
    function fxClaim(ms) {
        const now = Date.now()
        if (now < fxBusyUntil) return false
        fxBusyUntil = now + ms + 400
        return true
    }

    // ---- shape: radius grows with the size of the thing
    readonly property int rPill: 999
    readonly property int r8: 8
    readonly property int r14: 14
    readonly property int r20: 20
    readonly property int r28: 28

    // ---- motion (Material 3)
    // the pack sets the character (a heavy faction moves slower), the user sets the overall speed
    readonly property real speed: Math.max(0.5, Math.min(2, Settings.data.animSpeed ?? 1))
    readonly property real tempo: (pack.motion?.scale ?? 1) / speed
    readonly property string motionChar: pack.motion?.character ?? "mechanical"
    readonly property real overshoot: pack.motion?.overshoot ?? 0
    readonly property int dShort: Settings.data.reducedMotion ? 0 : Math.round(120 * tempo)
    readonly property int dMedium: Settings.data.reducedMotion ? 0 : lowPower ? 120 : Math.round(180 * tempo)
    readonly property int dLong: Settings.data.reducedMotion ? 0 : lowPower ? 120 : Math.round(240 * tempo)
    readonly property int dClose: Settings.data.reducedMotion ? 0 : lowPower ? 100 : Math.round(160 * tempo)
    // how a panel arrives: mechanical settles with a small overshoot, precise stops dead, phase eases both ways, heavy lands late
    readonly property int easeEnter: motionChar === "precise" ? Easing.OutQuart : motionChar === "phase" ? Easing.InOutSine : motionChar === "heavy" ? Easing.OutQuint : Easing.OutCubic
    readonly property var easeStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var easeDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var easeAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    // spatial curves with a little spring, by character: a relay snaps past its stop, a heavy plate lands and settles
    readonly property var easeSpring: motionChar === "precise" ? [0.16, 1, 0.3, 1, 1, 1]          // straight in, dead stop
        : motionChar === "phase" ? [0.45, 0, 0.2, 1, 1, 1]                                          // slow start, glide
        : motionChar === "heavy" ? [0.3, 1.45, 0.4, 0.96, 1, 1]                                     // overshoots, falls back
        : [0.38, 1.3, 0.3, 1, 1, 1]                                                                 // mechanical kick
    // the arrival of a large window and the reveal of its parts (0 with reduced motion, short with low power)
    readonly property int dEnter: Settings.data.reducedMotion ? 0 : lowPower ? 140 : Math.round((motionChar === "heavy" ? 460 : motionChar === "phase" ? 440 : motionChar === "precise" ? 340 : 380) * tempo)
    readonly property int dExit: Settings.data.reducedMotion ? 0 : lowPower ? 100 : Math.round(170 * tempo)
    readonly property int dStagger: !motionEnabled ? 0 : Math.round((motionChar === "precise" ? 34 : motionChar === "phase" ? 46 : motionChar === "heavy" ? 52 : 40) * tempo)
    // the decorative part of an arrival (a pulse along the trim, a scan, a heat sheen): only with motion and effects on
    readonly property bool arrivals: motionEnabled && fxLevel > 0 && Settings.data.fxArrivals !== false

    // ---- the user's own trim (Settings > Appearance)
    readonly property real panelOpacity: Math.max(0.6, Math.min(1, Settings.data.panelOpacity ?? 1))
    readonly property real glowStrength: Math.max(0, Math.min(1.5, Settings.data.glowStrength ?? 1))
    readonly property bool compact: Settings.data.density === "compact"
    // 2 full: seals, heraldry, guardians, everything. 1 reduced: the structural decor only. 0 off: plain instruments.
    readonly property int ornaments: Settings.data.ornaments === "off" ? 0 : Settings.data.ornaments === "reduced" ? 1 : 2

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
        if (!text || !text.trim()) return      // caught between two writes; the finished file follows
        try {
            const j = JSON.parse(text)
            for (const k in j) {
                const p = toCamel(k)
                if (root[p] !== undefined) root[p] = j[k]
            }
        } catch (e) { console.warn("theme: bad colors.json", e) }
    }

    // ---- sources. The applied theme lives in the state folder; a preview lives in the runtime folder
    // (XDG_RUNTIME_DIR), apart from every permanent file, and wins while it is there.
    readonly property string previewDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/machinespirit/preview"
    property string appliedColors: ""
    property string appliedPack: ""
    function applyPack(text) {
        try {
            const j = JSON.parse(text)
            if (!j || typeof j !== "object" || !kits.includes(j.kit)) throw new Error("unknown kit")
            pack = Object.assign({}, packDefault, j)
        } catch (e) { console.warn("theme: bad pack, keeping Mechanicus", e); pack = packDefault }
    }
    function restoreApplied() {
        previewMeta = null
        if (appliedPack) applyPack(appliedPack); else pack = packDefault
        if (appliedColors) applyColors(appliedColors)
    }
    FileView {
        path: root.stateDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.appliedColors = text(); if (!root.previewing) root.applyColors(text()) }
    }
    FileView {
        path: root.stateDir + "/pack.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.appliedPack = text(); if (!root.previewing) root.applyPack(text()) }
        onLoadFailed: { root.appliedPack = ""; if (!root.previewing) root.pack = root.packDefault }
    }
    // meta.json is written last and removed first, so the other two are whole whenever it is seen.
    // A preview is shown only when this very shell asked for it (ThemePacks arms it): one left behind by a
    // crashed shell is never picked up, it is discarded at start.
    property bool previewArmed: false
    function loadPreview() { previewArmed = true; pvMeta.reload() }
    function endPreview() { previewArmed = false; if (previewing) restoreApplied() }
    FileView { id: pvColors; path: root.previewDir + "/colors.json"; blockLoading: true; printErrors: false }
    FileView { id: pvPack; path: root.previewDir + "/pack.json"; blockLoading: true; printErrors: false }
    FileView {
        id: pvMeta
        path: root.previewDir + "/meta.json"
        watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: {
            if (!root.previewArmed) return
            try {
                const m = JSON.parse(text())
                if (!m.token || (m.expires || 0) * 1000 < Date.now()) throw new Error("stale")
                pvColors.reload(); pvPack.reload()
                const c = pvColors.text(), k = pvPack.text()
                JSON.parse(c); JSON.parse(k)
                root.previewMeta = m
                root.applyPack(k); root.applyColors(c)
            } catch (e) { console.warn("theme: preview dropped", e); root.endPreview() }
        }
        onLoadFailed: if (root.previewing) root.endPreview()
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
