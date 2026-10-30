pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// The player the shell shows: the one playing, else the first available.
// Many players (Firefox!) publish no cover; then it is looked up in the public iTunes search by
// artist + title (disable with MS_COVER_LOOKUP=0).
Singleton {
    id: root
    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.isPlaying) ?? list[0] ?? null
    }
    readonly property bool available: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string art: (player?.trackArtUrl ?? "") !== "" ? player.trackArtUrl : (cache[key] ?? "")

    readonly property string key: artist + "|" + title
    property var cache: ({})
    property string pendingKey: ""
    readonly property bool lookupEnabled: Quickshell.env("MS_COVER_LOOKUP") !== "0"

    onPlayingChanged: Cava.playing = playing
    Component.onCompleted: Cava.playing = playing
    onKeyChanged: maybeLookup()
    onPlayerChanged: maybeLookup()

    function maybeLookup() {
        if (!lookupEnabled || !player || title === "" || (player.trackArtUrl ?? "") !== "") return
        if (cache[key] !== undefined || lookup.running) return
        pendingKey = key
        lookup.command = ["curl", "-s", "-m", "8", "-G", "https://itunes.apple.com/search",
            "--data-urlencode", "term=" + artist + " " + title, "-d", "media=music", "-d", "entity=song", "-d", "limit=1"]
        lookup.running = true
    }

    Process {
        id: lookup
        stdout: StdioCollector {
            onStreamFinished: {
                let url = ""
                try {
                    const r = JSON.parse(text).results
                    if (r && r.length > 0) url = r[0].artworkUrl100.replace("100x100", "300x300")
                } catch (e) {}
                const c = Object.assign({}, root.cache)
                c[root.pendingKey] = url
                root.cache = c
                if (root.key !== root.pendingKey) root.maybeLookup()   // track changed meanwhile
            }
        }
    }
}
