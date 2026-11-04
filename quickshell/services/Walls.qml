pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import Quickshell
import Quickshell.Io

// Pict archive: talks to `ms-walls` (sources, search, download, apply).
Singleton {
    id: root
    property bool open: false
    function toggle() { open = !open; if (open) { Settings.open = false; Sanctum.close(); Popups.close(); Launcher.close(); Power.close(); if (items.length === 0) search() } }
    function close() { open = false }

    readonly property var sources: [
        { id: "local",     name: "Local",     needsKey: false, colors: true,  sorts: ["latest", "random"] },
        { id: "wallhaven", name: "Wallhaven", needsKey: false, colors: true,  sorts: ["top", "latest", "random", "relevance"] },
        { id: "openverse", name: "Openverse", needsKey: false, colors: false, sorts: [] },
        { id: "unsplash",  name: "Unsplash",  needsKey: true,  colors: false, sorts: [] },
        { id: "pexels",    name: "Pexels",    needsKey: true,  colors: true,  sorts: [] }
    ]
    readonly property var lenses: ["660000", "990000", "cc0000", "cc3333", "ea4c88", "993399", "663399", "333399", "0066cc", "0099cc",
        "66cccc", "77cc33", "669900", "336600", "666600", "999900", "cccc33", "ffff00", "ffcc33", "ff9900",
        "ff6600", "cc6633", "996633", "663300", "000000", "999999", "cccccc", "ffffff", "424153"]

    property string source: "local"
    property string query: ""
    property string color: ""
    property string sort: "latest"
    property int page: 1
    property int pages: 1
    property int total: 0
    property string seed: ""
    property var items: []
    property bool busy: false
    property string error: ""
    property string keyHint: ""
    property bool needKey: false
    property string applying: ""        // id being applied
    property string status: ""
    readonly property var current: sources.find(s => s.id === source)

    function setSource(id) {
        source = id; page = 1; seed = ""; items = []; total = 0; pages = 1
        const s = sources.find(x => x.id === id)
        if (s.sorts.length > 0) sort = s.sorts[0]
        if (!s.colors) color = ""
        search()
    }
    function setColor(c) { color = (color === c) ? "" : c; page = 1; search() }
    function setSort(s) { sort = s; page = 1; seed = ""; search() }
    function setQuery(q) { query = q; page = 1; debounce.restart() }
    function nextPage() { if (page < pages) { page++; search() } }
    function prevPage() { if (page > 1) { page--; search() } }

    Timer { id: debounce; interval: 450; onTriggered: root.search() }

    Connections{target:Privacy;function onPolicyChanged(){searchProc.running=false;if(root.source!=="local"){root.items=[];root.busy=false}}}
    function search() {
        if(source!=="local"&&!Privacy.allowed("wallpapers",true)){error="Online wallpapers disabled in Privacy";items=[];return}
        const args = ["ms-walls", "search", source, "--page", "" + page, "--sort", sort]
        if (query !== "") args.push("--query", query)
        if (color !== "") args.push("--color", color)
        if (seed !== "") args.push("--seed", seed)
        error = ""; needKey = false; busy = true
        searchProc.running = false
        searchProc.command = args
        searchProc.running = true
    }
    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false
                let d
                try { d = JSON.parse(text) } catch (e) { root.error = "The archive gave no answer"; return }
                if (d.error === "key") { root.needKey = true; root.keyHint = d.hint; root.items = []; root.total = 0; return }
                if (d.error) { root.error = d.error; return }
                root.items = d.items; root.pages = d.pages || 1; root.total = d.total || d.items.length
                if (d.seed) root.seed = d.seed
                if (d.items.length === 0) root.error = "Nothing found. Try another word or lens."
            }
        }
    }

    function apply(item) {
        if (applying !== "") return
        applying = item.id; status = item.local ? "Consecrating" : "Downloading"
        applyProc.command = ["ms-walls", "apply", item.full]
        applyProc.running = true
    }
    function applyRandom() { if (items.length > 0) apply(items[Math.floor(Math.random() * items.length)]) }
    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: {
                let d = {}
                try { d = JSON.parse(text) } catch (e) {}
                root.status = d.error ? d.error : "Applied"
                root.applying = ""
                clearStatus.restart()
                if (!d.error && root.source === "local") {} else if (!d.error) root.savedSomething = true
            }
        }
    }
    property bool savedSomething: false
    Timer { id: clearStatus; interval: 2500; onTriggered: root.status = "" }

    function save(item) { saveProc.command = ["ms-walls", "save", item.full]; status = "Saving"; saveProc.running = true }
    Process { id: saveProc; stdout: StdioCollector { onStreamFinished: { root.status = text.includes("saved") ? "Saved to Pictures/Wallpapers" : "Could not save"; clearStatus.restart() } } }

    function setKey(k) { keyProc.command = ["ms-walls", "setkey", source, k]; keyProc.running = true }
    Process { id: keyProc; onExited: root.search() }

    function openFolder() { Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/Pictures/Wallpapers"]) }
}
