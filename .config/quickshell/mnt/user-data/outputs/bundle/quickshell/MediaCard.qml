import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Компактный плеер: обложка слева; название, перемотка и кнопки справа.
// Цвет акцентов берётся из обложки.
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

    function fmt(s) {
        if (!isFinite(s) || s < 0) return "0:00"
        return Math.floor(s / 60) + ":" + ("0" + Math.floor(s % 60)).slice(-2)
    }
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

    // ── кнопка управления ──
    component CBtn: Rectangle {
        id: cb
        property string icon
        property bool big: false
        property bool on: false
        property string badge: ""
        property color accentColor: Theme.accent
        signal activated()
        implicitWidth: big ? 40 : 30
        implicitHeight: implicitWidth
        radius: width / 2
        color: big ? (cArea.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor)
                   : (cArea.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        Lbl {
            anchors.centerIn: parent
            text: cb.icon
            color: cb.big ? Theme.textOnAccent : (cb.on ? cb.accentColor : Theme.text)
            font.pixelSize: cb.big ? 14 : 12
            opacity: (!cb.big && !cb.on) ? 0.85 : 1
        }
        Lbl {
            visible: cb.badge !== ""
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 1
            text: cb.badge
            color: cb.accentColor
            font.pixelSize: 8
            font.bold: true
        }
        MouseArea {
            id: cArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cb.activated()
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

            // ── обложка ──
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
            }

            // ── название, перемотка, кнопки ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Lbl {
                    Layout.fillWidth: true
                    text: card.p ? (card.p.trackTitle || "Без названия") : ""
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: card.p ? card.p.trackArtist : ""
                    color: card.artAccent
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.p ? (card.p.trackAlbum || "") : ""
                    color: Theme.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                Item { Layout.preferredHeight: 6 }

                // время · полоса · время
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Lbl {
                        Layout.preferredWidth: 28
                        text: card.fmt(seek.dragRatio >= 0 && card.p ? seek.dragRatio * card.p.length : (card.p ? card.p.position : 0))
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
                        }
                    }

                    // клик по правому времени: «всего» ↔ «осталось»
                    Lbl {
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                        text: card.p
                            ? (card.showRemaining ? "-" + card.fmt(Math.max(0, card.p.length - card.p.position)) : card.fmt(card.p.length))
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

                Item { Layout.preferredHeight: 2 }

                // кнопки
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    CBtn {
                        visible: card.p !== null && card.p.shuffleSupported
                        icon: "\uf074"
                        accentColor: card.artAccent
                        on: card.p ? card.p.shuffle : false
                        onActivated: if (card.p) card.p.shuffle = !card.p.shuffle
                    }
                    Item { Layout.fillWidth: true }
                    CBtn {
                        icon: "\uf048"
                        onActivated: if (card.p && card.p.canGoPrevious) card.p.previous()
                    }
                    CBtn {
                        big: true
                        accentColor: card.artAccent
                        icon: card.playing ? "\uf04c" : "\uf04b"
                        onActivated: if (card.p && card.p.canTogglePlaying) card.p.togglePlaying()
                    }
                    CBtn {
                        icon: "\uf051"
                        onActivated: if (card.p && card.p.canGoNext) card.p.next()
                    }
                    Item { Layout.fillWidth: true }
                    CBtn {
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
