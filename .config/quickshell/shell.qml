//@ pragma UseQApplication
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

    Corners {}      // скруглённые углы экрана (удали строку, чтобы отключить)
    Launcher {}
    Session {}
    Osd {}

    // quickshell ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { UI.session = false; UI.launcher = !UI.launcher }
    }
    // quickshell ipc call session toggle
    IpcHandler {
        target: "session"
        function toggle(): void { UI.launcher = false; UI.session = !UI.session }
    }
    // quickshell ipc call osd brightness
    IpcHandler {
        target: "osd"
        function brightness(): void { Brightness.refresh(); UI.showOsd("brightness") }
        function volume(): void { UI.showOsd("volume") }
    }
}
