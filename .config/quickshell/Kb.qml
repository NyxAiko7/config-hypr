pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string layout: "EN"

    function abbrev(name) {
        const s = String(name).toLowerCase()
        if (s.indexOf("russian") >= 0) return "RU"
        if (s.indexOf("english") >= 0) return "EN"
        if (s.indexOf("ukrain") >= 0) return "UA"
        if (s.indexOf("german") >= 0) return "DE"
        return String(name).substring(0, 2).toUpperCase()
    }
    function next() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    // начальное значение
    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    const kb = j.keyboards.find(k => k.main) || j.keyboards[0]
                    if (kb) root.layout = root.abbrev(kb.active_keymap)
                } catch (e) {}
            }
        }
    }

    // смена раскладки на лету
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "activelayout") {
                const p = ev.data.split(",")
                root.layout = root.abbrev(p.slice(1).join(","))
            }
        }
    }
}
