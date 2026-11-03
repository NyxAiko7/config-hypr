pragma Singleton
import QtQuick
import Quickshell

// Локальная палитра локскрина в духе Bocchi the Rock:
// кислотный розовый, лимонный жёлтый, бирюза и жирные чёрные контуры.
Singleton {
    readonly property color ink:       "#17131f"
    readonly property color ink2:      "#241d31"
    readonly property color pink:      "#ff4f8b"
    readonly property color pinkDeep:  "#d92f6a"
    readonly property color yellow:    "#ffd84f"
    readonly property color cyan:      "#4fd8ff"
    readonly property color purple:    "#8b6cff"
    readonly property color cream:     "#fff4e8"
    readonly property color paper:     "#fffaf2"
    readonly property color orange:    "#ff8a4c"
    readonly property color muted:     "#b9aecb"
    readonly property color faint:     "#7d7291"

    readonly property string display: "DejaVu Sans Condensed"
    readonly property string mono: Theme.font

    function a(c, alpha) {
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }
}
