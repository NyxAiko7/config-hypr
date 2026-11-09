pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Настройки панели. Хранятся в ~/.config/quickshell/panel.json
// и применяются на лету. Пресеты меняют набор модулей, плотность
// и видимые элементы панели одним нажатием.
Singleton {
    id: root

    // ───────── положение и язык ─────────
    property string position: "top"     // top | bottom | left | right
    property string language: "ru"      // ru | en

    // ───────── активный пресет ─────────
    property string preset: "balanced"  // minimal | balanced | media | focus | custom

    // ───────── содержимое панели ─────────
    property var modules: ({
        bt: true, wifi: true, net: true, notif: true,
        music: true, weather: true, pomodoro: true, record: true
    })
    property bool showWorkspaces: true
    property bool showTitle: true
    property bool showTray: true
    property bool showWallpaper: true
    property bool showSettings: true
    property bool showKeyboard: true
    property bool showVolume: true
    property bool showBattery: true

    property bool widgetsEnabled: true
    property bool widgetClock: true
    property bool widgetPlayer: true

    // ───────── внешний вид ─────────
    property string density: "normal"   // compact | normal | roomy
    property int islandRadius: 16
    property int surfaceOpacity: 92     // 30..100 %
    property int fontSize: 12

    // ───────── личное / поведение ─────────
    property string avatarPath: ""
    property int lockAfterMin: 300
    property int sleepAfterMin: 600

    readonly property var positions: ["top", "bottom", "left", "right"]
    readonly property var languages: ["ru", "en"]
    readonly property var densities: ["compact", "normal", "roomy"]
    readonly property var presetKeys: ["minimal", "balanced", "media", "focus"]
    readonly property var showKeys: [
        "showWorkspaces", "showTitle", "showTray", "showWallpaper",
        "showSettings", "showKeyboard", "showVolume", "showBattery"
    ]

    // Готовые наборы панели
    readonly property var presetData: ({
        minimal: {
            density: "compact",
            modules: { bt: false, wifi: false, net: true, notif: true,
                       music: false, weather: false, pomodoro: false, record: false },
            showWorkspaces: false, showTitle: false, showTray: false,
            showWallpaper: false, showSettings: true, showKeyboard: false,
            showVolume: true, showBattery: true
        },
        balanced: {
            density: "normal",
            modules: { bt: true, wifi: true, net: true, notif: true,
                       music: true, weather: true, pomodoro: true, record: true },
            showWorkspaces: true, showTitle: true, showTray: true,
            showWallpaper: true, showSettings: true, showKeyboard: true,
            showVolume: true, showBattery: true
        },
        media: {
            density: "roomy",
            modules: { bt: true, wifi: true, net: true, notif: true,
                       music: true, weather: true, pomodoro: false, record: true },
            showWorkspaces: true, showTitle: true, showTray: true,
            showWallpaper: false, showSettings: true, showKeyboard: false,
            showVolume: true, showBattery: true
        },
        focus: {
            density: "normal",
            modules: { bt: false, wifi: true, net: true, notif: true,
                       music: false, weather: false, pomodoro: true, record: false },
            showWorkspaces: true, showTitle: false, showTray: false,
            showWallpaper: false, showSettings: true, showKeyboard: true,
            showVolume: true, showBattery: true
        }
    })

    readonly property int barHeight: density === "compact" ? 32
                                   : density === "roomy" ? 46 : 38
    readonly property real surfaceAlpha: Math.max(0.30, Math.min(1, surfaceOpacity / 100))

    readonly property bool hasAvatar: avatarPath !== ""
    readonly property string avatarUrl: avatarPath === "" ? ""
        : "file://" + encodeURI(avatarPath).replace(/#/g, "%23").replace(/\?/g, "%3F")

    readonly property bool vertical: position === "left" || position === "right"
    readonly property bool horizontal: !vertical
    readonly property bool atTop: position === "top"
    readonly property bool atBottom: position === "bottom"
    readonly property bool atLeft: position === "left"
    readonly property bool atRight: position === "right"

    readonly property bool english: language === "en"

    function setPosition(p) {
        if (positions.indexOf(p) < 0 || position === p) return
        position = p
        save()
    }

    function setLanguage(l) {
        if (languages.indexOf(l) < 0 || language === l) return
        language = l
        save()
    }

    function setPreset(key) {
        const p = presetData[key]
        if (!p || presetKeys.indexOf(key) < 0) return
        preset = key
        density = p.density
        modules = Object.assign({}, p.modules)
        showWorkspaces = p.showWorkspaces
        showTitle = p.showTitle
        showTray = p.showTray
        showWallpaper = p.showWallpaper
        showSettings = p.showSettings
        showKeyboard = p.showKeyboard
        showVolume = p.showVolume
        showBattery = p.showBattery
        save()
    }

    function markCustom() {
        if (preset !== "custom") preset = "custom"
    }

    function setModule(key, on) {
        if (modules[key] === undefined || modules[key] === !!on) return
        const m = Object.assign({}, modules)
        m[key] = !!on
        modules = m
        markCustom()
        save()
    }

    function setShow(key, on) {
        if (showKeys.indexOf(key) < 0) return
        const v = !!on
        switch (key) {
        case "showWorkspaces": if (showWorkspaces === v) return; showWorkspaces = v; break
        case "showTitle":      if (showTitle === v) return; showTitle = v; break
        case "showTray":       if (showTray === v) return; showTray = v; break
        case "showWallpaper":  if (showWallpaper === v) return; showWallpaper = v; break
        case "showSettings":   if (showSettings === v) return; showSettings = v; break
        case "showKeyboard":   if (showKeyboard === v) return; showKeyboard = v; break
        case "showVolume":     if (showVolume === v) return; showVolume = v; break
        case "showBattery":    if (showBattery === v) return; showBattery = v; break
        default: return
        }
        markCustom()
        save()
    }

    function setWidget(key, on) {
        const v = !!on
        switch (key) {
        case "widgetClock":  if (widgetClock === v) return; widgetClock = v; break
        case "widgetPlayer": if (widgetPlayer === v) return; widgetPlayer = v; break
        default: return
        }
        save()
    }

    function setWidgets(on) {
        const v = !!on
        if (widgetsEnabled === v) return
        widgetsEnabled = v
        save()
    }

    function setDensity(d) {
        if (densities.indexOf(d) < 0 || density === d) return
        density = d
        markCustom()
        save()
    }

    function setIslandRadius(n) {
        const v = Math.max(0, Math.min(30, Math.round(Number(n) || 0)))
        if (v === islandRadius) return
        islandRadius = v
        save()
    }

    function setSurfaceOpacity(n) {
        const v = Math.max(30, Math.min(100, Math.round(Number(n) || 92)))
        if (v === surfaceOpacity) return
        surfaceOpacity = v
        save()
    }

    function setFontSize(n) {
        const v = Math.max(8, Math.min(24, Math.round(Number(n) || 12)))
        if (v === fontSize) return
        fontSize = v
        save()
    }

    function setAvatar(path) {
        if (typeof path !== "string") return
        const p = path.trim()
        if (p === "" || avatarPath === p) return
        avatarPath = p
        save()
    }

    function clearAvatar() {
        if (avatarPath === "") return
        avatarPath = ""
        save()
    }

    function setLockAfterMin(n) {
        const v = Math.max(0, Math.round(Number(n) || 0))
        if (v === lockAfterMin) return
        lockAfterMin = v
        save()
    }

    function setSleepAfterMin(n) {
        const v = Math.max(0, Math.round(Number(n) || 0))
        if (v === sleepAfterMin) return
        sleepAfterMin = v
        save()
    }

    function save() {
        configFile.setText(JSON.stringify({
            position: position,
            language: language,
            preset: preset,
            density: density,
            modules: modules,
            showWorkspaces: showWorkspaces,
            showTitle: showTitle,
            showTray: showTray,
            showWallpaper: showWallpaper,
            showSettings: showSettings,
            showKeyboard: showKeyboard,
            showVolume: showVolume,
            showBattery: showBattery,
            widgetsEnabled: widgetsEnabled,
            widgetClock: widgetClock,
            widgetPlayer: widgetPlayer,
            islandRadius: islandRadius,
            surfaceOpacity: surfaceOpacity,
            fontSize: fontSize,
            avatar: avatarPath,
            lockAfterMin: lockAfterMin,
            sleepAfterMin: sleepAfterMin
        }, null, 2))
    }

    FileView {
        id: configFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
              + "/quickshell/panel.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: save()
        onLoaded: {
            try {
                const j = JSON.parse(configFile.text() || "{}")
                if (root.positions.indexOf(j.position) >= 0) root.position = j.position
                if (root.languages.indexOf(j.language) >= 0) root.language = j.language
                if (root.presetKeys.indexOf(j.preset) >= 0 || j.preset === "custom") root.preset = j.preset
                if (root.densities.indexOf(j.density) >= 0) root.density = j.density
                if (j.modules && typeof j.modules === "object")
                    root.modules = Object.assign({}, root.modules, j.modules)
                if (typeof j.showWorkspaces === "boolean") root.showWorkspaces = j.showWorkspaces
                if (typeof j.showTitle === "boolean") root.showTitle = j.showTitle
                if (typeof j.showTray === "boolean") root.showTray = j.showTray
                if (typeof j.showWallpaper === "boolean") root.showWallpaper = j.showWallpaper
                if (typeof j.showSettings === "boolean") root.showSettings = j.showSettings
                if (typeof j.showKeyboard === "boolean") root.showKeyboard = j.showKeyboard
                if (typeof j.showVolume === "boolean") root.showVolume = j.showVolume
                if (typeof j.showBattery === "boolean") root.showBattery = j.showBattery
                if (typeof j.widgetsEnabled === "boolean") root.widgetsEnabled = j.widgetsEnabled
                if (typeof j.widgetClock === "boolean") root.widgetClock = j.widgetClock
                if (typeof j.widgetPlayer === "boolean") root.widgetPlayer = j.widgetPlayer
                if (typeof j.islandRadius === "number") root.islandRadius = j.islandRadius
                if (typeof j.surfaceOpacity === "number") root.surfaceOpacity = j.surfaceOpacity
                if (typeof j.fontSize === "number") root.fontSize = j.fontSize
                if (typeof j.avatar === "string") root.avatarPath = j.avatar
                if (typeof j.lockAfterMin === "number") root.lockAfterMin = j.lockAfterMin
                if (typeof j.sleepAfterMin === "number") root.sleepAfterMin = j.sleepAfterMin
            } catch (e) {
                console.warn("PanelConfig: не могу разобрать panel.json:", e)
            }
        }
    }
}
