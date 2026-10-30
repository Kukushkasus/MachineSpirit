// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Shapes
import qs.common

// A bundle of thin cables hanging between two housings. Two of them are braided (over and under in turn),
// a third, thinner rubber line hangs lower. Here and there the insulation is worn away and the copper
// shows; that is where the lightning lives. A strike flashes along the bare copper with return strokes,
// heats it, throws sparks that fall, and makes the span shudder. Drawn as static shapes; the canvas only
// exists while something is burning.
Item {
    id: root
    property real portY: 19
    implicitHeight: 60
    readonly property bool usable: width > 70
    readonly property real span: Math.max(1, width)

    // ---- geometry: a catenary between the ports, braided offsets on top. A shudder does not recompute it:
    // the whole bundle is stretched about the port line on the GPU (`sway`), the ends stay put.
    property real sway: 0
    readonly property real sag: Math.max(2.5, Math.min(8, span * 0.025))
    function hang(t, extra) {
        const k = 1.4, c = Math.cosh((2 * t - 1) * k), ck = Math.cosh(k)
        return portY + (sag * extra) * (1 - c / ck) / (1 - 1 / ck)
    }
    readonly property real braid: 64          // px per full twist
    function edge(t) { return Math.min(1, t * span / 12, (1 - t) * span / 12) }
    function yOf(cable, t) {
        if (cable === 2) return hang(t, 1.55) + 2 * edge(t)
        const s = Math.sin(t * span / braid * Math.PI * 2) * 1.9 * edge(t)
        return hang(t, 1) + (cable === 0 ? s : -s)
    }
    function pts(cable, t0, t1, dy) {
        const out = [], step = 3 / span
        for (let t = t0; t < t1; t += step) out.push(Qt.point(t * span, yOf(cable, t) + (dy || 0)))
        out.push(Qt.point(t1 * span, yOf(cable, t1) + (dy || 0)))
        return out
    }

    // ---- where the copper shows: on the rust cable (0) and the rubber one (2), fixed per span length
    readonly property var bare: {
        if (span < 110) return [[], [], []]
        const L = Math.round(span)
        const r = i => ((L * 9301 + i * 49297) % 233280) / 233280
        const len = t => Math.min(0.3, (40 + r(t) * 50) / span)
        const a = [], c = []
        const a0 = 0.18 + r(1) * 0.2; a.push([a0, a0 + len(2)])
        if (span > 260) { const a1 = 0.58 + r(3) * 0.18; a.push([a1, a1 + len(4)]) }
        if (span > 180) { const c0 = 0.3 + r(5) * 0.35; c.push([c0, c0 + len(6) * 0.7]) }
        return [a, [], c]
    }
    function insulated(cable) {   // complement of the bare stretches
        const out = []; let t = 0
        for (const b of bare[cable]) { out.push([t, b[0]]); t = b[1] }
        out.push([t, 1])
        return out
    }
    // braid crossings: where cable 1 lies over cable 0
    function overStretches() {
        const out = [], half = braid / 2 / span
        for (let t = half; t < 1; t += 2 * half) out.push([t, Math.min(1, t + half)])
        return out
    }
    function multi(cable, ranges, dy) { return ranges.filter(r => r[1] - r[0] > 0.002).map(r => pts(cable, r[0], r[1], dy)) }

    readonly property color rubber: Theme.metalHi
    readonly property color cloth: Qt.darker(Theme.rust, 1.25)
    readonly property color braidB: Qt.darker(Theme.brassLo, 1.15)
    readonly property color outline: Qt.darker(Theme.metalLo, 1.6)

    Shape {
        anchors.fill: parent
        visible: root.usable
        transform: Scale { origin.y: root.portY; yScale: 1 + root.sway }
        preferredRendererType: Shape.CurveRenderer
        // the low rubber line
        ShapePath { fillColor: "transparent"; strokeColor: root.outline; strokeWidth: 3; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(2, root.insulated(2)) } }
        ShapePath { fillColor: "transparent"; strokeColor: root.rubber; strokeWidth: 1.8; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(2, root.insulated(2)) } }
        // brass braid under
        ShapePath { fillColor: "transparent"; strokeColor: root.outline; strokeWidth: 3.2; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(1, [[0, 1]]) } }
        ShapePath { fillColor: "transparent"; strokeColor: root.braidB; strokeWidth: 2; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(1, [[0, 1]]) } }
        // rust cable over it
        ShapePath { fillColor: "transparent"; strokeColor: root.outline; strokeWidth: 3.2; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(0, root.insulated(0)) } }
        ShapePath { fillColor: "transparent"; strokeColor: root.cloth; strokeWidth: 2; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(0, root.insulated(0)) } }
        // ...and the brass one back on top where it crosses over
        ShapePath { fillColor: "transparent"; strokeColor: root.outline; strokeWidth: 3.2; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(1, root.overStretches()) } }
        ShapePath { fillColor: "transparent"; strokeColor: root.braidB; strokeWidth: 2; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(1, root.overStretches()) } }
        // sheen
        ShapePath { fillColor: "transparent"; strokeColor: Qt.rgba(1, 1, 1, 0.13); strokeWidth: 0.7
            PathMultiline { paths: root.multi(0, root.insulated(0), -0.8).concat(root.multi(1, root.overStretches(), -0.8)) } }
        // bare copper: dark core, bright strands, twist hatching
        ShapePath { fillColor: "transparent"; strokeColor: Theme.brassLo; strokeWidth: 1.9; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(0, root.bare[0]).concat(root.multi(2, root.bare[2])) } }
        ShapePath { fillColor: "transparent"; strokeColor: Theme.brassHi; strokeWidth: 0.9; capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.multi(0, root.bare[0], -0.3).concat(root.multi(2, root.bare[2], -0.3)) } }
        ShapePath { fillColor: "transparent"; strokeColor: Qt.darker(Theme.brassLo, 1.3); strokeWidth: 0.6
            PathMultiline {
                paths: {
                    const out = []
                    for (const c of [0, 2]) for (const b of root.bare[c])
                        for (let x = b[0] * root.span + 2; x < b[1] * root.span - 1; x += 2.6) {
                            const y = root.yOf(c, x / root.span)
                            out.push([Qt.point(x - 0.8, y - 1), Qt.point(x + 0.8, y + 1)])
                        }
                    return out
                }
            }
        }
        // frayed insulation at the ends of each bare stretch
        ShapePath { fillColor: "transparent"; strokeColor: root.cloth; strokeWidth: 0.8
            PathMultiline {
                paths: {
                    const out = []
                    for (const c of [0, 2]) for (const b of root.bare[c]) for (const t of b) {
                        const x = t * root.span, y = root.yOf(c, t), d = t === b[0] ? 1 : -1
                        out.push([Qt.point(x, y - 1), Qt.point(x + d * 3, y - 2.2)], [Qt.point(x, y + 1), Qt.point(x + d * 2.5, y + 2.4)], [Qt.point(x, y), Qt.point(x + d * 3.5, y + 0.4)])
                    }
                    return out
                }
            }
        }
    }

    // ---- lightning
    property var bolts: []        // { cable, t0, t1, born, flashes: [ms], seed, crackle, jump }
    property var sparks: []       // { x, y, vx, vy, born, life }
    function hasBare() { return bare[0].length + bare[2].length > 0 }

    // a faint crackle on the bare copper: a tiny flash run on the render thread, no canvas
    function crackle() {
        if (!usable || !hasBare() || !Theme.motionEnabled) return
        const all = []
        for (const c of [0, 2]) for (const b of bare[c]) all.push({ c: c, b: b })
        const ch = all[Math.floor(Math.random() * all.length)]
        const t = ch.b[0] + Math.random() * (ch.b[1] - ch.b[0])
        fizz.x = t * span - fizz.width / 2; fizz.y = yOf(ch.c, t) - fizz.height / 2
        fizz.rotation = Math.random() * 180
        fizzAnim.restart()
    }
    Item {
        id: fizz
        width: 12; height: 12; opacity: 0
        Rectangle { anchors.centerIn: parent; width: 12; height: 3; radius: 1.5; color: Qt.alpha(Theme.spark, 0.45) }
        Rectangle { anchors.centerIn: parent; width: 3; height: 9; radius: 1.5; color: Qt.alpha(Theme.spark, 0.35) }
        Rectangle { anchors.centerIn: parent; width: 3; height: 3; radius: 1.5; color: "#f0faff" }
        SequentialAnimation {
            id: fizzAnim
            OpacityAnimator { target: fizz; from: 0; to: 1; duration: 30 }
            OpacityAnimator { target: fizz; from: 1; to: 0.2; duration: 50 }
            OpacityAnimator { target: fizz; from: 0.2; to: 0.9; duration: 30 }
            OpacityAnimator { target: fizz; from: 0.9; to: 0; duration: 90 }
        }
    }

    function strike(crackle) {
        if (!usable || !hasBare() || !Theme.motionEnabled) return
        const choices = []
        for (const c of [0, 2]) for (const b of bare[c]) choices.push({ c: c, b: b })
        const ch = choices[Math.floor(Math.random() * choices.length)]
        const len = ch.b[1] - ch.b[0]
        let t0 = ch.b[0] + Math.random() * len * 0.25, t1 = ch.b[1] - Math.random() * len * 0.25
        if (crackle) { const m = ch.b[0] + Math.random() * len; t0 = Math.max(ch.b[0], m - 6 / span); t1 = Math.min(ch.b[1], m + 6 / span) }
        if (Math.random() < 0.5) { const s = t0; t0 = t1; t1 = s }
        const now = Date.now()
        const flashes = crackle ? [0] : [0, 60 + Math.random() * 30, 140 + Math.random() * 40].concat(Math.random() < 0.5 ? [230 + Math.random() * 50] : [])
        // an arc may jump to the other bare cable if they overlap
        let jump = null
        if (!crackle && ch.c === 0 && bare[2].length > 0 && Math.random() < 0.45) {
            const o = bare[2][0], lo = Math.max(o[0], Math.min(t0, t1)), hi = Math.min(o[1], Math.max(t0, t1))
            if (hi > lo) jump = lo + Math.random() * (hi - lo)
        }
        bolts = bolts.filter(b => now - b.born < 700).concat([{ cable: ch.c, t0: t0, t1: t1, born: now, flashes: flashes, seed: Math.floor(Math.random() * 1e9), crackle: !!crackle, jump: jump }])
        const sp = sparks.filter(p => now - p.born < p.life)
        for (const f of flashes) for (let i = 0; i < (crackle ? 2 : 4); i++) {
            const t = t0 + (t1 - t0) * Math.random()
            sp.push({ x: t * span, y: yOf(ch.c, t), vx: (Math.random() - 0.5) * 90, vy: -30 - Math.random() * 70, born: now + f, life: 450 + Math.random() * 450 })
        }
        sparks = sp
        if (!crackle) shudder.restart()
        cv.visible = true
        frame.start()
    }
    SequentialAnimation {
        id: shudder
        NumberAnimation { target: root; property: "sway"; to: 0.45; duration: 70; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "sway"; to: 0; duration: 520; easing.type: Easing.OutElastic; easing.amplitude: 1.1; easing.period: 0.3 }
    }

    function rng(seed) { let a = seed >>> 0; return () => { a = (a * 1664525 + 1013904223) >>> 0; return a / 4294967296 } }
    // jagged channel: points along the wire, each segment split by midpoint displacement
    function channel(cable, t0, t1, amp, R) {
        const n = Math.max(2, Math.round(Math.abs(t1 - t0) * span / 10))
        let p = []
        for (let i = 0; i <= n; i++) { const t = t0 + (t1 - t0) * i / n; p.push([t * span, yOf(cable, t)]) }
        for (let level = 0; level < 3; level++) {
            const q = [p[0]]
            for (let i = 1; i < p.length; i++) {
                const a = p[i - 1], b = p[i], dx = b[0] - a[0], dy = b[1] - a[1], l = Math.hypot(dx, dy) || 1
                const off = (R() - 0.5) * 2 * amp
                q.push([(a[0] + b[0]) / 2 - dy / l * off, (a[1] + b[1]) / 2 + dx / l * off], b)
            }
            p = q; amp *= 0.55
        }
        return p
    }
    function forkFrom(p, R) {
        const f = [p]; let x = p[0], y = p[1]
        const dir = R() < 0.5 ? -1 : 1, down = R() < 0.7 ? 1 : -1
        for (let k = 0; k < 3 + Math.floor(R() * 3); k++) { x += dir * (2 + R() * 4); y += down * (1.5 + R() * 3); f.push([x, y]) }
        return f
    }

    Canvas {
        id: cv
        anchors.fill: parent
        transform: Scale { origin.y: root.portY; yScale: 1 + root.sway }
        visible: false
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const ctx = getContext("2d")
            if (!ctx) return
            ctx.reset()
            const now = Date.now()
            const s = Theme.spark, sr = Math.round(s.r * 255), sg = Math.round(s.g * 255), sb = Math.round(s.b * 255)
            const blue = a => "rgba(" + sr + "," + sg + "," + sb + "," + a + ")"
            ctx.lineCap = "round"; ctx.lineJoin = "round"
            const line = pts => { ctx.beginPath(); ctx.moveTo(pts[0][0], pts[0][1]); for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]); ctx.stroke() }

            for (const b of root.bolts) {
                const age = now - b.born
                if (age < 0) continue
                // brightness: each return stroke flashes and decays fast; afterglow after the last one
                let I = 0, k = 0
                for (let i = 0; i < b.flashes.length; i++) if (age >= b.flashes[i]) { I = Math.max(I, Math.exp(-(age - b.flashes[i]) / 38)); k = i }
                const heat = b.crackle ? 0 : Math.exp(-age / 420)
                if (heat > 0.03) {   // the copper glows from the current
                    const wire = root.pts(b.cable, Math.min(b.t0, b.t1), Math.max(b.t0, b.t1)).map(q => [q.x, q.y])
                    ctx.strokeStyle = "rgba(255,140,50," + (0.22 * heat) + ")"; ctx.lineWidth = 5; line(wire)
                    ctx.strokeStyle = "rgba(255," + Math.round(180 + 75 * heat) + "," + Math.round(110 + 130 * heat) + "," + (0.9 * heat) + ")"
                    ctx.lineWidth = 1.5; line(wire)
                }
                if (I < 0.04) continue
                const R = root.rng(b.seed + k * 7919)
                const main = root.channel(b.cable, b.t0, b.t1, b.crackle ? 2 : 4, R)
                const forks = []
                if (!b.crackle && main.length > 6) for (let i = 0; i < 1 + Math.floor(R() * 3); i++) forks.push(root.forkFrom(main[2 + Math.floor(R() * (main.length - 4))], R))
                let arc = null
                if (b.jump !== null) {
                    const ya = root.yOf(0, b.jump), yc = root.yOf(2, b.jump), x = b.jump * root.span
                    arc = [[x, ya]]; const n = 4
                    for (let i = 1; i < n; i++) arc.push([x + (R() - 0.5) * 5, ya + (yc - ya) * i / n])
                    arc.push([x, yc])
                }
                // halo built from a few soft passes (the Qt canvas does not draw shadows)
                const all = [main].concat(forks, arc ? [arc] : [])
                ctx.strokeStyle = blue(0.07 * I); ctx.lineWidth = 9; for (const q of all) line(q)
                ctx.strokeStyle = blue(0.16 * I); ctx.lineWidth = 4.5; for (const q of all) line(q)
                ctx.strokeStyle = blue(0.85 * I); ctx.lineWidth = 1.7; line(main); if (arc) line(arc)
                ctx.lineWidth = 1; for (const f of forks) line(f)
                ctx.strokeStyle = "rgba(240,250,255," + I + ")"; ctx.lineWidth = 0.8; line(main); if (arc) line(arc)
            }
            for (const p of root.sparks) {   // sparks: short streaks falling under gravity
                const dt = (now - p.born) / 1000
                if (dt < 0) continue
                const life = dt * 1000 / p.life
                if (life > 1) continue
                const at = d => [p.x + p.vx * d, p.y + p.vy * d + 260 * d * d]
                const a = at(Math.max(0, dt - 0.03)), c = at(dt)
                ctx.strokeStyle = "rgba(255," + Math.round(235 - 60 * life) + "," + Math.round(190 - 120 * life) + "," + (1 - life) + ")"
                ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(c[0], c[1]); ctx.stroke()
            }
        }
    }

    Timer {
        id: frame
        interval: 33; repeat: true
        onTriggered: {
            const now = Date.now()
            root.bolts = root.bolts.filter(b => now - b.born < (b.crackle ? 160 : 700))
            root.sparks = root.sparks.filter(p => now - p.born < p.life)
            if (root.bolts.length === 0 && root.sparks.length === 0) { stop(); cv.visible = false; return }
            cv.requestPaint()
        }
    }
}
