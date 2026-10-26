pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Сколько ватт сейчас уходит из батареи (или заряжает её).
// Читаем напрямую из /sys/class/power_supply — работает и там, где UPower не отдаёт мощность.
Singleton {
    id: root

    property bool available: false
    property real watts: 0                     // всегда ≥ 0
    property string status: ""                 // Charging | Discharging | Full | Not charging

    // что показывать: sysfs, а если его нет — данные UPower
    readonly property real shown: available ? watts : Math.abs(UPower.displayDevice.changeRate || 0)

    function text() {
        return shown.toFixed(1) + " Вт"
    }

    readonly property string script:
        'for b in /sys/class/power_supply/BAT*; do [ -d "$b" ] || continue; ' +
        'p=$(cat "$b/power_now" 2>/dev/null); ' +
        'if [ -z "$p" ] || [ "$p" = 0 ]; then ' +
        '  c=$(cat "$b/current_now" 2>/dev/null); v=$(cat "$b/voltage_now" 2>/dev/null); ' +
        '  if [ -n "$c" ] && [ -n "$v" ]; then p=$(( c * v / 1000000 )); fi; ' +
        'fi; ' +
        's=$(cat "$b/status" 2>/dev/null); echo "${p:-0} $s"; break; done'

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: SplitParser {
            onRead: d => {
                const line = d.trim()
                if (line === "") return
                const sp = line.indexOf(" ")
                const uw = parseFloat(sp > 0 ? line.slice(0, sp) : line)
                root.status = sp > 0 ? line.slice(sp + 1) : ""
                root.available = isFinite(uw)
                root.watts = isFinite(uw) ? Math.abs(uw) / 1e6 : 0
            }
        }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
