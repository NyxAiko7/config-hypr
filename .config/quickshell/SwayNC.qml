pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Мост к SwayNC: счётчик, DND и открытие панели
Singleton {
    id: root

    property int count: 0
    property bool dnd: false

    function toggle()    { Quickshell.execDetached(["swaync-client", "-t", "-sw"]) }
    function toggleDnd() { Quickshell.execDetached(["swaync-client", "-d", "-sw"]) }
    function clear()     { Quickshell.execDetached(["swaync-client", "-C", "-sw"]) }

    Process {
        id: sub
        command: ["swaync-client", "-swb"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line)
                    root.count = parseInt(j.text) || 0
                    root.dnd = String(j.alt).indexOf("dnd") >= 0
                } catch (e) {}
            }
        }
        // если swaync ещё не запущен — пробуем снова
        onExited: retry.start()
    }
    Timer { id: retry; interval: 3000; onTriggered: sub.running = true }
}
