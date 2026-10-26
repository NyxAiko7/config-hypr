//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // подложка под лаунчер: клик мимо закрывает его
    Variants {
        model: Quickshell.screens
        LauncherScrim {
            required property var modelData
            screen: modelData
        }
    }

    Corners {}      // скруглённые углы экрана (удали строку, чтобы отключить)
    Events {}
    Session {}
    Lock {}
    PasswordPrompt {}
    WallpaperPicker {}

    // quickshell ipc call launcher toggle | clipboard | windows
    IpcHandler {
        target: "launcher"
        function toggle(): void { UI.openLauncher("apps") }
        function clipboard(): void { Clip.reload(); UI.openLauncher("clip") }
        function windows(): void { UI.openLauncher("windows") }
    }
    // quickshell ipc call session toggle
    IpcHandler {
        target: "session"
        function toggle(): void { UI.launcher = false; UI.session = !UI.session }
    }
    // quickshell ipc call wallpaper toggle | random
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { UI.launcher = false; UI.session = false; UI.wallpaper = !UI.wallpaper }
        function random(): void { Wallpapers.refresh(); randomDelay.start() }
    }
    Timer { id: randomDelay; interval: 400; onTriggered: Wallpapers.random() }

    // quickshell ipc call pomodoro toggle | skip
    IpcHandler {
        target: "pomodoro"
        function toggle(): void { if (Pomodoro.running) Pomodoro.stop(); else Pomodoro.start("focus") }
        function skip(): void { if (Pomodoro.running) Pomodoro.skip() }
    }
    // quickshell ipc call notifs toggle | dnd | clear
    IpcHandler {
        target: "notifs"
        function toggle(): void { UI.toggleCenter() }
        function dnd(): void { Notifs.dnd = !Notifs.dnd }
        function clear(): void { Notifs.clearAll() }
    }
    // quickshell ipc call record region | screen | stop
    IpcHandler {
        target: "record"
        function region(): void { Recorder.start(true) }
        function screen(): void { Recorder.start(false) }
        function stop(): void { Recorder.stop() }
    }
    // quickshell ipc call osd brightness | volume  (показывает полосу в острове)
    IpcHandler {
        target: "osd"
        function brightness(): void { Brightness.refresh(); Levels.show("brightness") }
        function volume(): void { Levels.show("volume") }
    }
}
