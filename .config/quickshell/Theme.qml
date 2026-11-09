pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Единая палитра оболочки. Никаких готовых тем: все цвета выводятся
// из текущих обоев через pywal (~/.cache/wal/colors.json).
// Светлая или тёмная сторона выбирается автоматически по яркости обоев.
Singleton {
    id: root

    property color bg:           "#14121a"
    property color popupBg:      "#f214121a"
    property color surface:      "#221f2c"
    property color text:         "#f2eef7"
    property color muted:        "#9a93a8"
    property color accent:       "#b69cff"
    property color accent2:      "#5fe0d0"
    property color warn:         "#ff6b81"
    property color textOnAccent: "#14121a"
    property color hairline:     "#18ffffff"

    property bool light: false
    property string wallpaper: ""

    readonly property int barHeight: PanelConfig.barHeight
    readonly property int radius: PanelConfig.islandRadius + 2
    readonly property int islandRadius: Math.max(0, PanelConfig.islandRadius - 1)
    readonly property int islandHeight: barHeight - 6
    readonly property int islandInset: (barHeight - islandHeight) / 2

    // «матовое стекло» островов: мягкий градиент, тонкая кромка и блик сверху
    readonly property color islandBg:     Qt.rgba(bg.r, bg.g, bg.b, PanelConfig.surfaceAlpha)
    readonly property color islandTop:    Qt.lighter(islandBg, 1.16)
    readonly property color islandBottom: Qt.darker(islandBg, 1.10)
    readonly property color islandEdge:   Qt.rgba(text.r, text.g, text.b, 0.10)
    readonly property color islandShine:  Qt.rgba(text.r, text.g, text.b, 0.16)
    readonly property color islandHover:  Qt.rgba(accent.r, accent.g, accent.b, 0.18)

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: PanelConfig.fontSize
    readonly property int iconSize: Math.round(PanelConfig.fontSize * 1.15)

    property string lastRaw: ""
    property bool loadedOnce: false

    Behavior on bg           { ColorAnimation { duration: 420 } }
    Behavior on popupBg      { ColorAnimation { duration: 420 } }
    Behavior on surface      { ColorAnimation { duration: 420 } }
    Behavior on text         { ColorAnimation { duration: 420 } }
    Behavior on muted        { ColorAnimation { duration: 420 } }
    Behavior on accent       { ColorAnimation { duration: 420 } }
    Behavior on accent2      { ColorAnimation { duration: 420 } }
    Behavior on textOnAccent { ColorAnimation { duration: 420 } }

    function hex(c) {
        return "#" + [c.r, c.g, c.b].map(v => ("0" + Math.round(v * 255).toString(16)).slice(-2)).join("")
    }
    function hueDist(a, b) {
        const d = Math.abs(a - b)
        return Math.min(d, 1 - d)
    }
    function lum(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    }
    // делаем цвет из палитры обоев достаточно ярким и насыщенным
    function vivid(c, lMin, lMax) {
        const s = c.hslSaturation < 0.12 ? c.hslSaturation : Math.max(0.48, c.hslSaturation)
        const l = Math.max(lMin, Math.min(lMax, c.hslLightness + 0.18))
        return Qt.hsla(Math.max(0, c.hslHue), Math.min(1, s), l, 1)
    }

    function apply(j) {
        const base  = Qt.color(j.special.background)
        const fg    = Qt.color(j.special.foreground)
        const solid = Qt.rgba(base.r, base.g, base.b, 1)
        const isLight = lum(base) > 0.52

        light = isLight
        wallpaper = j.wallpaper || ""

        // два самых «цветных» и разных по оттенку цвета обоев
        const cands = []
        for (let i = 1; i <= 6; i++) {
            const c = Qt.color(j.colors["color" + i])
            cands.push({ c: c, score: c.hslSaturation * (0.4 + 0.6 * (1 - Math.abs(c.hslLightness - 0.5) * 2)) })
        }
        cands.sort((a, b) => b.score - a.score)
        const a1 = cands[0].c
        let a2 = cands[1].c
        for (let k = 1; k < cands.length; k++)
            if (hueDist(cands[k].c.hslHue, a1.hslHue) >= 0.09) { a2 = cands[k].c; break }

        if (isLight) {
            const hue = base.hslHue
            const sat = Math.min(0.20, base.hslSaturation)
            const nBg      = Qt.hsla(hue, sat, 0.95, 1)
            const nSurface = Qt.hsla(hue, sat, 0.89, 1)
            const nText    = Qt.hsla(fg.hslHue, Math.min(0.30, Math.max(0.05, fg.hslSaturation)), 0.16, 1)
            const nMuted   = Qt.hsla(nText.hslHue, Math.min(0.24, nText.hslSaturation), 0.44, 1)
            const nAccent  = Qt.hsla(a1.hslHue, Math.max(0.52, a1.hslSaturation), 0.44, 1)
            const nAccent2 = Qt.hsla(a2.hslHue, Math.max(0.48, a2.hslSaturation), 0.46, 1)

            bg           = nBg
            surface      = nSurface
            text         = nText
            muted        = nMuted
            accent       = nAccent
            accent2      = nAccent2
            popupBg      = Qt.rgba(nBg.r, nBg.g, nBg.b, 0.97)
            textOnAccent = nBg
            hairline     = Qt.rgba(nText.r, nText.g, nText.b, 0.12)
        } else {
            const nSurface = Qt.tint(solid, Qt.rgba(fg.r, fg.g, fg.b, 0.10))
            const nText    = Qt.hsla(fg.hslHue, Math.min(0.35, Math.max(0.02, fg.hslSaturation)),
                                     Math.max(0.86, fg.hslLightness), 1)
            const nMuted   = Qt.tint(solid, Qt.rgba(fg.r, fg.g, fg.b, 0.58))
            const nAccent  = vivid(a1, 0.64, 0.74)
            const nAccent2 = vivid(a2, 0.60, 0.72)

            bg           = solid
            surface      = nSurface
            text         = nText
            muted        = nMuted
            accent       = nAccent
            accent2      = nAccent2
            popupBg      = Qt.rgba(base.r, base.g, base.b, 0.96)
            textOnAccent = lum(nAccent) > 0.45 ? solid : "#ffffff"
            hairline     = Qt.rgba(fg.r, fg.g, fg.b, 0.08)
        }

        warn = Qt.hsla(0.97, 0.72, light ? 0.46 : 0.66, 1)

        if (loadedOnce) UI.flash("\uf53f", I18n.t("Цвета обновлены"), I18n.t("Из обоев"), "", "theme", "wallpaper")
        loadedOnce = true
    }

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
