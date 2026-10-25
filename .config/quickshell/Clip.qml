pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// История буфера обмена. Нужны cliphist и wl-clipboard,
// а в hyprland.conf:  exec-once = wl-paste --watch cliphist store
Singleton {
    id: root

    property var items: []              // [{id, text}]

    function reload() { listProc.running = true }

    function search(text) {
        const q = text.trim().toLowerCase()
        const found = items.filter(i => q === "" || i.text.toLowerCase().indexOf(q) >= 0)
        if (items.length === 0)
            return [{ kind: "info", name: "История пуста", glyph: "\uf0ea",
                      comment: "нужен cliphist: wl-paste --watch cliphist store", icon: "" }]
        return found.slice(0, 6).map(i => ({
            kind: "clip", id: i.id, glyph: "\uf0ea", icon: "",
            name: i.text.replace(/\s+/g, " ").slice(0, 90),
            comment: ""
        }))
    }

    function paste(e) {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id])
        UI.flash("\uf0ea", "Скопировано из истории", e.name.slice(0, 40), "", "info", "")
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const t = lines[i].indexOf("\t")
                    if (t <= 0) continue
                    let body = lines[i].slice(t + 1)
                    if (body.indexOf("[[ binary data") === 0) body = "Изображение / бинарные данные"
                    out.push({ id: lines[i].slice(0, t), text: body })
                }
                root.items = out
            }
        }
    }
}
