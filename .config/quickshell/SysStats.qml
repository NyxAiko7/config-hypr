pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property int cpu: 0
    property int mem: 0
    property var lastCpu: [0, 0]

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
    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: { cpuProc.running = true; memProc.running = true }
    }
}
