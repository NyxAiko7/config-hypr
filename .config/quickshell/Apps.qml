pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Поиск приложений для лаунчера в острове. Запоминает, что ты запускаешь чаще.
Singleton {
    id: root

    property var counts: ({})

    function score(e, q) {
        const n = e.name.toLowerCase()
        if (n === q) return 100
        if (n.indexOf(q) === 0) return 80
        if (n.indexOf(q) >= 0) return 60
        const extra = ((e.genericName || "") + " " + (e.keywords ? e.keywords.join(" ") : "") + " " + (e.comment || "")).toLowerCase()
        if (extra.indexOf(q) >= 0) return 30
        let i = 0
        for (let k = 0; k < n.length && i < q.length; k++)
            if (n[k] === q[i]) i++
        return i === q.length ? 15 : 0
    }

    // безопасный вычислитель выражений: + - * / % ^ и скобки
    function calc(src) {
        const s = src.replace(/,/g, ".").replace(/\s+/g, "")
        let i = 0
        function peek() { return s[i] }
        function num() {
            const m = /^(\d+\.?\d*|\.\d+)/.exec(s.slice(i))
            if (!m) throw "num"
            i += m[0].length
            return parseFloat(m[0])
        }
        function atom() {
            if (peek() === "(") { i++; const v = expr(); if (peek() !== ")") throw "paren"; i++; return v }
            if (peek() === "-") { i++; return -atom() }
            if (peek() === "+") { i++; return atom() }
            return num()
        }
        function pow() { let v = atom(); while (peek() === "^") { i++; v = Math.pow(v, atom()) } return v }
        function term() {
            let v = pow()
            while (peek() === "*" || peek() === "/" || peek() === "%") {
                const o = s[i++]; const r = pow()
                v = o === "*" ? v * r : (o === "/" ? v / r : v % r)
            }
            return v
        }
        function expr() {
            let v = term()
            while (peek() === "+" || peek() === "-") {
                const o = s[i++]; const r = term()
                v = o === "+" ? v + r : v - r
            }
            return v
        }
        const v = expr()
        if (i !== s.length) throw "tail"
        return v
    }

    function fmtNum(v) {
        const r = Math.round(v * 1e8) / 1e8
        return String(r)
    }

    // особые строки поиска: калькулятор, «? запрос» — веб, «> команда» — запуск
    function special(raw) {
        const t = raw.trim()
        if (t === "") return null
        if (t[0] === "?" && t.slice(1).trim() !== "")
            return { kind: "web", icon: "", glyph: "\uf0ac", name: "Искать: " + t.slice(1).trim(),
                     comment: "в браузере", value: Config.searchUrl + encodeURIComponent(t.slice(1).trim()) }
        if (t[0] === ">" && t.slice(1).trim() !== "")
            return { kind: "run", icon: "", glyph: "\uf120", name: "Выполнить: " + t.slice(1).trim(),
                     comment: "в оболочке", value: t.slice(1).trim() }
        if (/^[0-9+\-*\/().,%^ ]+$/.test(t) && /[0-9]/.test(t) && /[+*\/%^()]|.-/.test(t)) {
            try {
                const v = calc(t)
                if (isFinite(v)) return { kind: "calc", icon: "", glyph: "\uf1ec", name: "= " + fmtNum(v),
                                          comment: t + "  ·  копировать", value: fmtNum(v) }
            } catch (e) {}
        }
        return null
    }

    function search(text) {
        const sp = special(text)
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        const q = text.trim().toLowerCase()
        let list
        if (q === "") {
            // пусто: сначала частые, затем по алфавиту
            list = apps.map(e => ({ e: e, s: counts[e.id] || 0 }))
                       .sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name))
        } else {
            list = apps.map(e => ({ e: e, s: score(e, q) }))
                       .filter(x => x.s > 0)
                       .map(x => ({ e: x.e, s: x.s + Math.min(counts[x.e.id] || 0, 20) }))
                       .sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name))
        }
        const res = list.slice(0, 6).map(x => x.e)
        return sp ? [sp].concat(res.slice(0, 5)) : res
    }

    function launch(e) {
        if (e.kind === "calc") {
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", e.value])
            UI.flash("\uf1ec", "Скопировано", e.name, "", "info", "")
            return
        }
        if (e.kind === "web") { Quickshell.execDetached(["xdg-open", e.value]); return }
        if (e.kind === "run") { Quickshell.execDetached(["sh", "-c", e.value]); return }
        if (e.kind === "info") return
        const c = Object.assign({}, counts)
        c[e.id] = (c[e.id] || 0) + 1
        counts = c
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.local/state/quickshell" && printf "%s" "$1" > "$HOME/.local/state/quickshell/launch-counts.json"',
            "sh", JSON.stringify(c)])
        e.execute()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/launch-counts.json"
        onLoaded: { try { root.counts = JSON.parse(file.text()) } catch (e) {} }
    }
}
