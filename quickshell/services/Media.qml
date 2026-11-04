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
    readonly property string originalArt: (player?.trackArtUrl ?? "") || (cache[key] ?? "")
    property string downloadedArt: ""
    readonly property string art: originalArt.startsWith("file:") ? originalArt : (Privacy.allowed("remoteArt",true)?downloadedArt:"")
    property string artRequest: ""
    property bool manualArt:false
    onOriginalArtChanged: loadArt(manualArt)
    function loadArt(manual) {
        artProc.running=false;downloadedArt="";
        if(originalArt.startsWith("https://")&&Privacy.allowed("remoteArt",manual)){artRequest=JSON.stringify({kind:"remoteArt",url:originalArt,manual:!!manual});artProc.running=true}
    }
    Process{id:artProc;command:["ms-net"];stdinEnabled:true;onStarted:{write(root.artRequest);stdinEnabled=false}onExited:stdinEnabled=true
        stdout:StdioCollector{onStreamFinished:{try{root.downloadedArt=JSON.parse(text).url||""}catch(e){}}}}
    Connections{target:Privacy;function onPolicyChanged(){lookup.running=false;root.loadArt(false);root.maybeLookup()}function onReadyChanged(){root.loadArt(false);root.maybeLookup()}}
    property bool manualLookup:false
    function refreshCover(){const c=Object.assign({},cache);delete c[key];cache=c;manualLookup=true;manualArt=true;maybeLookup();loadArt(true)}

    readonly property string key: artist + "|" + title
    property var cache: ({})
    property string pendingKey: ""
    readonly property bool lookupEnabled: Quickshell.env("MS_COVER_LOOKUP") !== "0" && Privacy.allowed("coverSearch",manualLookup)

    onPlayingChanged: Cava.playing = playing
    Component.onCompleted: Cava.playing = playing
    onKeyChanged: {manualLookup=false;manualArt=false;maybeLookup()}
    onPlayerChanged: maybeLookup()

    function maybeLookup() {
        if (!lookupEnabled || !player || title === "" || (player.trackArtUrl ?? "") !== "") return
        if (cache[key] !== undefined || lookup.running) return
        pendingKey = key
        lookupPayload=JSON.stringify({kind:"coverSearch",artist:artist,title:title,manual:manualLookup})
        lookup.running = true
    }

    property string lookupPayload:""
    Process {
        id: lookup;command:["ms-net"];stdinEnabled:true
        onStarted:{write(root.lookupPayload);stdinEnabled=false}
        onExited:stdinEnabled=true
        stdout: StdioCollector {
            onStreamFinished: {
                let url = ""
                try {
                    url=JSON.parse(text).url||""
                } catch (e) {}
                const c = Object.assign({}, root.cache)
                c[root.pendingKey] = url
                root.cache = c
                root.manualLookup=false
                if (root.key !== root.pendingKey) root.maybeLookup()   // track changed meanwhile
            }
        }
    }
}
