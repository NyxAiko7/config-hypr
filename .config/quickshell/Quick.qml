pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Быстрые действия. Нужны: grim, slurp, wl-clipboard, libnotify (скриншоты),
// hyprpicker (пипетка), hyprsunset (ночной свет)
Singleton {
    id: root

    property bool night: false

    // ── режимы питания (power-profiles-daemon: powerprofilesctl) ──
    property string profile: ""            // power-saver | balanced | performance
    readonly property string profileName:
        profile === "power-saver" ? "Экономия" : (profile === "performance" ? "Мощность" : (profile === "balanced" ? "Баланс" : "Питание"))
    readonly property string profileIcon:
        profile === "power-saver" ? "\uf06c" : (profile === "performance" ? "\uf135" : "\uf0e4")

    function cycleProfile() {
        if (profile === "") {
            UI.flash("\uf0e4", "Режимы питания", "нужен power-profiles-daemon", "", "info", "")
            return
        }
        const order = ["power-saver", "balanced", "performance"]
        const next = order[(order.indexOf(profile) + 1) % order.length]
        Quickshell.execDetached(["powerprofilesctl", "set", next])
        profile = next
        UI.flash(profileIcon, "Режим: " + profileName, "", "", "info", "")
        recheckProfile.restart()
    }

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

    function refresh() { nightProc.running = true; profProc.running = true }

    Timer { id: recheck; interval: 1200; onTriggered: root.refresh() }
    Timer { id: recheckProfile; interval: 800; onTriggered: profProc.running = true }
    Process {
        id: profProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser { onRead: d => root.profile = d.trim() }
    }
    Process {
        id: nightProc
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => root.night = (code === 0)
    }
    Component.onCompleted: refresh()
}
