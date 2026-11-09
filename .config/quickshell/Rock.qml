pragma Singleton
import QtQuick
import Quickshell

// Единая палитра оболочки. Никаких переключаемых тем:
// все цвета приходят из Theme (палитра текущих обоев).
Singleton {
    readonly property bool comic: false
    readonly property bool hsr: false
    readonly property bool marisa: false
    readonly property bool sao: false
    readonly property bool light: Theme.light

    // «чернила» и «свет» — производные от палитры обоев
    readonly property color ink:       Theme.light ? "#101014" : Theme.bg
    readonly property color creamBase: Theme.text
    readonly property color cream:     Theme.text
    readonly property color ink2:      Theme.surface
    readonly property color muted:     Theme.muted
    readonly property color faint:     Theme.muted

    readonly property color pink:      Theme.accent
    readonly property color pinkDeep:  Qt.darker(Theme.accent, 1.25)
    readonly property color yellow:    Theme.accent2
    readonly property color cyan:      Theme.accent2
    readonly property color purple:    Theme.accent
    readonly property color orange:    Theme.warn
    readonly property color gold:      Theme.accent
    readonly property color starlight: Theme.text

    readonly property color hp:     "#6ee7a0"
    readonly property color danger: Theme.warn

    readonly property string display: "DejaVu Sans"
    readonly property string mono: Theme.font

    // геометрия: чистые скруглённые поверхности без декоративных теней
    readonly property real panelRadius:  PanelConfig.islandRadius
    readonly property real panelBorder:  1
    readonly property real panelShadow:  0
    readonly property real panelTilt:    0
    readonly property real pillRadius:   Math.max(6, PanelConfig.islandRadius - 6)
    readonly property real chipRadius:   Math.max(5, PanelConfig.islandRadius - 7)
    readonly property real chipBorder:   1
    readonly property real chipOffset:   0

    // общие поверхности меню
    readonly property color uiSurface:  Theme.surface
    readonly property color uiSurface2: Theme.light
        ? Qt.darker(Theme.surface, 1.04)
        : Qt.lighter(Theme.surface, 1.10)
    readonly property color uiActive: Theme.light
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
        : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.26)
    readonly property color uiText: cream
    readonly property color uiSub: muted
    readonly property color uiEdge: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
    readonly property color uiHover: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
    readonly property color uiAccent: Theme.accent
    readonly property color uiOnActive: Theme.textOnAccent
    readonly property real uiRadius:   PanelConfig.islandRadius
    readonly property real uiRadiusSm: Math.max(8, PanelConfig.islandRadius - 6)
    readonly property real uiBorder:   1
    readonly property real uiShadow:   0

    // поверхности панели
    readonly property color paper:      uiSurface
    readonly property color islandFill: Theme.islandBg
    readonly property color barFill:    Theme.islandBg
    readonly property color barText:    Theme.text
    readonly property color barSub:     Theme.muted
    readonly property color barLine:    Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)

    function a(c, alpha) {
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
}
