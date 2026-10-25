pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Погода через Open-Meteo (без ключа, доступен без VPN).
// Место: координаты/город из Config.qml, иначе по IP. Последний ответ кэшируется на диске.
Singleton {
    id: root

    property bool ready: false
    property bool error: false
    property bool loading: false
    property string temp: ""
    property string feels: ""
    property string desc: ""
    property string icon: "\ue30d"
    property string humidity: ""
    property string wind: ""
    property string windDir: ""
    property string uv: ""
    property string city: ""
    property string sunrise: ""
    property string sunset: ""
    property string pressure: ""
    property var days: []
    property var hourly: []
    property double lastFetch: 0
    property double lastAlert: 0
    property real lat: NaN
    property real lon: NaN
    property bool located: false           // место уже определено в этой сессии
    property int ipStage: 0

    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/quickshell/weather.json"
    readonly property var codeNames: ({
        0: "Ясно", 1: "Преимущественно ясно", 2: "Переменная облачность", 3: "Пасмурно",
        45: "Туман", 48: "Изморозь",
        51: "Лёгкая морось", 53: "Морось", 55: "Сильная морось", 56: "Ледяная морось", 57: "Ледяная морось",
        61: "Небольшой дождь", 63: "Дождь", 65: "Сильный дождь", 66: "Ледяной дождь", 67: "Ледяной дождь",
        71: "Небольшой снег", 73: "Снег", 75: "Сильный снег", 77: "Снежная крупа",
        80: "Ливни", 81: "Ливни", 82: "Сильные ливни", 85: "Снегопад", 86: "Сильный снегопад",
        95: "Гроза", 96: "Гроза с градом", 99: "Гроза с градом"
    })

    function descFor(code) { return codeNames[Number(code)] || "—" }

    function iconFor(code, day) {
        const c = Number(code)
        if (c === 0) return day ? "\ue30d" : "\ue32b"
        if (c === 1 || c === 2) return day ? "\ue302" : "\ue37e"
        if (c === 3) return "\ue312"
        if (c === 45 || c === 48) return "\ue313"
        if (c === 56 || c === 57 || c === 66 || c === 67) return "\ue3ad"
        if (c >= 51 && c <= 55) return "\ue319"
        if (c >= 61 && c <= 65) return "\ue318"
        if (c >= 71 && c <= 77) return "\ue31a"
        if (c >= 80 && c <= 82) return "\ue319"
        if (c === 85 || c === 86) return "\ue31a"
        if (c >= 95) return "\ue31d"
        return "\ue312"
    }

    function compass(deg) {
        const n = ["С", "ССВ", "СВ", "ВСВ", "В", "ВЮВ", "ЮВ", "ЮЮВ", "Ю", "ЮЮЗ", "ЮЗ", "ЗЮЗ", "З", "ЗСЗ", "СЗ", "ССЗ"]
        return n[Math.round(Number(deg) / 22.5) % 16]
    }

    function curl(url) { return ["curl", "-fsS", "--max-time", "15", "-A", "quickshell-bar", url] }

    // ───────── определение места ─────────
    function locate() {
        loading = true
        if (Config.weatherLat !== "" && Config.weatherLon !== "") {
            lat = parseFloat(Config.weatherLat)
            lon = parseFloat(Config.weatherLon)
            city = Config.weatherCity
            located = true
            fetchForecast()
        } else if (Config.weatherCity !== "") {
            geoProc.command = curl("https://geocoding-api.open-meteo.com/v1/search?count=1&language=ru&format=json&name="
                                   + encodeURIComponent(Config.weatherCity))
            geoProc.running = true
        } else {
            ipStage = 0
            ipProc.command = curl("http://ip-api.com/json/?fields=status,city,lat,lon&lang=ru")
            ipProc.running = true
        }
    }

    function gotLocation(la, lo, name) {
        lat = la
        lon = lo
        city = name || city
        located = true
        fetchForecast()
    }

    function failed(why) {
        console.warn("Weather:", why)
        loading = false
        error = !ready
        retry.start()
    }

    // ───────── прогноз ─────────
    function fetchForecast() {
        loading = true
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
            "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure" +
            "&hourly=temperature_2m,weather_code,precipitation_probability" +
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max" +
            "&timezone=auto&forecast_days=3&wind_speed_unit=kmh"
        forecastProc.command = curl(url)
        forecastProc.running = true
    }

    function parseForecast(text, fromCache) {
        const wasReady = ready
        const j = JSON.parse(text)
        const c = j.current
        const d = j.daily
        const h = j.hourly

        temp = String(Math.round(c.temperature_2m))
        feels = String(Math.round(c.apparent_temperature))
        humidity = String(Math.round(c.relative_humidity_2m))
        wind = String(Math.round(c.wind_speed_10m))
        windDir = compass(c.wind_direction_10m)
        pressure = Math.round(c.surface_pressure * 0.75006) + " мм"
        desc = descFor(c.weather_code)
        icon = iconFor(c.weather_code, c.is_day === 1)
        uv = String(Math.round(d.uv_index_max[0]))
        sunrise = String(d.sunrise[0]).slice(11, 16)
        sunset = String(d.sunset[0]).slice(11, 16)

        const names = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
        days = d.time.map((t, i) => ({
            label: i === 0 ? "Сегодня" : (i === 1 ? "Завтра" : names[new Date(t + "T12:00:00").getDay()]),
            hi: Math.round(d.temperature_2m_max[i]),
            lo: Math.round(d.temperature_2m_min[i]),
            icon: iconFor(d.weather_code[i], true),
            desc: descFor(d.weather_code[i])
        }))

        // 8 точек с шагом 3 часа, начиная с текущего часа
        let start = 0
        const nowHour = String(c.time).slice(0, 13)
        for (let i = 0; i < h.time.length; i++) if (String(h.time[i]).slice(0, 13) === nowHour) { start = i; break }
        const pts = []
        for (let k = start; k < h.time.length && pts.length < 8; k += 3) {
            const hr = parseInt(String(h.time[k]).slice(11, 13))
            pts.push({
                when: k - start,
                temp: Math.round(h.temperature_2m[k]),
                icon: iconFor(h.weather_code[k], hr >= 6 && hr < 21),
                label: String(h.time[k]).slice(11, 13)
            })
        }
        hourly = pts

        // предупреждение, если в ближайшие часы осадки, а сейчас их нет
        if (!fromCache && wasReady) {
            let what = ""
            for (let q = 1; q < Math.min(3, pts.length) && what === ""; q++) {
                const ic = pts[q].icon
                if (ic === icon) continue
                if (ic === "\ue31d") what = "Гроза"
                else if (ic === "\ue318" || ic === "\ue319") what = "Дождь"
                else if (ic === "\ue31a") what = "Снег"
            }
            if (what !== "" && Date.now() - lastAlert > 6 * 3600 * 1000) {
                lastAlert = Date.now()
                UI.flash(icon, what + " в ближайшие часы", temp + "° сейчас", "", "weather", "weather")
            }
        }

        ready = true
        error = false
        loading = false
        if (!fromCache) {
            lastFetch = Date.now()
            const blob = JSON.stringify({ city: city, lat: lat, lon: lon, forecast: text })
            Quickshell.execDetached(["sh", "-c",
                'mkdir -p "$HOME/.cache/quickshell" && printf "%s" "$1" > "$HOME/.cache/quickshell/weather.json"',
                "sh", blob])
        }
    }

    function refresh(force) {
        if (loading) return
        if (!force && Date.now() - lastFetch < 5 * 60000) return
        if (located) fetchForecast()
        else locate()
    }

    // ───────── процессы ─────────
    Process {
        id: geoProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text).results
                    if (!r || r.length === 0) { root.failed("город не найден"); return }
                    root.gotLocation(r[0].latitude, r[0].longitude, r[0].name)
                } catch (e) { root.failed("геокодер: " + e) }
            }
        }
        onExited: code => { if (code !== 0) root.failed("геокодер недоступен") }
    }
    Process {
        id: ipProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text)
                    if (o.status !== "success") throw "status"
                    root.gotLocation(o.lat, o.lon, o.city)
                } catch (e) { root.ipFallback() }
            }
        }
        onExited: code => { if (code !== 0) root.ipFallback() }
    }
    Process {
        id: ip2Proc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text)
                    if (!o.success) throw "status"
                    root.gotLocation(o.latitude, o.longitude, o.city)
                } catch (e) { root.failed("не удалось определить место по IP") }
            }
        }
    }
    function ipFallback() {
        if (ipStage > 0 || ip2Proc.running) return
        ipStage = 1
        ip2Proc.command = curl("https://ipwho.is/?fields=success,city,latitude,longitude&lang=ru")
        ip2Proc.running = true
    }
    Process {
        id: forecastProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.parseForecast(text, false) }
                catch (e) { root.failed("ответ прогноза: " + e) }
            }
        }
        onExited: code => { if (code !== 0) root.failed("Open-Meteo недоступен") }
    }

    // ───────── кэш: показываем сразу, пока идёт запрос ─────────
    FileView {
        id: cacheFile
        path: root.cachePath
        onLoaded: {
            if (root.ready) return
            try {
                const o = JSON.parse(cacheFile.text())
                root.city = o.city || ""
                root.parseForecast(o.forecast, true)
            } catch (e) {}
        }
    }

    Timer { id: retry; interval: 120000; onTriggered: root.refresh(true) }
    Timer {
        interval: Math.max(5, Config.weatherRefreshMin) * 60000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh(true)
    }
}
