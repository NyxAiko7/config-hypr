import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Живая плашка в центре острова: круглая обложка с кольцом прогресса и время трека.
// При наведении выезжает название.
Pill {
    id: chip

    signal openRequested()

    readonly property var p: Media.player
    readonly property bool playing: p !== null && p.playbackState === MprisPlaybackState.Playing
    readonly property real ratio: (p && p.length > 0) ? Math.max(0, Math.min(1, p.position / p.length)) : 0

    interactive: true
    visible: p !== null

    function fmt(s) {
        if (!isFinite(s) || s < 0) return "0:00"
        return Math.floor(s / 60) + ":" + ("0" + Math.floor(s % 60)).slice(-2)
    }

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) { if (p && p.canTogglePlaying) p.togglePlaying() }
        else if (mouse.button === Qt.RightButton) { if (p && p.canGoNext) p.next() }
        else openRequested()
    }

    Timer {
        running: chip.visible && chip.playing
        interval: 1000
        repeat: true
        onTriggered: chip.p.positionChanged()
    }

    // обложка в кольце прогресса
    Item {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28

        Canvas {
            id: ring
            anchors.fill: parent
            readonly property real prog: chip.ratio
            onProgChanged: requestPaint()
            Connections {
                target: Theme
                function onAccentChanged() { ring.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const c = width / 2, rad = c - 1.5
                ctx.lineWidth = 2
                ctx.strokeStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16)
                ctx.beginPath()
                ctx.arc(c, c, rad, 0, Math.PI * 2)
                ctx.stroke()
                if (prog > 0.001) {
                    ctx.strokeStyle = Theme.accent
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.arc(c, c, rad, -Math.PI / 2, -Math.PI / 2 + prog * Math.PI * 2)
                    ctx.stroke()
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: 20
            height: 20
            opacity: chip.playing ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle { anchors.fill: parent; color: Theme.surface }
            Image {
                id: cover
                anchors.fill: parent
                source: chip.p ? chip.p.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Lbl {
                anchors.centerIn: parent
                visible: !cover.visible
                text: "\uf001"
                color: Theme.muted
                font.pixelSize: 9
            }
            RoundMask { anchors.fill: parent; radius: 10; maskColor: Theme.bg }
        }
    }

    // сколько играет трек
    Lbl {
        text: chip.fmt(chip.p ? chip.p.position : 0)
        font.pixelSize: 11
        font.bold: true
        color: chip.playing ? Theme.text : Theme.muted
    }

    // название выезжает при наведении
    Lbl {
        id: titleLbl
        opacity: chip.hovered ? 1 : 0
        visible: opacity > 0.01
        Layout.preferredWidth: chip.hovered ? Math.min(implicitWidth, 200) : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        elide: Text.ElideRight
        clip: true
        color: Theme.muted
        font.pixelSize: 11
        text: chip.p
            ? (chip.p.trackArtist ? chip.p.trackArtist + " – " : "") + (chip.p.trackTitle || "")
            : ""
    }
}
