pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Показывает уровень громкости/яркости в динамическом острове
Singleton {
    id: root

    property string kind: "volume"          // volume | brightness
    property bool ready: false              // не показывать при старте
    readonly property var sink: Pipewire.defaultAudioSink

    readonly property bool muted: kind !== "brightness" && sink !== null && sink.audio !== null && sink.audio.muted
    readonly property real value: kind === "brightness"
        ? Brightness.value
        : ((sink && sink.audio) ? sink.audio.volume : 0)

    function icon() {
        if (kind === "brightness") return "\uf185"
        if (muted) return "\uf026"
        return value < 0.01 ? "\uf026" : (value < 0.5 ? "\uf027" : "\uf028")
    }

    function show(k) {
        kind = k
        UI.flash(icon(), "", "", "", "level", "", 1400)
    }

    PwObjectTracker { objects: [root.sink] }
    Timer { interval: 2500; running: true; onTriggered: root.ready = true }

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { if (root.ready) root.show("volume") }
        function onMutedChanged()  { if (root.ready) root.show("volume") }
    }
}
