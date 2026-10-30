pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness: a laptop backlight through brightnessctl, external monitors over DDC/CI through
// ddcutil (needs i2c-dev). Probed once when first wanted; writes are debounced because DDC is slow.
Singleton {
    id: root
    property bool available: false
    property real value: 1            // 0..1
    property string method: ""        // "backlight" / "ddc"
    property string bus: ""
    property bool probed: false

    function probe() {
        if (probed) return
        probed = true
        detect.running = true
    }
    function set(v) {
        value = Math.max(0.01, Math.min(1, v))
        apply.restart()
    }

    Process {
        id: detect
        command: ["sh", "-c", "if brightnessctl -l -c backlight 2>/dev/null | grep -q backlight; then echo backlight $(brightnessctl -c backlight g) $(brightnessctl -c backlight m); "
            + "elif command -v ddcutil >/dev/null; then b=$(ddcutil detect --brief 2>/dev/null | sed -n 's/.*\\/dev\\/i2c-\\([0-9]*\\).*/\\1/p' | head -1); "
            + "[ -n \"$b\" ] && echo ddc $b $(ddcutil -b $b getvcp 10 --brief 2>/dev/null | awk '{print $4, $5}'); fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/)
                if (p[0] === "backlight" && p.length >= 3) { root.method = "backlight"; root.value = Number(p[1]) / Math.max(1, Number(p[2])); root.available = true }
                else if (p[0] === "ddc" && p.length >= 4) { root.method = "ddc"; root.bus = p[1]; root.value = Number(p[2]) / Math.max(1, Number(p[3])); root.available = true }
            }
        }
    }
    Timer {
        id: apply; interval: 300
        onTriggered: {
            const pct = Math.round(root.value * 100)
            if (root.method === "backlight") Quickshell.execDetached(["brightnessctl", "-c", "backlight", "-q", "s", pct + "%"])
            else if (root.method === "ddc") Quickshell.execDetached(["ddcutil", "-b", root.bus, "setvcp", "10", String(pct)])
        }
    }
}
