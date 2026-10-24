pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Погода через wttr.in (нужен curl)
Singleton {
    id: root

    property bool ready: false
    property bool error: false
    property string temp: ""
    property string feels: ""
    property string desc: ""
    property string icon: "\ue30d"
    property string humidity: ""
    property string wind: ""
    property string windDir: ""
    property string uv: ""
    property string city: ""
    property var days: []
    property var hourly: []
    property double lastFetch: 0

    function iconFor(code, day) {
        const c = parseInt(code)
        if (c === 113) return day ? "\ue30d" : "\ue32b"
        if (c === 116) return day ? "\ue302" : "\ue37e"
        if (c === 119 || c === 122) return "\ue312"
        if ([143, 248, 260].indexOf(c) >= 0) return "\ue313"
        if ([200, 386, 389, 392, 395].indexOf(c) >= 0) return "\ue31d"
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].indexOf(c) >= 0) return "\ue31a"
        if ([182, 185, 281, 284, 311, 314, 317, 320, 350, 362, 365, 374, 377].indexOf(c) >= 0) return "\ue3ad"
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359].indexOf(c) >= 0) return "\ue318"
        return "\ue312"
    }

    function pick(arr) { return (arr && arr.length > 0) ? arr[0].value : "" }

    function parse(text) {
        try {
            const j = JSON.parse(text)
            const c = j.current_condition[0]
            const hour = new Date().getHours()

            temp = c.temp_C
            feels = c.FeelsLikeC
            humidity = c.humidity
            wind = c.windspeedKmph
            windDir = c.winddir16Point
            uv = c.uvIndex || ""
            desc = c.lang_ru ? pick(c.lang_ru) : pick(c.weatherDesc)
            icon = iconFor(c.weatherCode, hour >= 6 && hour < 21)
            city = j.nearest_area ? pick(j.nearest_area[0].areaName) : ""

            const names = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
            days = j.weather.map((d, i) => {
                const mid = d.hourly[Math.min(4, d.hourly.length - 1)]
                return {
                    label: i === 0 ? "Сегодня" : (i === 1 ? "Завтра" : names[new Date(d.date + "T12:00:00").getDay()]),
                    hi: d.maxtempC, lo: d.mintempC,
                    icon: iconFor(mid.weatherCode, true),
                    desc: mid.lang_ru ? pick(mid.lang_ru) : pick(mid.weatherDesc)
                }
            })

            const hrs = []
            for (let di = 0; di < Math.min(2, j.weather.length); di++) {
                const hh = j.weather[di].hourly
                for (let k = 0; k < hh.length; k++) {
                    const th = parseInt(hh[k].time) / 100
                    hrs.push({
                        when: di * 24 + th,
                        temp: parseInt(hh[k].tempC),
                        icon: iconFor(hh[k].weatherCode, th >= 6 && th < 21),
                        label: ("0" + th).slice(-2)
                    })
                }
            }
            hourly = hrs.filter(x => x.when > hour - 3).slice(0, 8)

            ready = true
            error = false
            lastFetch = Date.now()
        } catch (e) {
            console.warn("Weather: не разобрал ответ:", e)
            error = true
            retry.start()
        }
    }

    function refresh(force) {
        if (proc.running) return
        if (!force && Date.now() - lastFetch < 5 * 60000) return
        const city = Config.weatherCity ? encodeURIComponent(Config.weatherCity) : ""
        proc.command = ["curl", "-fsS", "--max-time", "15", "https://wttr.in/" + city + "?format=j1&lang=ru"]
        proc.running = true
    }

    Process {
        id: proc
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        onExited: code => { if (code !== 0) { root.error = true; retry.start() } }
    }
    Timer { id: retry; interval: 180000; onTriggered: root.refresh(true) }
    Timer {
        interval: Math.max(5, Config.weatherRefreshMin) * 60000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh(true)
    }
}
