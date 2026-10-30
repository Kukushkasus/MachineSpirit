pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification daemon: tracked list for the center, short-lived `toasts` for popups.
Singleton {
    id: root
    readonly property alias server: server
    readonly property var all: server.trackedNotifications.values
    property var toasts: []        // notification objects currently shown as popups
    property int unread: 0
    property bool dnd: false       // quiet mode: notifications are kept, no popups
    property var stamps: ({})      // notification id -> arrival time (ms)

    // grouped by application, newest group first: [{ app, icon, items: [n...], last }]
    readonly property var groups: {
        const map = {}, order = []
        const list = all.slice().reverse()
        for (const n of list) {
            const key = n.appName || "System"
            if (!map[key]) { map[key] = { app: key, icon: n.appIcon || "", items: [], last: 0 }; order.push(map[key]) }
            map[key].items.push(n)
            map[key].last = Math.max(map[key].last, stamps[n.id] ?? 0)
        }
        return order.sort((a, b) => b.last - a.last)
    }
    function age(n) {
        const s = Math.max(0, (Date.now() - (stamps[n.id] ?? Date.now())) / 1000)
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + " min" : s < 86400 ? Math.floor(s / 3600) + " h" : Math.floor(s / 86400) + " d"
    }
    function when(n) { return Qt.formatTime(new Date(stamps[n.id] ?? Date.now()), "HH:mm") }
    function copy(n) { Quickshell.execDetached(["wl-copy", (n.summary || "") + (n.body ? "\n" + n.body : "")]) }
    function dismissGroup(g) { for (const n of g.items.slice()) dismiss(n) }

    function dismiss(n) { removeToast(n); n.dismiss() }
    function clearAll() {
        const list = server.trackedNotifications.values.slice()
        for (const n of list) n.dismiss()
        toasts = []
        unread = 0
    }
    function removeToast(n) { toasts = toasts.filter(t => t !== n) }
    function markRead() { unread = 0 }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true
            const st = Object.assign({}, root.stamps); st[n.id] = Date.now(); root.stamps = st
            root.unread += 1
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return
            root.toasts = [n].concat(root.toasts).slice(0, 4)
            const ms = n.expireTimeout > 0 ? n.expireTimeout * 1000 : 6000
            const timer = Qt.createQmlObject('import QtQuick; Timer { running: true; repeat: false }', root)
            timer.interval = ms
            timer.triggered.connect(() => { root.removeToast(n); timer.destroy() })
        }
    }
}
