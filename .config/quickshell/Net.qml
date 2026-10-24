pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Сеть через NetworkManager (nmcli): статус, список Wi-Fi, подключение, подробности
Singleton {
    id: root

    // ── основное ──
    property bool wifiEnabled: false
    property bool connected: false
    property string kind: ""          // "wifi" | "ethernet" | ""
    property string connection: ""
    property string iface: ""
    property int strength: 0
    readonly property string icon: kind === "ethernet" ? "\uf0ac" : "\uf1eb"

    // ── подробности (обновляются, пока открыт центр управления) ──
    property bool detailsActive: false
    property string ip: ""
    property string gateway: ""
    property string dns: ""
    property string band: ""          // "5 ГГц"
    property string security: ""      // "WPA2"
    property string linkSpeed: ""     // "540 Мбит/с"
    property string connectivity: "unknown"   // full | limited | portal | none | unknown
    property int latency: -1          // мс, -1 = нет ответа
    property real rxRate: 0           // байт/с
    property real txRate: 0
    property real prevRx: -1
    property real prevTx: -1
    property double prevT: 0

    // ── список сетей ──
    property var networks: []         // [{ssid, signal, secured, inUse, saved}]
    property var rawNets: []
    property var savedNames: []
    property bool scanning: false
    property bool wantList: false     // страница Wi-Fi открыта
    property string connecting: ""
    property string lastError: ""
    property bool usedPassword: false
    property string pendingSsid: ""

    // ───────── вспомогательное ─────────
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

    function fmtRate(b) {
        if (!isFinite(b) || b < 0) b = 0
        if (b < 1024) return Math.round(b) + " Б/с"
        if (b < 1024 * 1024) return Math.round(b / 1024) + " КБ/с"
        return (b / 1048576).toFixed(1) + " МБ/с"
    }

    // ───────── обновление ─────────
    function refresh() {
        radioProc.running = true
        statusProc.running = true
        if (detailsActive) {
            connProc.running = true
            if (iface !== "") loadDetails()
        }
    }
    function loadDetails() {
        detailsProc.command = ["sh", "-c",
            'i="$1"; nmcli -t -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show "$i" 2>/dev/null; echo "SPEED:$(cat /sys/class/net/$i/speed 2>/dev/null)"',
            "sh", iface]
        detailsProc.running = true
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"])
        wifiEnabled = !wifiEnabled
        later.restart()
    }

    function parseStatus(text) {
        let k = "", c = "", dev = ""
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const p = splitTerse(lines[i])
            // DEVICE:TYPE:STATE:CONNECTION
            if (p.length < 4 || p[2] !== "connected") continue
            if (p[1] === "ethernet") { k = "ethernet"; c = p.slice(3).join(":"); dev = p[0]; break }
            if (p[1] === "wifi" && k === "") { k = "wifi"; c = p.slice(3).join(":"); dev = p[0] }
        }
        const changed = dev !== iface
        kind = k
        connection = c
        iface = dev
        connected = k !== ""
        if (!connected) {
            ip = ""; gateway = ""; dns = ""; band = ""; security = ""; linkSpeed = ""
            rxRate = 0; txRate = 0; latency = -1
        }
        if (changed) { prevRx = -1; prevTx = -1 }
        if (k === "wifi") sigProc.running = true
        if (detailsActive && dev !== "") loadDetails()
    }

    function parseDetails(text) {
        const lines = text.split("\n")
        let gotIp = "", gotGw = "", gotDns = "", speed = ""
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "") continue
            const f = splitTerse(lines[i])
            const key = f[0]
            const val = f.slice(1).join(":")
            if (key.indexOf("IP4.ADDRESS") === 0 && gotIp === "") gotIp = val.split("/")[0]
            else if (key === "IP4.GATEWAY") gotGw = val
            else if (key.indexOf("IP4.DNS") === 0 && gotDns === "") gotDns = val
            else if (key === "SPEED") speed = val
        }
        ip = gotIp
        gateway = gotGw
        dns = gotDns
        if (kind === "ethernet") {
            const n = parseInt(speed)
            linkSpeed = n > 0 ? (n >= 1000 ? (n / 1000) + " Гбит/с" : n + " Мбит/с") : ""
        }
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
    function copyIp() {
        if (ip !== "")
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", ip])
    }

    // ───────── таймеры ─────────
    Timer {
        id: later
        interval: 1200
        onTriggered: { root.refresh(); if (root.wantList) root.scan() }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    // скорость приёма/отдачи — раз в секунду, пока открыт центр управления
    Timer {
        interval: 1000
        running: root.detailsActive && root.iface !== ""
        repeat: true
        onTriggered: {
            trafficProc.command = ["sh", "-c",
                "sed 's/:/ /' /proc/net/dev | awk -v d=\"$1\" '$1==d {print $2, $10}'",
                "sh", root.iface]
            trafficProc.running = true
        }
    }
    // пинг — раз в 8 секунд
    Timer {
        interval: 8000
        running: root.detailsActive && root.connected
        repeat: true
        triggeredOnStart: true
        onTriggered: pingProc.running = true
    }
    onDetailsActiveChanged: {
        if (detailsActive) { prevRx = -1; prevTx = -1; refresh() }
        else { rxRate = 0; txRate = 0 }
    }

    // ───────── процессы ─────────
    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser { onRead: d => root.wifiEnabled = (d.trim() === "enabled") }
    }
    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector { onStreamFinished: root.parseStatus(text) }
    }
    // сигнал, защита, диапазон и скорость активной Wi-Fi сети
    Process {
        id: sigProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,FREQ,RATE", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("*:") !== 0) continue
                    const f = root.splitTerse(lines[i])
                    root.strength = parseInt(f[1]) || 0
                    const sec = (f[2] || "").trim()
                    root.security = (sec === "" || sec === "--") ? "Открытая" : sec.split(" ").slice(-1)[0]
                    const mhz = parseInt(f[3]) || 0
                    root.band = mhz === 0 ? "" : (mhz < 3000 ? "2.4 ГГц" : (mhz < 5900 ? "5 ГГц" : "6 ГГц"))
                    root.linkSpeed = (f[4] || "").replace("Mbit/s", "Мбит/с").trim()
                    break
                }
            }
        }
    }
    Process {
        id: detailsProc
        stdout: StdioCollector { onStreamFinished: root.parseDetails(text) }
    }
    Process {
        id: connProc
        command: ["nmcli", "-t", "-f", "CONNECTIVITY", "general"]
        stdout: SplitParser { onRead: d => root.connectivity = d.trim() }
    }
    Process {
        id: trafficProc
        stdout: SplitParser {
            onRead: d => {
                const p = d.trim().split(" ").map(Number)
                if (p.length < 2 || isNaN(p[0])) return
                const t = Date.now()
                if (root.prevRx >= 0 && t > root.prevT) {
                    const dt = (t - root.prevT) / 1000
                    root.rxRate = Math.max(0, (p[0] - root.prevRx) / dt)
                    root.txRate = Math.max(0, (p[1] - root.prevTx) / dt)
                }
                root.prevRx = p[0]
                root.prevTx = p[1]
                root.prevT = t
            }
        }
    }
    Process {
        id: pingProc
        command: ["ping", "-c", "1", "-W", "2", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /time=([0-9.]+)/.exec(text)
                root.latency = m ? Math.round(parseFloat(m[1])) : -1
            }
        }
        onExited: code => { if (code !== 0) root.latency = -1 }
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
