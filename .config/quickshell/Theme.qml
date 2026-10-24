pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Цвета берутся из pywal (~/.cache/wal/colors.json).
// При каждом изменении палитры Quickshell сам пишет ~/.config/swaync/colors.css
// и перезагружает стиль SwayNC — шаблоны и симлинки pywal больше не нужны.
Singleton {
    id: root

    property color bg:           "#121018"
    property color popupBg:      "#f2121018"
    property color surface:      "#221f2c"
    property color text:         "#e8e6ef"
    property color muted:        "#8b879c"
    property color accent:       "#b69cff"
    property color accent2:      "#5fe0d0"
    property color warn:         "#ff8fa3"
    property color textOnAccent: "#121018"
    property color hairline:     "#12ffffff"

    readonly property int barHeight: 36
    readonly property int radius: 20
    readonly property int islandRadius: 18
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int iconSize: 14

    property string lastRaw: ""
    property bool loadedOnce: false

    Behavior on bg           { ColorAnimation { duration: 400 } }
    Behavior on popupBg      { ColorAnimation { duration: 400 } }
    Behavior on surface      { ColorAnimation { duration: 400 } }
    Behavior on text         { ColorAnimation { duration: 400 } }
    Behavior on muted        { ColorAnimation { duration: 400 } }
    Behavior on accent       { ColorAnimation { duration: 400 } }
    Behavior on accent2      { ColorAnimation { duration: 400 } }
    Behavior on textOnAccent { ColorAnimation { duration: 400 } }

    function hex(c) {
        return "#" + [c.r, c.g, c.b].map(v => ("0" + Math.round(v * 255).toString(16)).slice(-2)).join("")
    }
    function hueDist(a, b) {
        const d = Math.abs(a - b)
        return Math.min(d, 1 - d)
    }
    // делаем цвет pywal достаточно яркими и насыщенным для тёмного фона
    function vivid(c) {
        const s = c.hslSaturation < 0.1 ? c.hslSaturation : Math.max(0.45, c.hslSaturation)
        const l = Math.max(0.66, Math.min(0.78, c.hslLightness + 0.2))
        return Qt.hsla(Math.max(0, c.hslHue), Math.min(1, s), l, 1)
    }

    function apply(j) {
        const base  = Qt.color(j.special.background)
        const fg    = Qt.color(j.special.foreground)
        const solid = Qt.rgba(base.r, base.g, base.b, 1)

        // два самых «цветных» и разных по оттенку из color1..color6
        const cands = []
        for (let i = 1; i <= 6; i++) {
            const c = Qt.color(j.colors["color" + i])
            cands.push({ c: c, score: c.hslSaturation * Math.min(1, c.hslLightness * 2.5) })
        }
        cands.sort((a, b) => b.score - a.score)
        const a1 = cands[0].c
        let a2 = cands[1].c
        for (let k = 1; k < cands.length; k++)
            if (hueDist(cands[k].c.hslHue, a1.hslHue) >= 0.08) { a2 = cands[k].c; break }

        const nSurface = Qt.tint(solid, Qt.rgba(fg.r, fg.g, fg.b, 0.09))
        const nMuted   = Qt.tint(solid, Qt.rgba(fg.r, fg.g, fg.b, 0.55))
        const nAccent  = vivid(a1)
        const nAccent2 = vivid(a2)
        const nWarn    = Qt.color("#ff8fa3")

        bg           = solid
        popupBg      = Qt.rgba(base.r, base.g, base.b, 0.96)
        surface      = nSurface
        text         = fg
        muted        = nMuted
        accent       = nAccent
        accent2      = nAccent2
        warn         = nWarn
        textOnAccent = solid
        hairline     = Qt.rgba(fg.r, fg.g, fg.b, 0.07)

        exportSwaync([["bg", solid], ["fg", fg], ["surface", nSurface], ["muted", nMuted],
                      ["accent", nAccent], ["accent2", nAccent2], ["warn", nWarn], ["onaccent", solid]])

        if (loadedOnce) UI.flash("\uf1fc", "Тема обновлена", "Цвета из обоев", "", "theme")
        loadedOnce = true
    }

    // пишем colors.css для SwayNC и перезагружаем его стиль
    function exportSwaync(pairs) {
        const css = pairs.map(p => "@define-color " + p[0] + " " + hex(p[1]) + ";").join("\n") + "\n"
        swayProc.command = ["sh", "-c",
            'mkdir -p "$HOME/.config/swaync" && printf "%s" "$1" > "$HOME/.config/swaync/colors.css" && (swaync-client -rs >/dev/null 2>&1 || true)',
            "sh", css]
        swayProc.running = true
    }

    Process { id: swayProc }

    FileView {
        id: walFile
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: console.warn("Theme: не могу прочитать", walFile.path, "— запусти wal -i обои")
        onLoaded: {
            const raw = walFile.text()
            if (raw === root.lastRaw) return
            try {
                root.apply(JSON.parse(raw))
                root.lastRaw = raw
                console.log("Theme: палитра обновлена из", walFile.path)
            } catch (e) {
                console.warn("Theme: ошибка разбора colors.json:", e)
            }
        }
    }

    // подстраховка, если inotify пропустит перезапись файла
    Timer { interval: 2000; running: true; repeat: true; onTriggered: walFile.reload() }
}
