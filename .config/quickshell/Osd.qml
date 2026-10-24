import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: osd

    property var sink: Pipewire.defaultAudioSink
    property bool ready: false          // не показывать при старте

    readonly property bool isBrightness: UI.osdKind === "brightness"
    readonly property bool muted: !isBrightness && sink && sink.audio && sink.audio.muted
    readonly property real value: isBrightness
        ? Brightness.value
        : ((sink && sink.audio) ? sink.audio.volume : 0)

    visible: card.opacity > 0.01 || UI.osdVisible
    anchors { bottom: true }
    margins { bottom: 72 }
    implicitWidth: 280
    implicitHeight: 52
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"
    color: "transparent"
    mask: Region {}                      // клики проходят сквозь

    PwObjectTracker { objects: [osd.sink] }
    Timer { interval: 2500; running: true; onTriggered: osd.ready = true }

    Connections {
        target: osd.sink ? osd.sink.audio : null
        function onVolumeChanged() { if (osd.ready) UI.showOsd("volume") }
        function onMutedChanged()  { if (osd.ready) UI.showOsd("volume") }
    }

    function icon() {
        if (isBrightness) return "\uf185"
        if (muted) return "\uf026"
        return value < 0.01 ? "\uf026" : (value < 0.5 ? "\uf027" : "\uf028")
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 26
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.hairline
        opacity: UI.osdVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 14

            Lbl {
                text: osd.icon()
                color: osd.muted ? Theme.muted : Theme.accent
                font.pixelSize: 16
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                Layout.fillWidth: true
                height: 4; radius: 2
                color: Theme.surface
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, osd.muted ? 0 : osd.value))
                    height: parent.height; radius: 2
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }
            Lbl {
                text: osd.muted ? "–" : Math.round(osd.value * 100)
                color: Theme.muted
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
