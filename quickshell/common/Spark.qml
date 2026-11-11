// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import qs.common

// A short blue bolt between two points, flickering for a moment. Used when a panel opens.
Canvas {
    id: root
    property real x0: 0
    property real y0: 0
    property real x1: 0
    property real y1: 0
    property real life: 0          // 1 -> 0 while the bolt fades
    anchors.fill: parent
    visible: life > 0

    function fire() { if (!Theme.fxOn("particles")) return; life = 1; anim.restart() }
    NumberAnimation { id: anim; target: root; property: "life"; from: 1; to: 0; duration: 340; easing.type: Easing.OutQuad }
    onLifeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (life <= 0) return
        const steps = 7, pts = []
        for (let i = 0; i <= steps; i++) {
            const t = i / steps, edge = Math.sin(t * Math.PI)
            pts.push([x0 + (x1 - x0) * t + (Math.random() - 0.5) * 12 * edge, y0 + (y1 - y0) * t])
        }
        const path = () => { ctx.beginPath(); pts.forEach((p, i) => i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1])) }
        ctx.lineCap = "round"; ctx.lineJoin = "round"
        path(); ctx.strokeStyle = Qt.alpha(Theme.spark, 0.25 * life); ctx.lineWidth = 7; ctx.stroke()
        path(); ctx.strokeStyle = Qt.alpha(Theme.spark, 0.9 * life); ctx.lineWidth = 2; ctx.stroke()
        path(); ctx.strokeStyle = Qt.rgba(0.92, 0.97, 1, life); ctx.lineWidth = 0.8; ctx.stroke()
    }
}
