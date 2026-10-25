pragma Singleton
import QtQuick
import Quickshell

// Таймер фокуса: 25 минут работы, 5 минут отдыха
Singleton {
    id: root

    property string mode: "idle"          // idle | focus | break
    property int total: 0
    property int remaining: 0
    property int focusMin: 25
    property int breakMin: 5
    property int sessions: 0

    readonly property bool running: mode !== "idle"
    readonly property real progress: total > 0 ? 1 - remaining / total : 0

    function text() {
        const m = Math.floor(remaining / 60), s = remaining % 60
        return ("0" + m).slice(-2) + ":" + ("0" + s).slice(-2)
    }

    function start(kind) {
        mode = kind
        total = (kind === "focus" ? focusMin : breakMin) * 60
        remaining = total
        tick.restart()
        UI.flash(kind === "focus" ? "\uf017" : "\uf0f4",
                 kind === "focus" ? "Фокус " + focusMin + " мин" : "Перерыв " + breakMin + " мин",
                 kind === "focus" ? "Удачной работы" : "Отдохни от экрана", "", "info", "")
    }
    function stop() {
        mode = "idle"
        total = 0
        remaining = 0
        tick.stop()
    }
    // следующая фаза: фокус → перерыв, перерыв → стоп
    function skip() {
        if (mode === "focus") start("break")
        else stop()
    }

    function finish() {
        if (mode === "focus") {
            sessions++
            Quickshell.execDetached(["notify-send", "-a", "Фокус",
                "Фокус завершён", "Сессия " + sessions + " готова. Отдохни " + breakMin + " мин"])
            start("break")
        } else {
            Quickshell.execDetached(["notify-send", "-a", "Фокус",
                "Перерыв закончился", "Можно возвращаться к работе"])
            stop()
        }
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: { root.remaining--; if (root.remaining <= 0) root.finish() }
    }
}
