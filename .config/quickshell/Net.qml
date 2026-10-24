pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Сеть через NetworkManager (nmcli): статус, список Wi-Fi, подключение
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool connected: false
    property string kind: ""          // "wifi" | "ethernet" | ""
    property string connection: ""
    property int strength: 0
    readonly property string icon: kind === "ethernet" ? "\uf0ac" : "\uf1eb"

    property var networks: []         // [{ssid, signal, secured, inUse, saved}]
    property var rawNets: []
    property var savedNames: []
    property bool scanning: false
    property bool wantList: false     // страница Wi-Fi открыта
    property string connecting: ""
    property string lastError: ""
    property bool usedPassword: false
    property string pendingSsid: ""

    // разбор строк nmcli -t (двоеточия экранируются как \:)
    function splitTerse(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (ch === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (ch === ":") { out.push(cur); cur = "" }
            else cur += ch
        }
        out.push(cur)
        return out
    }

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
            const p = splitTerse(lines[i])
            if (p.length < 3 || p[1] !== "connected") continue
            if (p[0] === "ethernet") { k = "ethernet"; c = p.slice(2).join(":"); break }
            if (p[0] === "wifi" && k === "") { k = "wifi"; c = p.slice(2).join(":") }
        }
        kind = k
        connection = c
        connected = k !== ""
        if (k === "wifi") sigProc.running = true
    }

    function rebuild() {
        const saved = savedNames
        const list = rawNets.map(n => ({
            ssid: n.ssid, signal: n.signal, secured: n.secured, inUse: n.inUse,
            saved: saved.indexOf(n.ssid) >= 0
        }))
        list.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
        networks = list
    }

    function parseList(text) {
        const seen = {}
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "") continue
            const f = splitTerse(lines[i])
            const ssid = f[1]
            if (!ssid) continue
            const inUse = f[0] === "*"
            const sig = parseInt(f[2]) || 0
            const sec = f[3] || ""
            const secured = sec !== "" && sec !== "--"
            const old = seen[ssid]
            if (!old) seen[ssid] = { ssid: ssid, signal: sig, secured: secured, inUse: inUse }
            else {
                old.signal = Math.max(old.signal, sig)
                old.inUse = old.inUse || inUse
            }
        }
        rawNets = Object.keys(seen).map(k => seen[k])
        rebuild()
    }

    function scan() {
        if (scanning) return
        scanning = true
        savedProc.running = true
        rescanProc.running = true
    }

    function friendly(err) {
        const e = String(err)
        if (e.indexOf("Secrets were required") >= 0 || e.indexOf("password") >= 0) return "Неверный пароль"
        if (e.indexOf("No network with SSID") >= 0) return "Сеть не найдена"
        if (e.indexOf("timeout") >= 0 || e.indexOf("Timeout") >= 0) return "Время подключения истекло"
        return e.replace(/^Error:\s*/, "").trim() || "Не удалось подключиться"
    }

    function connectTo(ssid, password) {
        if (connectProc.running) return
        connecting = ssid
        pendingSsid = ssid
        lastError = ""
        usedPassword = !!password
        if (password)
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        else if (savedNames.indexOf(ssid) >= 0)
            connectProc.command = ["nmcli", "connection", "up", "id", ssid]
        else
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }
    function disconnectCurrent() {
        if (connection !== "")
            Quickshell.execDetached(["nmcli", "connection", "down", "id", connection])
        later.restart()
    }
    function forget(ssid) {
        Quickshell.execDetached(["nmcli", "connection", "delete", "id", ssid])
        later.restart()
    }

    Timer {
        id: later
        interval: 1200
        onTriggered: { root.refresh(); if (root.wantList) root.scan() }
    }
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

    // сканирование → список → сохранённые профили
    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: listProc.running = true
    }
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: { root.parseList(text); root.scanning = false }
        }
        onExited: root.scanning = false
    }
    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = []
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const f = root.splitTerse(lines[i])
                    if (f.length >= 2 && (f[1].indexOf("wireless") >= 0 || f[1] === "wifi")) names.push(f[0])
                }
                root.savedNames = names
                root.rebuild()
            }
        }
    }

    // подключение
    Process {
        id: connectProc
        stderr: StdioCollector { id: connErr }
        onExited: code => {
            root.connecting = ""
            if (code !== 0) errTimer.start()
            else { root.lastError = ""; later.restart() }
        }
    }
    Timer {
        id: errTimer
        interval: 200
        onTriggered: {
            root.lastError = root.friendly(connErr.text)
            // неудачный профиль с новым паролем не оставляем
            if (root.usedPassword && root.pendingSsid !== "")
                Quickshell.execDetached(["nmcli", "connection", "delete", "id", root.pendingSsid])
            later.restart()
        }
    }
}
