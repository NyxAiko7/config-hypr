pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// Список открытых окон для переключателя в острове.
// В mode «windows» лаунчер ищет по названию/приложению; если запрос — это число,
// окна того рабочего стола поднимаются наверх (в подписи виден номер стола).
Singleton {
    id: root

    readonly property int maxResults: 8

    function wsOf(t) {
        try { return t.workspace ? t.workspace.id : -1 } catch (e) { return -1 }
    }

    function search(text) {
        const raw = text.trim()
        const q = raw.toLowerCase()
        const numOnly = /^[0-9]{1,2}$/.test(raw) ? parseInt(raw) : -1
        const list = ToplevelManager.toplevels.values
        const out = []
        for (let i = 0; i < list.length; i++) {
            const t = list[i]
            const title = t.title || t.appId || "Окно"
            const ws = wsOf(t)
            const boost = (numOnly > 0 && ws === numOnly) ? 50 : 0     // окна нужного стола — выше
            if (q !== "" && boost === 0
                && title.toLowerCase().indexOf(q) < 0
                && String(t.appId).toLowerCase().indexOf(q) < 0) continue
            let icon = ""
            try {
                const e = DesktopEntries.byId(t.appId) || DesktopEntries.heuristicLookup(t.appId)
                if (e) icon = e.icon
            } catch (err) {}
            out.push({ kind: "window", tl: t, name: title,
                       comment: String(t.appId || "") + (ws > 0 ? " · ws" + ws : ""),
                       icon: icon, glyph: "\uf2d0", active: t.activated, s: boost })
        }
        out.sort((a, b) => (b.s - a.s) || (b.active - a.active))
        return out.slice(0, maxResults)
    }

    function focus(e) { e.tl.activate() }
    function close(e) { e.tl.close() }
}
