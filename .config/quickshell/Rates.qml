pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Курсы валют для лаунчера: «100 usd in rub», «€20 → евро».
// Источник — frankfurter.dev (без ключа, обновляется раз в сутки).
// Нужен curl. Без сети работает кэш из ~/.cache/quickshell/rates.json
Singleton {
    id: root

    property var rates: ({})            // base → { CUR: value }
    property string base: "EUR"
    property bool ready: false
    readonly property string cacheFile: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell/rates.json"

    function rate(a, b) {
        if (!ready) return 0
        if (a === base) return rates[b] || 0
        if (b === base) { const ra = rates[a]; return ra > 0 ? 1 / ra : 0 }
        const ra = rates[a], rb = rates[b]
        return (ra > 0 && rb > 0) ? rb / ra : 0
    }

    // пересчёт с мгновенным откликом в острове
    function fetchOne(from, to, amount) {
        const r = rate(from, to)
        if (r > 0) {
            UI.flash("\uf51e", Apps.fmtNum(amount * r) + " " + to, from + " → " + to, "", "info", "")
            return
        }
        pending = { from: from, to: to, amount: amount }
        UI.flash("\uf51e", "Обновляю курсы…", from + " → " + to, "", "info", "")
        load()
    }
    property var pending: null

    function load() { getProc.running = true }

    Process {
        id: getProc
        command: ["curl", "-fsS", "--max-time", "8", "https://api.frankfurter.dev/v1/latest"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    root.base = j.base || "EUR"
                    root.rates = j.rates || ({})
                    root.ready = true
                    saveProc.running = true
                    finish(true)
                } catch (e) { finish(false) }
            }
        }
        onExited: code => { if (code !== 0) finish(false) }
    }

    function finish(ok) {
        const p = pending
        pending = null
        if (!p) return
        if (ok) {
            const r = rate(p.from, p.to)
            if (r > 0) { UI.flash("\uf51e", Apps.fmtNum(p.amount * r) + " " + p.to, p.from + " → " + p.to, "", "info", ""); return }
        }
        UI.flash("\uf51e", "Курсы недоступны", "нет сети или нужен curl", "", "info", "")
    }

    Process {
        id: saveProc
        command: ["sh", "-c",
            'mkdir -p "$(dirname "$1")"; printf "%s" "$2" > "$1"', "sh",
            root.cacheFile,
            JSON.stringify({ ts: Math.floor(Date.now() / 1000), base: root.base, rates: root.rates })]
    }

    FileView {
        id: cache
        path: root.cacheFile
        onLoaded: {
            try {
                const j = JSON.parse(cache.text())
                if (Date.now() / 1000 - (j.ts || 0) < 86400) {
                    root.base = j.base; root.rates = j.rates; root.ready = true
                }
            } catch (e) {}
        }
    }

    // старт + обновление раз в сутки
    Timer { running: true; interval: 3000; onTriggered: root.load() }
    Timer { interval: 86400000; running: root.ready; repeat: true; onTriggered: root.load() }
}
