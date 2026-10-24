pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Быстрые действия. Нужны: grim, slurp, wl-clipboard, libnotify (скриншоты),
// hyprpicker (пипетка), hyprsunset (ночной свет)
Singleton {
    id: root

    property bool night: false

    function screenshot(region) {
        const script =
            'sleep 0.4; mkdir -p "$HOME/Pictures/Screenshots"; ' +
            'f="$HOME/Pictures/Screenshots/$(date +%F_%H-%M-%S).png"; ' +
            (region ? 'g=$(slurp) || exit 0; grim -g "$g" "$f"' : 'grim "$f"') +
            ' && { command -v wl-copy >/dev/null 2>&1 && wl-copy < "$f"; ' +
            'notify-send -i "$f" "Скриншот сохранён" "$f"; }'
        Quickshell.execDetached(["sh", "-c", script])
    }

    function pick() {
        Quickshell.execDetached(["sh", "-c",
            'sleep 0.3; c=$(hyprpicker -a 2>/dev/null) && notify-send "Цвет скопирован" "$c"'])
    }

    function toggleNight() {
        if (night) Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
        else Quickshell.execDetached(["hyprsunset", "-t", "4000"])
        night = !night
        recheck.restart()
    }

    function refresh() { nightProc.running = true }

    Timer { id: recheck; interval: 1200; onTriggered: root.refresh() }
    Process {
        id: nightProc
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => root.night = (code === 0)
    }
    Component.onCompleted: refresh()
}
