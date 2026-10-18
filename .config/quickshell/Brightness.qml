pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Яркость через brightnessctl
Singleton {
    id: root

    property real value: 0
    property bool available: false

    function refresh() { getProc.running = true }
    function set(v) {
        value = Math.max(0.01, Math.min(1, v))
        throttle.restart()
    }

    Timer {
        id: throttle
        interval: 60
        onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.round(root.value * 100) + "%"])
    }
    Process {
        id: getProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: d => {
                const p = d.split(",")
                if (p.length >= 5) { root.available = true; root.value = parseInt(p[3]) / 100 }
            }
        }
    }
    Component.onCompleted: refresh()
}
