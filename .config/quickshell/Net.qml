pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Состояние сети через NetworkManager (nmcli)
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool connected: false
    property string kind: ""          // "wifi" | "ethernet" | ""
    property string connection: ""
    property int strength: 0
    readonly property string icon: kind === "ethernet" ? "\uf0ac" : "\uf1eb"

    function refresh() {
        radioProc.running = true
        statusProc.running = true
    }
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"])
        wifiEnabled = !wifiEnabled
        later.restart()
    }
    function parseStatus(text) {
        let k = "", c = ""
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const p = lines[i].split(":")
            if (p.length < 3 || p[1] !== "connected") continue
            if (p[0] === "ethernet") { k = "ethernet"; c = p.slice(2).join(":"); break }
            if (p[0] === "wifi" && k === "") { k = "wifi"; c = p.slice(2).join(":") }
        }
        kind = k
        connection = c
        connected = k !== ""
        if (k === "wifi") sigProc.running = true
    }

    Timer { id: later; interval: 1200; onTriggered: root.refresh() }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser { onRead: d => root.wifiEnabled = (d.trim() === "enabled") }
    }
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector { onStreamFinished: root.parseStatus(text) }
    }
    Process {
        id: sigProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++)
                    if (lines[i].indexOf("*:") === 0) root.strength = parseInt(lines[i].split(":")[1])
            }
        }
    }
}
