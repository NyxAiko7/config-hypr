pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// Список открытых окон для переключателя в острове
Singleton {
    function search(text) {
        const q = text.trim().toLowerCase()
        const list = ToplevelManager.toplevels.values
        const out = []
        for (let i = 0; i < list.length; i++) {
            const t = list[i]
            const title = t.title || t.appId || "Окно"
            if (q !== "" && title.toLowerCase().indexOf(q) < 0 && String(t.appId).toLowerCase().indexOf(q) < 0) continue
            let icon = ""
            try {
                const e = DesktopEntries.byId(t.appId) || DesktopEntries.heuristicLookup(t.appId)
                if (e) icon = e.icon
            } catch (err) {}
            out.push({ kind: "window", tl: t, name: title, comment: String(t.appId || ""), icon: icon, glyph: "\uf2d0", active: t.activated })
        }
        out.sort((a, b) => (b.active - a.active))
        return out.slice(0, 6)
    }

    function focus(e) { e.tl.activate() }
    function close(e) { e.tl.close() }
}
