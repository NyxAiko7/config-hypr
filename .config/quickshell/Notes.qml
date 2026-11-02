pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Быстрые заметки из лаунчера: «# не забыть купить кофе».
// Хранятся в ~/.local/state/quickshell/notes.md — обычный текст,
// его можно синхронизировать git'ом или открыть любым редактором.
Singleton {
    id: root

    readonly property string file: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/notes.md"
    property var items: []                 // последние строки сверху

    function add(text) {
        writeProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$1")"; [ -f "$1" ] || printf "# Заметки\\n" > "$1"; ' +
            'printf "\\n- %s  ·  %s\\n" "$(date "+%F %H:%M")" "$2" >> "$1"', "sh", file, text]
        writeProc.running = true
    }

    function open() { Quickshell.execDetached(["xdg-open", file]) }
    function reload() { notesFile.reload() }

    Process { id: writeProc }

    FileView {
        id: notesFile
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: root.items = []
        onLoaded: {
            const lines = notesFile.text().split("\n").filter(l => l.indexOf("- ") === 0)
            root.items = lines.slice(-300).reverse()
        }
    }
}
