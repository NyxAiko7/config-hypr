pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Запись экрана через wf-recorder (нужны wf-recorder и slurp)
Singleton {
    id: root

    property bool recording: false
    property int seconds: 0

    function text() {
        const m = Math.floor(seconds / 60), s = seconds % 60
        return ("0" + m).slice(-2) + ":" + ("0" + s).slice(-2)
    }

    function start(region) {
        if (recProc.running) return
        const script =
            'mkdir -p "$HOME/Videos/Recordings"; ' +
            'f="$HOME/Videos/Recordings/$(date +%F_%H-%M-%S).mp4"; ' +
            (region ? 'g=$(slurp) || exit 0; exec wf-recorder -g "$g" -f "$f"' : 'exec wf-recorder -f "$f"')
        recProc.command = ["sh", "-c", script]
        recProc.running = true
    }

    function stop() { Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]) }
    function toggle(region) { if (recording) stop(); else start(region) }

    Process {
        id: recProc
        onStarted: confirm.start()
        onExited: {
            confirm.stop()
            tick.stop()
            if (root.recording) {
                root.recording = false
                Quickshell.execDetached(["notify-send", "-a", "Запись экрана",
                    "Запись сохранена", "Папка ~/Videos/Recordings"])
            }
        }
    }
    // если slurp отменили, процесс завершится сразу — тогда «запись» не объявляем
    Timer {
        id: confirm
        interval: 1200
        onTriggered: {
            if (!recProc.running) return
            root.recording = true
            root.seconds = 0
            tick.start()
            UI.flash("\uf03d", "Запись экрана", "Клик по значку слева — остановить", "", "rec", "")
        }
    }
    Timer { id: tick; interval: 1000; repeat: true; onTriggered: root.seconds++ }
}
