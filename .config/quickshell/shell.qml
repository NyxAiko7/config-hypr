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
    Widgets {}
    Events {}
    Session {}
    Lock {}
    PasswordPrompt {}
    WallpaperPicker {}
    SettingsPanel {}

    // quickshell ipc call launcher toggle | clipboard | windows
    IpcHandler {
        target: "launcher"
        function toggle() { UI.openLauncher("apps") }
        function clipboard() { Clip.reload(); UI.openLauncher("clip") }
        function windows() { UI.openLauncher("windows") }
    }
    // quickshell ipc call session toggle
    IpcHandler {
        target: "session"
        function toggle() { UI.launcher = false; UI.session = !UI.session }
    }
    // quickshell ipc call wallpaper toggle | random
    IpcHandler {
        target: "wallpaper"
        function toggle() { UI.launcher = false; UI.session = false; UI.settings = false; UI.wallpaper = !UI.wallpaper }
        function random() { Wallpapers.refresh(); randomDelay.start() }
    }
    // quickshell ipc call settings toggle
    IpcHandler {
        target: "settings"
        function toggle() {
            UI.launcher = false
            UI.session = false
            UI.wallpaper = false
            UI.settings = !UI.settings
        }
        function lang(l: string) { PanelConfig.setLanguage(l) }
    }
    Timer { id: randomDelay; interval: 400; onTriggered: Wallpapers.random() }

    // quickshell ipc call pomodoro toggle | skip
    IpcHandler {
        target: "pomodoro"
        function toggle() { if (Pomodoro.running) Pomodoro.stop(); else Pomodoro.start("focus") }
        function skip() { if (Pomodoro.running) Pomodoro.skip() }
    }
    // quickshell ipc call notifs toggle | dnd | clear
    IpcHandler {
        target: "notifs"
        function toggle() { UI.toggleCenter() }
        function dnd() { Notifs.dnd = !Notifs.dnd }
        function clear() { Notifs.clearAll() }
    }
    // quickshell ipc call record region | screen | stop
    IpcHandler {
        target: "record"
        function region() { Recorder.start(true) }
        function screen() { Recorder.start(false) }
        function stop() { Recorder.stop() }
    }
    // quickshell ipc call osd brightness | volume  (показывает полосу в острове)
    IpcHandler {
        target: "osd"
        function brightness() { Brightness.refresh(); Levels.show("brightness") }
        function volume() { Levels.show("volume") }
    }
    // quickshell ipc call help toggle  (попап «Горячие клавиши»)
    IpcHandler {
        target: "help"
        function toggle() { UI.toggleHelp() }
    }
    IpcHandler {
        target: "widgets"
        function toggle() { PanelConfig.setWidgets(!PanelConfig.widgetsEnabled) }
        function clock() { PanelConfig.setWidget("widgetClock", !PanelConfig.widgetClock) }
        function player() { PanelConfig.setWidget("widgetPlayer", !PanelConfig.widgetPlayer) }
    }
}
