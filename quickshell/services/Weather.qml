pragma Singleton
// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Io
import QtQuick

// Weather from wttr.in (JSON, located by IP unless MS_WEATHER_LOCATION is set, e.g. "Berlin").
Singleton {
    id: root
    property bool ready: false
    property bool stale: false
    property double updatedAt: 0
    property string area: ""
    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property int wind: 0
    property int pressure: 0
    property int visibility: 0
    property int uv: 0
    property string desc: ""
    property string icon: "cloud"
    property var forecast: []   // [{ day, hi, lo, icon, rain }]
    property var hourly: []     // today: [{ hour, temp }] every 3 h
    property var upcoming: []   // the next 8 three-hour slots from now: [{ label, temp, icon, rain }]
    property real sunrise: 7    // hours, local
    property real sunset: 18

    function iconFor(code) {
        code = Number(code)
        if (code === 113) return "clear_day"
        if (code === 116) return "partly_cloudy_day"
        if (code === 119 || code === 122) return "cloud"
        if ([143, 248, 260].includes(code)) return "foggy"
        if ([200, 386, 389, 392, 395].includes(code)) return "thunderstorm"
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code)) return "weather_snowy"
        return "rainy"
    }

    function parse(text) {
        try {
            const d = JSON.parse(text)
            const c = d.current_condition[0]
            root.temp = Number(c.temp_C)
            root.feels = Number(c.FeelsLikeC)
            root.humidity = Number(c.humidity)
            root.wind = Number(c.windspeedKmph)
            root.pressure = Number(c.pressure)
            root.visibility = Number(c.visibility)
            root.uv = Number(c.uvIndex)
            root.desc = c.weatherDesc[0].value.trim()
            root.icon = iconFor(c.weatherCode)
            root.area = d.nearest_area[0].areaName[0].value
            root.forecast = d.weather.map(w => ({
                day: Qt.locale("en_US").dayName(new Date(w.date).getDay(), Locale.ShortFormat),
                hi: Number(w.maxtempC),
                lo: Number(w.mintempC),
                icon: iconFor(w.hourly[4].weatherCode),
                rain: Math.max(...w.hourly.map(h => Number(h.chanceofrain) || 0))
            }))
            const hm = t => { const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(t || ""); if (!m) return null; let h = Number(m[1]) % 12; if (m[3].toUpperCase() === "PM") h += 12; return h + Number(m[2]) / 60 }
            const astro = d.weather[0].astronomy?.[0]
            root.sunrise = hm(astro?.sunrise) ?? 7
            root.sunset = hm(astro?.sunset) ?? 18
            root.hourly = d.weather[0].hourly.map(h => ({ hour: Number(h.time) / 100, temp: Number(h.tempC) }))
            const now = new Date().getHours(), slots = []
            d.weather.forEach((w, di) => w.hourly.forEach(h => {
                const hr = Number(h.time) / 100
                if (di === 0 && hr + 3 <= now) return
                slots.push({ label: slots.length === 0 ? "Now" : String(hr).padStart(2, "0") + ":00",
                             temp: Number(h.tempC), icon: iconFor(h.weatherCode), rain: Number(h.chanceofrain) || 0 })
            }))
            root.upcoming = slots.slice(0, 8)
            root.ready = true
            root.stale = false
            root.updatedAt = Date.now()
        } catch (e) {
            root.stale = root.ready
            console.warn("weather parse failed:", e)
        }
    }

    Process {
        id: proc
        command: ["curl", "-s", "-m", "10", "https://wttr.in/" + (Quickshell.env("MS_WEATHER_LOCATION") || "") + "?format=j1"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer {
        interval: 20 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
