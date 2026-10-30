pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick

// Connection details: interface, addresses, gateway, MAC and session traffic.
Singleton {
    id: root
    property string iface: ""
    property string kind: ""          // ethernet / wifi
    property string connection: ""
    property string localIp: ""
    property string gateway: ""
    property string mac: ""
    property string publicIp: ""
    property bool online: iface !== ""
    // bytes since the shell started
    property real rxTotal: 0
    property real txTotal: 0
    property var base: null

    function fmtBytes(b) {
        if (b < 1024) return Math.round(b) + " B"
        if (b < 1048576) return (b / 1024).toFixed(0) + " KB"
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB"
        return (b / 1073741824).toFixed(1) + " GB"
    }

    Process {
        id: route
        command: ["sh", "-c", "ip -j route get 1.1.1.1 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)[0]
                    root.iface = r.dev ?? ""
                    root.localIp = r.prefsrc ?? ""
                    root.gateway = r.gateway ?? ""
                    root.kind = root.iface.startsWith("wl") ? "Wi-Fi" : "Ethernet"
                    if (root.iface !== "") { macFile.path = "/sys/class/net/" + root.iface + "/address"; macFile.reload(); nm.running = true }
                } catch (e) { root.iface = "" }
            }
        }
    }
    FileView { id: macFile; onLoaded: root.mac = text().trim().toUpperCase() }
    Process {
        id: nm
        command: ["sh", "-c", "nmcli -t -f DEVICE,CONNECTION device status 2>/dev/null | grep '^" + root.iface + ":' | cut -d: -f2"]
        stdout: StdioCollector { onStreamFinished: root.connection = text.trim() }
    }
    Process {
        id: pub
        command: ["curl", "-s", "-m", "6", "https://api.ipify.org"]
        stdout: StdioCollector { onStreamFinished: root.publicIp = text.trim() }
    }
    FileView { id: dev; path: "/proc/net/dev" }

    Timer {
        interval: 15000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { route.running = true }
    }
    Timer { interval: 600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: pub.running = true }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            dev.reload()
            let rx = 0, tx = 0
            for (const line of dev.text().split("\n").slice(2)) {
                const p = line.trim().split(/\s+/)
                if (p.length < 10 || p[0].startsWith("lo:")) continue
                rx += Number(p[1]); tx += Number(p[9])
            }
            if (!root.base) root.base = { rx: rx, tx: tx }
            root.rxTotal = rx - root.base.rx
            root.txTotal = tx - root.base.tx
        }
    }
}
