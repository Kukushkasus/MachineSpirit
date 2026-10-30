// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Particles
import qs.common

// Sparks from a live joint: hot white-gold points that fly out, fall under gravity and shrink away.
// The particle system runs only while sparks are alive.
// puff(): a burst, hiss(): a few, jet(): a spray both ways along a seam.
Item {
    id: root
    property real spread: 10        // width of the joint the sparks leave
    property real power: 1          // scales speed and count
    width: 1; height: 1

    property real dir: 270
    property real fan: 60
    function puff() { dir = 270; fan = 70; burst(16) }
    function hiss() { dir = 270; fan = 50; burst(6) }
    function jet() { fan = 25; dir = 200; burst(4); jetBack.restart() }
    Timer { id: jetBack; interval: 16; onTriggered: { root.dir = 340; root.burst(4) } }

    function burst(n) {
        if (Theme.lowPower) return
        sys.running = true
        stopper.restart()
        hot.burst(Math.round(n * power))
    }
    Timer { id: stopper; interval: 900; onTriggered: sys.running = false }

    ParticleSystem { id: sys; running: false }

    ImageParticle {
        system: sys
        source: "../assets/spark.png"
        color: "#fff3d6"
        colorVariation: 0.08
        entryEffect: ImageParticle.Scale
    }

    Emitter {
        id: hot
        system: sys
        enabled: false
        x: -root.spread / 2; y: -1; width: root.spread; height: 2
        lifeSpan: 450; lifeSpanVariation: 200
        size: 3.5; sizeVariation: 1.5
        endSize: 1
        velocity: AngleDirection { angle: root.dir; angleVariation: root.fan; magnitude: 130 * root.power; magnitudeVariation: 50 * root.power }
        acceleration: PointDirection { y: 520 }
    }
}
