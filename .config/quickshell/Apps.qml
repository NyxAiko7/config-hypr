pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Поиск приложений для лаунчера в острове. Запоминает, что ты запускаешь чаще.
Singleton {
    id: root

    property var counts: ({})
    readonly property int maxResults: 8      // сколько строк показывать

    function score(e, q) {
        const n = e.name.toLowerCase()
        if (n === q) return 100
        if (n.indexOf(q) === 0) return 80
        if (n.indexOf(q) >= 0) return 60
        const extra = ((e.genericName || "") + " " + (e.keywords ? e.keywords.join(" ") : "") + " " + (e.comment || "")).toLowerCase()
        if (extra.indexOf(q) >= 0) return 30
        // подпоследовательность: «fire» → «Firefox»
        let i = 0
        for (let k = 0; k < n.length && i < q.length; k++)
            if (n[k] === q[i]) i++
        if (i === q.length) return 15
        // опечатки: не больше двух лишних символов в имени
        if (q.length >= 3 && editDistance(n, q) <= 2) return 10
        return 0
    }

    // расстояние Левенштейна (с «полосой» шириной 3 — быстрее и нам хватает точности)
    function editDistance(a, b) {
        const la = a.length, lb = b.length
        if (Math.abs(la - lb) > 2) return 99
        let prev = new Array(lb + 1)
        let cur = new Array(lb + 1)
        for (let j = 0; j <= lb; j++) prev[j] = j
        for (let i = 1; i <= la; i++) {
            cur[0] = i
            let rowMin = cur[0]
            for (let j = 1; j <= lb; j++) {
                const cost = a[i - 1] === b[j - 1] ? 0 : 1
                cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
                if (cur[j] < rowMin) rowMin = cur[j]
            }
            if (rowMin > 2) return 99
            const t = prev; prev = cur; cur = t
        }
        return prev[lb]
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

    // особые строки поиска: «? запрос» — веб, «> команда» — запуск, «# текст» — заметка,
    // «ws3 / ws+1» — рабочий стол, курсы валют, калькулятор
    function special(raw) {
        const t = raw.trim()
        if (t === "") return null
        if (t[0] === "?" && t.slice(1).trim() !== "")
            return { kind: "web", icon: "", glyph: "\uf0ac", name: I18n.t("Искать: ") + t.slice(1).trim(),
                     comment: I18n.t("в браузере"), value: Config.searchUrl + encodeURIComponent(t.slice(1).trim()) }
        if (t[0] === ">" && t.slice(1).trim() !== "")
            return { kind: "run", icon: "", glyph: "\uf120", name: I18n.t("Выполнить: ") + t.slice(1).trim(),
                     comment: I18n.t("в оболочке"), value: t.slice(1).trim() }
        if (t[0] === "#" && t.slice(1).trim() !== "")
            return { kind: "note", icon: "", glyph: "\uf044", name: I18n.t("Заметка: ") + t.slice(1).trim(),
                     comment: I18n.t("сохранить в ") + Notes.file, value: t.slice(1).trim() }

        const ws = workspaceEntry(t)
        if (ws) return ws

        const fx = parseMoney(t)
        if (fx) {
            const r = Rates.rate(fx.from, fx.to)
            if (r > 0)
                return { kind: "calc", icon: "", glyph: "\uf51e",
                         name: fmtNum(fx.amount * r) + " " + fx.to,
                         comment: fx.amount + " " + fx.from + " → " + fx.to + I18n.t(" · копировать"),
                         value: fmtNum(fx.amount * r) }
            return { kind: "fetch", icon: "", glyph: "\uf51e",
                     name: fx.amount + " " + fx.from + " → " + fx.to,
                     comment: I18n.t("нет курса — Enter обновит"), from: fx.from, to: fx.to, amount: fx.amount }
        }

        if (/^[0-9+\-*\/().,%^ ]+$/.test(t) && /[0-9]/.test(t) && /[+*\/%^()]|.-/.test(t)) {
            try {
                const v = calc(t)
                if (isFinite(v)) return { kind: "calc", icon: "", glyph: "\uf1ec", name: "= " + fmtNum(v),
                                          comment: t + I18n.t("  ·  копировать"), value: fmtNum(v) }
            } catch (e) {}
        }
        return null
    }

    // ── рабочие столы прямо из лаунчера: «ws3», «ws+1», «ws-2» ──
    readonly property var wsRe: /^ws\s*([+-]?)\s*([0-9]{1,2})$/i

    function workspaceEntry(raw) {
        const m = wsRe.exec(raw.trim())
        if (!m) return null
        const rel = m[1] !== ""
        const n = parseInt(m[2])
        if (rel)
            return { kind: "ws", icon: "", glyph: "\uf108",
                     name: I18n.t("Рабочий стол ") + (m[1] === "-" ? "−" : "+") + n,
                     comment: I18n.t("сдвинуться на текущем мониторе"), delta: m[1] === "-" ? -n : n, relative: true }
        if (n < 1 || n > 20) return null
        return { kind: "ws", icon: "", glyph: "\uf108", name: I18n.t("Рабочий стол ") + n,
                 comment: I18n.t("перейти"), target: n, relative: false }
    }

    function goWorkspace(e) {
        const fm = Hyprland.focusedMonitor
        const cur = fm ? fm.activeWorkspace.id : 1
        const target = e.relative ? cur + e.delta : e.target
        if (target < 1) return
        Hyprland.dispatch("workspace " + target)
    }

    // ── конвертация валют: «100 usd in rub», «$50 → евро», «300р in usd» ──
    readonly property var aliases: ({
        rub: "RUB", руб: "RUB", р: "RUB",
        usd: "USD", бакс: "USD", dollar: "USD",
        eur: "EUR", евро: "EUR", euro: "EUR",
        uah: "UAH", грн: "UAH",
        byn: "BYN", KZT: "KZT", тенге: "KZT",
        GBP: "GBP", фунт: "GBP", CNY: "CNY", юань: "CNY", JPY: "JPY", иена: "JPY"
    })
    readonly property var symMap: ({ "$": "USD", "€": "EUR", "£": "GBP", "¥": "JPY" })
    readonly property var moneyRe: /^(?:([$€£¥])\s*)?([0-9]+(?:[.,][0-9]+)?)\s*([A-Za-zА-Яа-я]{1,4})?\s*(?:to|в|in|->|→|=)?\s*(?:([$€£¥])\s*)?([A-Za-zА-Яа-я]{1,4})?$/

    function normCur(s) {
        if (!s) return ""
        return aliases[s] || aliases[s.toLowerCase()] || s.toUpperCase()
    }

    function parseMoney(t) {
        const m = moneyRe.exec(t)
        if (!m) return null
        const amount = parseFloat(String(m[2]).replace(",", "."))
        let from = normCur(m[3])
        const to = normCur(m[5])
        if (!from && (m[1] || m[4])) from = symMap[m[1] || m[4]] || ""
        if (!isFinite(amount) || amount <= 0) return null
        if (from === "" || to === "" || from === to) return null
        return { amount: amount, from: from, to: to }
    }

    function rate(a, b) { return Rates.rate(a, b) }

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
        const extras = []
        if (sp) extras.push(sp)
        if (q.length >= 2)
            for (let i = 0; i < Notes.items.length && extras.length < 3; i++) {
                const line = String(Notes.items[i])
                if (line.toLowerCase().indexOf(q) >= 0)
                    extras.push({ kind: "openNote", icon: "", glyph: "\uf044",
                                  name: line.replace(/^- /, ""), comment: I18n.t("заметка · Enter — открыть файл") })
            }
        const res = list.slice(0, maxResults).map(x => x.e)
        const room = Math.max(0, maxResults - extras.length)
        return extras.concat(res.slice(0, room))
    }

    function launch(e) {
        if (e.kind === "calc") {
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", e.value])
            UI.flash("\uf1ec", I18n.t("Скопировано"), e.name, "", "info", "")
            return
        }
        if (e.kind === "fetch") { Rates.fetchOne(e.from, e.to, e.amount); return }
        if (e.kind === "ws") { Apps.goWorkspace(e); UI.launcher = false; return }
        if (e.kind === "note") {
            Notes.add(e.value)
            UI.flash("\uf044", I18n.t("Заметка сохранена"), e.value.slice(0, 40), "", "info", "")
            return
        }
        if (e.kind === "openNote") { UI.launcher = false; Notes.open(); return }
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
