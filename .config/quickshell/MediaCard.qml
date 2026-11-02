import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Плеер: обложка слева; название, перемотка, громкость и кнопки справа.
// Цвет акцентов берётся из обложки. Колесо мыши над карточкой — громкость.
Rectangle {
    id: card

    property bool active: false                      // окно открыто — обновляем позицию
    readonly property var p: Media.player
    readonly property bool playing: p !== null && p.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: p ? String(p.trackArtUrl || "") : ""

    property color tint: Theme.accent                // средний цвет обложки
    property bool showRemaining: false

    // яркий вариант цвета обложки для акцентов
    readonly property color artAccent: {
        if (tint.hslSaturation < 0.12) return Theme.accent
        return Qt.hsla(Math.max(0, tint.hslHue), Math.max(0.5, Math.min(0.9, tint.hslSaturation)), 0.72, 1)
    }

    visible: p !== null
    implicitHeight: col.implicitHeight + 24
    radius: 20
    color: Qt.tint(Theme.surface, Qt.rgba(tint.r, tint.g, tint.b, 0.08))
    Behavior on color { ColorAnimation { duration: 450 } }
    Behavior on tint  { ColorAnimation { duration: 450 } }

    function cycleLoop() {
        if (!p || !p.loopSupported) return
        if (p.loopState === MprisLoopState.None) p.loopState = MprisLoopState.Playlist
        else if (p.loopState === MprisLoopState.Playlist) p.loopState = MprisLoopState.Track
        else p.loopState = MprisLoopState.None
    }

    Timer {
        running: card.active && card.playing
        interval: 500
        repeat: true
        onTriggered: card.p.positionChanged()
    }

    // колесо мыши над всей карточкой = громкость плеера
    WheelHandler {
        // прокручиваем только вертикальные колёса; горизонтальные игнорируем
        function handleWheel(w) {
            const dy = w.angleDelta.y
            if (card.p && card.p.volumeSupported && dy !== 0) {
                w.accepted = true
                Media.setVol(card.p.volume + (dy > 0 ? 0.03 : -0.03))
            }
        }
        onWheel: handleWheel(wheel)
    }

    // ── средний цвет обложки (крошечный холст 16×16) ──
    Canvas {
        id: sampler
        width: 16
        height: 16
        opacity: 0.01
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate
        property string src: card.artUrl

        function refresh() {
            if (src === "") { card.tint = Theme.accent; return }
            loadImage(src)
        }
        onSrcChanged: refresh()
        Component.onCompleted: refresh()
        onImageLoaded: requestPaint()

        onPaint: {
            if (src === "" || !isImageLoaded(src)) return
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, 16, 16)
            ctx.drawImage(src, 0, 0, 16, 16)
            const d = ctx.getImageData(0, 0, 16, 16).data
            let r = 0, g = 0, b = 0, w = 0
            for (let i = 0; i < d.length; i += 4) {
                const R = d[i] / 255, G = d[i + 1] / 255, B = d[i + 2] / 255, A = d[i + 3] / 255
                const mx = Math.max(R, G, B), mn = Math.min(R, G, B)
                const sat = mx === 0 ? 0 : (mx - mn) / mx
                const wt = A * (sat * sat + 0.02) * (0.25 + mx) * (mx > 0.15 ? 1 : 0.1)
                r += R * wt; g += G * wt; b += B * wt; w += wt
            }
            card.tint = w > 0.01 ? Qt.rgba(r / w, g / w, b / w, 1) : Theme.accent
        }
    }


    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // ── обложка (клик = play/pause) ──
            Item {
                Layout.preferredWidth: 92
                Layout.preferredHeight: 92
                Layout.alignment: Qt.AlignTop
                opacity: card.playing ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: 250 } }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: card.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "\uf001"
                    color: Theme.muted
                    font.pixelSize: 26
                }
                RoundMask { anchors.fill: parent; radius: 16; maskColor: card.color }

                // оверлей-иконка при наведении
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Qt.rgba(0, 0, 0, 0.35)
                    opacity: artArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Lbl {
                        anchors.centerIn: parent
                        text: card.playing ? "\uf04c" : "\uf04b"
                        color: "white"
                        font.pixelSize: 22
                    }
                }
                MouseArea {
                    id: artArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (card.p && card.p.canTogglePlaying) card.p.togglePlaying()
                }
            }

            // ── название, перемотка, громкость, кнопки ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Lbl {
                        Layout.fillWidth: true
                        text: card.p ? (card.p.trackTitle || "Без названия") : ""
                        font.bold: true
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                    // «любимый трек»
                    MediaBtn {
                        visible: card.p !== null
                        icon: Media.isLoved ? "\uf004" : "\uf08a"
                        accentColor: "#e0557a"
                        on: Media.isLoved
                        onActivated: Media.toggleLove()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Lbl {
                        Layout.fillWidth: true
                        text: card.p ? card.p.trackArtist : ""
                        color: card.artAccent
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Lbl {
                        visible: text !== ""
                        text: card.p ? (card.p.trackAlbum || "") : ""
                        color: Theme.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.maximumWidth: 110
                    }
                }

                Item { Layout.preferredHeight: 6 }

                // время · полоса · время
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Lbl {
                        Layout.preferredWidth: 34
                        text: Fmt.hms(seek.dragRatio >= 0 && card.p ? seek.dragRatio * card.p.length : (card.p ? card.p.position : 0))
                        color: Theme.muted
                        font.pixelSize: 10
                    }

                    Item {
                        id: seek
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16

                        readonly property real ratio: (card.p && card.p.length > 0)
                            ? Math.max(0, Math.min(1, card.p.position / card.p.length)) : 0
                        property real dragRatio: -1
                        readonly property real shown: dragRatio >= 0 ? dragRatio : ratio
                        readonly property bool hot: seekArea.containsMouse || seekArea.pressed

                        Rectangle {
                            id: track
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: seek.hot ? 6 : 4
                            radius: height / 2
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14)
                            Behavior on height { NumberAnimation { duration: 120 } }
                            Rectangle {
                                width: parent.width * seek.shown
                                height: parent.height
                                radius: height / 2
                                color: card.artAccent
                            }
                        }
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * seek.shown - width / 2))
                            color: Theme.text
                            opacity: seek.hot ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function r(mx) { return Math.max(0, Math.min(1, mx / width)) }
                            onPressed: m => seek.dragRatio = r(m.x)
                            onPositionChanged: m => { if (pressed) seek.dragRatio = r(m.x) }
                            onReleased: {
                                const pl = card.p
                                if (pl && pl.canSeek && pl.length > 0 && seek.dragRatio >= 0)
                                    pl.position = seek.dragRatio * pl.length
                                seek.dragRatio = -1
                            }
                            // двойной клик по полосе = ±5 сек в точку клика не тащим — просто рестарт
                            onDoubleClicked: if (card.p && card.p.canSeek) card.p.position = 0
                        }
                    }

                    // клик по правому времени: «всего» ↔ «осталось»
                    Lbl {
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        text: card.p
                            ? (card.showRemaining ? "-" + Fmt.hms(Math.max(0, card.p.length - card.p.position)) : Fmt.hms(card.p.length))
                            : ""
                        color: Theme.muted
                        font.pixelSize: 10
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.showRemaining = !card.showRemaining
                        }
                    }
                }

                Item { Layout.preferredHeight: 4 }

                // ── громкость плеера ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    spacing: 6
                    visible: card.p !== null && card.p.volumeSupported

                    Lbl {
                        text: (card.p && card.p.volume <= 0) ? "\uf026" : (card.p && card.p.volume < 0.5 ? "\uf027" : "\uf028")
                        color: Theme.muted
                        font.pixelSize: 10
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (card.p) Media.setVol(card.p.volume > 0 ? 0 : 0.5)
                        }
                    }
                    Item {
                        id: vol
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14
                        readonly property real shown: card.p ? Math.max(0, Math.min(1, card.p.volume)) : 0
                        readonly property bool hot: volArea.containsMouse || volArea.pressed

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: vol.hot ? 5 : 3
                            radius: height / 2
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                            Behavior on height { NumberAnimation { duration: 120 } }
                            Rectangle {
                                width: parent.width * vol.shown
                                height: parent.height
                                radius: height / 2
                                color: Qt.rgba(card.artAccent.r, card.artAccent.g, card.artAccent.b, 0.75)
                            }
                        }
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * vol.shown - width / 2))
                            color: Theme.text
                            opacity: vol.hot ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            id: volArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function set(mx) { Media.setVol(Math.max(0, Math.min(1, mx / width))) }
                            onPressed: m => set(m.x)
                            onPositionChanged: m => { if (pressed) set(m.x) }
                        }
                    }
                    Lbl {
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                        text: card.p ? Math.round(card.p.volume * 100) + "%" : ""
                        color: Theme.muted
                        font.pixelSize: 9
                    }
                }

                Item { Layout.preferredHeight: 2 }

                // кнопки
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    MediaBtn {
                        visible: card.p !== null && card.p.shuffleSupported
                        icon: "\uf074"
                        accentColor: card.artAccent
                        on: card.p ? card.p.shuffle : false
                        onActivated: if (card.p) card.p.shuffle = !card.p.shuffle
                    }
                    Item { Layout.fillWidth: true }
                    MediaBtn {
                        icon: "\uf04a"                       // −5 секунд
                        enabled: card.p ? card.p.canSeek : false
                        onActivated: Media.seekBy(-5)
                    }
                    MediaBtn {
                        icon: "\uf048"
                        onActivated: if (card.p && card.p.canGoPrevious) card.p.previous()
                    }
                    MediaBtn {
                        big: true
                        accentColor: card.artAccent
                        icon: card.playing ? "\uf04c" : "\uf04b"
                        onActivated: if (card.p && card.p.canTogglePlaying) card.p.togglePlaying()
                    }
                    MediaBtn {
                        icon: "\uf051"
                        onActivated: if (card.p && card.p.canGoNext) card.p.next()
                    }
                    MediaBtn {
                        icon: "\uf04e"                       // +5 секунд
                        enabled: card.p ? card.p.canSeek : false
                        onActivated: Media.seekBy(5)
                    }
                    Item { Layout.fillWidth: true }
                    MediaBtn {
                        visible: card.p !== null && card.p.loopSupported
                        icon: "\uf021"
                        accentColor: card.artAccent
                        on: card.p ? card.p.loopState !== MprisLoopState.None : false
                        badge: (card.p && card.p.loopState === MprisLoopState.Track) ? "1" : ""
                        onActivated: card.cycleLoop()
                    }
                }
            }
        }

        // ── выбор плеера, если их несколько ──
        RowLayout {
            visible: Media.players.length > 1
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Media.players
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool current: card.p === modelData
                    implicitWidth: chipLbl.implicitWidth + 20
                    implicitHeight: 22
                    radius: 11
                    color: current ? Qt.rgba(card.artAccent.r, card.artAccent.g, card.artAccent.b, 0.20)
                                   : (chipArea.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent")
                    border.width: 1
                    border.color: current ? card.artAccent : Theme.hairline
                    Lbl {
                        id: chipLbl
                        anchors.centerIn: parent
                        text: String(chip.modelData.identity).substring(0, 14)
                        color: chip.current ? card.artAccent : Theme.muted
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.pin(chip.current && Media.pinned === chip.modelData ? null : chip.modelData)
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
