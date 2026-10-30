pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick

// CPU / memory / swap / network throughput, polled from /proc.
Singleton {
    id: root
    property real cpu: 0
    property real ram: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property real swap: 0
    property real swapUsedGb: 0
    property real swapTotalGb: 0
    property real load1: 0
    property real rxRate: 0     // bytes per second
    property real txRate: 0
    property var prevCpu: null
    property var prevNet: null

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: mem; path: "/proc/meminfo" }
    FileView { id: net; path: "/proc/net/dev" }
    FileView { id: loadavg; path: "/proc/loadavg" }
    FileView { id: upfile; path: "/proc/uptime" }
    property string uptime: ""
    property real disk: 0           // root filesystem, 0..1
    property real diskUsedGb: 0
    property real diskTotalGb: 0

    // last 60 samples, oldest first, for the gauges' traces
    property var cpuHist: []
    property var rxHist: []
    property var txHist: []
    function push(arr, v) { const a = arr.slice(-59); a.push(v); return a }

    // heaviest processes, only polled while something asks for them
    property bool wantProcs: false
    property var procs: []          // [{ name, cpu }]
    Process {
        id: psProc
        command: ["sh", "-c", "ps -eo pcpu=,comm= --sort=-pcpu | head -4"]
        stdout: StdioCollector {
            onStreamFinished: root.procs = text.trim().split("\n").filter(l => l.trim() !== "").map(l => {
                const m = l.trim().match(/^([0-9.]+)\s+(.*)$/)
                return m ? { cpu: Number(m[1]), name: m[2] } : { cpu: 0, name: l.trim() }
            }).filter(p => p.name !== "ps" && p.name !== "sh").slice(0, 3)
        }
    }
    Timer { interval: 2000; running: root.wantProcs; repeat: true; triggeredOnStart: true; onTriggered: psProc.running = true }

    // Fixed-shape rate text: "812 B/s", "79.3 KB/s", "1.2 MB/s".
    function formatRate(b) {
        if (b < 1000) return Math.round(b) + " B/s"
        if (b < 1000 * 1024) return (b / 1024).toFixed(1) + " KB/s"
        return (b / 1048576).toFixed(1) + " MB/s"
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload(); loadavg.reload()
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4]
            const total = f.reduce((a, b) => a + b, 0)
            if (root.prevCpu) { root.cpu = 1 - (idle - root.prevCpu.idle) / Math.max(1, total - root.prevCpu.total); root.cpuHist = root.push(root.cpuHist, root.cpu) }
            root.prevCpu = { idle: idle, total: total }

            const m = mem.text()
            const get = k => { const r = new RegExp(k + ":\\s+(\\d+)").exec(m); return r ? Number(r[1]) : 0 }
            const t = get("MemTotal"), a = get("MemAvailable")
            if (t > 0) { root.ram = 1 - a / t; root.ramUsedGb = (t - a) / 1048576; root.ramTotalGb = t / 1048576 }
            const st = get("SwapTotal"), sf = get("SwapFree")
            root.swap = st > 0 ? 1 - sf / st : 0
            root.swapUsedGb = (st - sf) / 1048576; root.swapTotalGb = st / 1048576

            root.load1 = Number(loadavg.text().split(" ")[0]) || 0

            upfile.reload()
            const up = Math.floor(Number(upfile.text().split(" ")[0]) || 0)
            const ud = Math.floor(up / 86400), uh = Math.floor(up % 86400 / 3600), um = Math.floor(up % 3600 / 60)
            root.uptime = ud > 0 ? ud + "d " + uh + "h" : (uh > 0 ? uh + "h " + um + "m" : um + "m")
        }
    }

    // Network is sampled every two seconds and smoothed so the readout does not flicker.
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            net.reload()
            let rx = 0, tx = 0
            for (const line of net.text().split("\n").slice(2)) {
                const p = line.trim().split(/\s+/)
                if (p.length < 10 || p[0].startsWith("lo:")) continue
                rx += Number(p[1]); tx += Number(p[9])
            }
            const now = Date.now()
            if (root.prevNet) {
                const dt = Math.max(0.2, (now - root.prevNet.t) / 1000)
                const r = Math.max(0, (rx - root.prevNet.rx) / dt)
                const t = Math.max(0, (tx - root.prevNet.tx) / dt)
                root.rxRate = root.rxRate * 0.4 + r * 0.6
                root.txRate = root.txRate * 0.4 + t * 0.6
                root.rxHist = root.push(root.rxHist, root.rxRate)
                root.txHist = root.push(root.txHist, root.txRate)
            }
            root.prevNet = { rx: rx, tx: tx, t: now }
        }
    }

    Process {
        id: dfProc
        command: ["sh", "-c", "df -B1 --output=used,size / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).map(Number)
                if (p.length >= 2 && p[1] > 0) { root.disk = p[0] / p[1]; root.diskUsedGb = p[0] / 1073741824; root.diskTotalGb = p[1] / 1073741824 }
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: dfProc.running = true }
}
