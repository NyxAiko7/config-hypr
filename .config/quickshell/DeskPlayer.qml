import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Item {
    id: card

    readonly property int pad: 18
    readonly property int cut: 18
    readonly property var p: Media.player
    readonly property bool hasPlayer: p !== null && p !== undefined
    readonly property bool playing: hasPlayer && p.playbackState === MprisPlaybackState.Playing
    readonly property real ratio: (hasPlayer && p.length > 0)
        ? Math.max(0, Math.min(1, p.position / p.length)) : 0
    readonly property string artUrl: hasPlayer ? String(p.trackArtUrl || "") : ""

    implicitWidth: 448
    implicitHeight: 196

    Timer {
        running: card.visible && card.playing
        interval: 500
        repeat: true
        onTriggered: if (card.hasPlayer) card.p.positionChanged()
    }

    Timer {
        interval: 16
        running: card.visible && card.playing
        repeat: true
        onTriggered: spinner.rotation = (spinner.rotation + 0.7) % 360
    }

    WheelHandler {
        function handleWheel(w) {
            const dy = w.angleDelta.y
            if (card.p && card.p.volumeSupported && dy !== 0) {
                w.accepted = true
                Media.setVol(card.p.volume + (dy > 0 ? 0.03 : -0.03))
            }
        }
        onWheel: handleWheel(wheel)
    }

    Canvas {
        id: frame
        anchors.fill: parent

        property color topColor: Theme.islandTop
        property color bottomColor: Theme.islandBottom
        property color edge: Rock.a(Rock.cream, 0.12)
        property color accent: Rock.pink
        property color accent2: Rock.cyan
        property color fg: Rock.cream
        property int cut: card.cut

        onTopColorChanged: requestPaint()
        onBottomColorChanged: requestPaint()
        onEdgeChanged: requestPaint()
        onAccentChanged: requestPaint()
        onAccent2Changed: requestPaint()
        onFgChanged: requestPaint()
        onCutChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height, c = cut

            const g = ctx.createLinearGradient(0, 0, 0, h)
            g.addColorStop(0, topColor)
            g.addColorStop(1, bottomColor)
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.moveTo(c, 0)
            ctx.lineTo(w, 0)
            ctx.lineTo(w, h - c)
            ctx.lineTo(w - c, h)
            ctx.lineTo(0, h)
            ctx.lineTo(0, c)
            ctx.closePath()
            ctx.fill()

            const rg = ctx.createRadialGradient(card.pad + 64, h / 2, 4, card.pad + 64, h / 2, 120)
            rg.addColorStop(0, Qt.rgba(accent.r, accent.g, accent.b, 0.10))
            rg.addColorStop(1, Qt.rgba(accent.r, accent.g, accent.b, 0))
            ctx.fillStyle = rg
            ctx.fill()

            ctx.strokeStyle = edge
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(c, 0)
            ctx.lineTo(w, 0)
            ctx.lineTo(w, h - c)
            ctx.lineTo(w - c, h)
            ctx.lineTo(0, h)
            ctx.lineTo(0, c)
            ctx.closePath()
            ctx.stroke()

            ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.60)
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(0, c)
            ctx.lineTo(c, 0)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(w, h - c)
            ctx.lineTo(w - c, h)
            ctx.stroke()

            ctx.strokeStyle = Qt.rgba(accent2.r, accent2.g, accent2.b, 0.35)
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(0, c + 14)
            ctx.lineTo(0, c + 42)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(w, h - c - 42)
            ctx.lineTo(w, h - c - 14)
            ctx.stroke()

            for (let x = c + 54; x < w - 54; x += 10) {
                ctx.fillStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.16)
                ctx.fillRect(x, 0.5, 5, 1)
            }

            for (let i = 0; i < 7; i++) {
                const bh = 3 + ((i * 7) % 9)
                ctx.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.28)
                ctx.fillRect(20 + i * 3, h - 8 - bh, 1.4, bh)
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: 16

        Item {
            id: vinylBox
            Layout.preferredWidth: 128
            Layout.preferredHeight: 128
            Layout.alignment: Qt.AlignVCenter

            Item {
                id: spinner
                anchors.fill: parent

                Canvas {
                    id: vinyl
                    anchors.fill: parent

                    property color base: Rock.ink
                    property color fg: Rock.cream
                    property color accent: Rock.pink

                    onBaseChanged: requestPaint()
                    onFgChanged: requestPaint()
                    onAccentChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const w = width, h = height
                        const cx = w / 2, cy = h / 2
                        const R = Math.min(w, h) / 2 - 1

                        ctx.fillStyle = base
                        ctx.beginPath()
                        ctx.arc(cx, cy, R, 0, Math.PI * 2)
                        ctx.fill()

                        for (let r = R * 0.42; r < R - 4; r += 3) {
                            ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, (r % 6 < 3) ? 0.035 : 0.065)
                            ctx.lineWidth = 1
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.stroke()
                        }

                        ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.16)
                        ctx.lineWidth = 1.5
                        ctx.beginPath()
                        ctx.arc(cx, cy, R - 0.5, 0, Math.PI * 2)
                        ctx.stroke()

                        ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.35)
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.arc(cx, cy, R * 0.72, -0.9, -0.2)
                        ctx.stroke()

                        ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.10)
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.arc(cx, cy, R * 0.36, 0, Math.PI * 2)
                        ctx.stroke()
                    }
                }

                Item {
                    id: coverBox
                    width: 66
                    height: 66
                    anchors.centerIn: parent

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Rock.a(Rock.cream, 0.07)
                    }

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: card.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Lbl {
                        anchors.centerIn: parent
                        visible: cover.status !== Image.Ready
                        text: "\uf001"
                        color: Rock.a(Rock.cream, 0.45)
                        font.pixelSize: 20
                    }

                    RoundMask {
                        anchors.fill: parent
                        radius: width / 2
                        maskColor: Rock.ink
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 9
                height: 9
                radius: 4.5
                color: Rock.ink
                border.width: 1
                border.color: Rock.a(Rock.cream, 0.30)
            }

            Item {
                id: arm
                x: vinylBox.width - 24
                y: 10
                width: 3
                height: 70
                rotation: card.playing ? -6 : 18
                transformOrigin: Item.TopLeft
                Behavior on rotation { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: 1.5
                    color: Rock.a(Rock.cream, 0.72)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 10
                    height: 14
                    radius: 2
                    color: Rock.a(Rock.cream, 0.80)
                    border.width: 1
                    border.color: Rock.a(Rock.ink, 0.50)
                }
            }

            Rectangle {
                x: vinylBox.width - 30
                y: 4
                width: 12
                height: 12
                radius: 6
                color: Rock.ink
                border.width: 2
                border.color: Rock.a(Rock.cream, 0.65)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (card.p && card.p.canTogglePlaying) card.p.togglePlaying()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 5
                    height: 5
                    radius: 2.5
                    color: card.playing ? Rock.warn : Rock.a(Rock.cream, 0.25)

                    SequentialAnimation on opacity {
                        running: card.playing
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.20; duration: 700 }
                        NumberAnimation { to: 1.00; duration: 700 }
                    }
                }

                Lbl {
                    text: !card.hasPlayer ? "NO SIGNAL" : (card.playing ? "ON AIR" : "STANDBY")
                    color: card.playing ? Rock.warn : Rock.a(Rock.cream, 0.45)
                    font.pixelSize: 8
                    font.weight: Font.Black
                    font.letterSpacing: 1.5
                }

                Item { Layout.fillWidth: true }

                Lbl {
                    Layout.alignment: Qt.AlignVCenter
                    text: "SIDE A" + (card.hasPlayer && card.p.volumeSupported
                        ? " · " + Math.round(card.p.volume * 100) + "%" : "")
                    color: Rock.a(Rock.cream, 0.35)
                    font.pixelSize: 8
                    font.letterSpacing: 1.0
                }
            }

            Lbl {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: card.hasPlayer
                    ? (card.p.trackTitle || I18n.t("Без названия"))
                    : I18n.t("Нет активного плеера")
                color: Rock.cream
                font.family: Rock.display
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Lbl {
                Layout.fillWidth: true
                text: card.hasPlayer ? String(card.p.trackArtist || "") : "MPRIS · OFFLINE"
                color: Rock.a(Rock.cream, 0.55)
                font.pixelSize: 10
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                Layout.topMargin: 2

                Canvas {
                    id: wave
                    anchors.fill: parent

                    property real ratio: card.ratio
                    property bool active: card.hasPlayer
                    property color accent: Rock.pink
                    property color accent2: Rock.cyan
                    property color fg: Rock.cream

                    onRatioChanged: requestPaint()
                    onActiveChanged: requestPaint()
                    onAccentChanged: requestPaint()
                    onAccent2Changed: requestPaint()
                    onFgChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const w = width, h = height
                        const n = 38
                        const bw = 2.5
                        const step = (w - bw) / (n - 1)
                        for (let i = 0; i < n; i++) {
                            const t = i / (n - 1)
                            const shape = 0.30 + 0.70 * Math.abs(Math.sin(i * 1.37) * Math.cos(i * 0.53))
                            const bh = 3 + shape * (h - 6)
                            const filled = t <= ratio
                            ctx.fillStyle = filled
                                ? (t < 0.66 ? accent : accent2)
                                : Qt.rgba(fg.r, fg.g, fg.b, active ? 0.13 : 0.06)
                            ctx.fillRect(i * step, (h - bh) / 2, bw, bh)
                        }
                        const px = Math.max(0, Math.min(1, ratio)) * (w - bw)
                        ctx.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.90)
                        ctx.fillRect(px, 0, 1.5, h)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: card.p ? card.p.canSeek : false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        if (card.p && card.p.canSeek && card.p.length > 0)
                            card.p.position = Math.max(0, Math.min(1, mouse.x / wave.width)) * card.p.length
                    }
                    onDoubleClicked: if (card.p && card.p.canSeek) card.p.position = 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Lbl {
                    text: Fmt.clock(card.p ? card.p.position : 0)
                    color: Rock.a(Rock.cream, 0.45)
                    font.pixelSize: 9
                }

                Item { Layout.fillWidth: true }

                Lbl {
                    text: Fmt.clock(card.p ? card.p.length : 0)
                    color: Rock.a(Rock.cream, 0.45)
                    font.pixelSize: 9
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.topMargin: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    height: 1
                    color: Rock.a(Rock.cream, 0.08)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    DeskButton {
                        icon: "\uf048"
                        available: card.p ? card.p.canGoPrevious : false
                        onActivated: if (card.p && card.p.canGoPrevious) card.p.previous()
                    }

                    DeskButton {
                        big: true
                        active: card.playing
                        icon: card.playing ? "\uf04c" : "\uf04b"
                        available: card.p ? card.p.canTogglePlaying : false
                        onActivated: if (card.p && card.p.canTogglePlaying) card.p.togglePlaying()
                    }

                    DeskButton {
                        icon: "\uf051"
                        available: card.p ? card.p.canGoNext : false
                        onActivated: if (card.p && card.p.canGoNext) card.p.next()
                    }
                }
            }
        }
    }
}
