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
                ctx.strokeStyle = Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.18)
                ctx.beginPath()
                ctx.arc(c, c, rad, 0, Math.PI * 2)
                ctx.stroke()
                if (Rock.marisa) {
                    ctx.fillStyle = Rock.a(Rock.gold, 0.7)
                    for (let i = 0; i < 8; i++) {
                        const a = i * Math.PI / 4
                        ctx.beginPath()
                        ctx.arc(c + Math.cos(a) * rad, c + Math.sin(a) * rad, 0.9, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
                if (prog > 0.001) {
                    ctx.strokeStyle = Rock.marisa ? Rock.gold : Rock.yellow
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    ctx.arc(c, c, rad, -Math.PI / 2, -Math.PI / 2 + prog * Math.PI * 2)
                    ctx.stroke()
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: Rock.marisa

            NumberAnimation on rotation {
                running: chip.visible && chip.playing
                from: 0
                to: 360
                duration: 14000
                loops: Animation.Infinite
            }

            Repeater {
                model: 4
                delegate: Text {
                    required property int index
                    readonly property real ang: index * Math.PI / 2 - Math.PI / 4
                    text: index % 2 === 0 ? "✦" : "✧"
                    color: index % 2 === 0 ? Rock.gold : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
                    font.pixelSize: index % 2 === 0 ? 6 : 5
                    x: parent.width / 2 + Math.cos(ang) * (parent.width / 2 - 2) - width / 2
                    y: parent.height / 2 + Math.sin(ang) * (parent.height / 2 - 2) - height / 2
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: 20
            height: 20
            opacity: chip.playing ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle { anchors.fill: parent; color: Rock.comic ? Rock.paper : Rock.uiSurface2 }
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
                color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
                font.pixelSize: 9
            }
            RoundMask { anchors.fill: parent; radius: 10; maskColor: Rock.marisa ? Rock.uiSurface : Rock.ink2 }
        }
    }

    // сколько играет трек
    Lbl {
        text: Fmt.clock(chip.p ? chip.p.position : 0)
        font.pixelSize: 11
        font.bold: true
        color: chip.playing ? (Rock.marisa ? Rock.barText : Rock.cream) : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.5)
    }

    // название выезжает при наведении
    Lbl {
        id: titleLbl
        opacity: ((chip.playing || chip.hovered) && !PanelConfig.vertical) ? 1 : 0
        visible: opacity > 0.01
        Layout.preferredWidth: (chip.playing || chip.hovered) ? Math.min(implicitWidth, chip.playing ? 160 : 200) : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        elide: Text.ElideRight
        clip: true
        color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.6)
        font.pixelSize: 11
        text: chip.p
            ? (chip.p.trackArtist ? chip.p.trackArtist + " – " : "") + (chip.p.trackTitle || "")
            : ""
    }
}
