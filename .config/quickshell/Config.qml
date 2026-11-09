pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Личные настройки
Singleton {
    id: root

    // Погода: достаточно оставить всё пустым — место определится по IP.
    // Можно указать город (найдётся автоматически) или точные координаты.
    property string weatherCity: ""
    property string weatherLat: ""        // например "55.75"
    property string weatherLon: ""        // например "37.62"
    property int weatherRefreshMin: 20

    // Поиск из лаунчера: «? запрос»
    readonly property string searchUrl: "https://duckduckgo.com/?q="

    // Папка с обоями для переключателя. Пусто = ~/Pictures/Wallpapers (или ~/Pictures)
    readonly property string wallpaperDir: ""
    // Своя команда установки обоев (shell). Путь к картинке лежит в $f.
    // Пример: "awww img \"$f\" --transition-type wipe"
    // Пусто = автоопределение: awww → swww → hyprpaper → swaybg
    readonly property string wallpaperSetter: ""

    signal weatherChanged()

    function setWeatherCity(v) {
        v = String(v)
        if (v === weatherCity) return
        weatherCity = v
        save()
        weatherChanged()
    }

    function setWeatherLat(v) {
        v = String(v)
        if (v === weatherLat) return
        weatherLat = v
        save()
        weatherChanged()
    }

    function setWeatherLon(v) {
        v = String(v)
        if (v === weatherLon) return
        weatherLon = v
        save()
        weatherChanged()
    }

    function setWeatherRefreshMin(v) {
        const n = Math.max(5, parseInt(v) || 20)
        if (n === weatherRefreshMin) return
        weatherRefreshMin = n
        save()
        weatherChanged()
    }

    function save() {
        configFile.setText(JSON.stringify({
            weatherCity: weatherCity,
            weatherLat: weatherLat,
            weatherLon: weatherLon,
            weatherRefreshMin: weatherRefreshMin
        }, null, 2))
    }

    FileView {
        id: configFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
              + "/quickshell/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: save()
        onLoaded: {
            try {
                const j = JSON.parse(configFile.text() || "{}")
                if (typeof j.weatherCity === "string") root.weatherCity = j.weatherCity
                if (typeof j.weatherLat === "string") root.weatherLat = j.weatherLat
                if (typeof j.weatherLon === "string") root.weatherLon = j.weatherLon
                if (typeof j.weatherRefreshMin === "number") root.weatherRefreshMin = j.weatherRefreshMin
            } catch (e) {
                console.warn("Config: не могу разобрать config.json:", e)
            }
        }
    }
}
