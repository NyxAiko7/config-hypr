pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property int cpu: 0
    property int mem: 0
    property int disk: 0
    property int temp: 0              // °C, 0 = нет датчика
    property int uptimeSec: 0
    property var lastCpu: [0, 0]

    readonly property string uptimeText: {
        const h = Math.floor(uptimeSec / 3600), m = Math.floor((uptimeSec % 3600) / 60)
        return h > 0 ? h + " ч " + m + " мин" : m + " мин"
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{print $2+$3+$4+$7+$8, $2+$3+$4+$5+$6+$7+$8}' /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(" ").map(Number)
                const dt = p[1] - root.lastCpu[1]
                if (dt > 0) root.cpu = Math.round(100 * (p[0] - root.lastCpu[0]) / dt)
                root.lastCpu = p
            }
        }
    }
    Process {
        id: memProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%d\", (t-a)*100/t}' /proc/meminfo"]
        stdout: SplitParser { onRead: data => root.mem = parseInt(data) }
    }
    Process {
        id: miscProc
        command: ["sh", "-c",
            `d=$(df -P / | awk 'NR==2{sub("%","",$5); print $5}'); u=$(cut -d. -f1 /proc/uptime); t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); echo "$d $u $t"`]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(" ").map(Number)
                if (p.length >= 3) {
                    root.disk = p[0] || 0
                    root.uptimeSec = p[1] || 0
                    root.temp = Math.round((p[2] || 0) / 1000)
                }
            }
        }
    }
    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: { cpuProc.running = true; memProc.running = true; miscProc.running = true }
    }
}
