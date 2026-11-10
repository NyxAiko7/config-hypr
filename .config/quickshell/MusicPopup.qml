import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

BarPopup {
    id: popup
    alignment: "center"
    property var player: null

    fill: "transparent"
    accent: "transparent"
    radius: 0
    borderWidth: 0
    decorated: false

    implicitWidth: 420
    implicitHeight: card.height + 12

    readonly property var p: Media.player
    readonly property bool hasPlayer: p !== null && p !== undefined
    readonly property bool playing: hasPlayer && p.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: hasPlayer ? String(p.trackArtUrl || "") : ""
    readonly property real ratio: (hasPlayer && p.length > 0)
        ? Math.max(0, Math.min(1, (p.position || 0) / p.length)) : 0
    readonly property string identity: hasPlayer ? String(p.identity || "") : ""
    readonly property int loopMode: hasPlayer ? p.loopState : MprisLoopState.None
    readonly property bool loopActive: loopMode !== MprisLoopState.None

    property color tint: Rock.uiAccent
    Behavior on tint { ColorAnimation { duration: 420 } }

    readonly property color artAccent: {
        if (tint.hslSaturation < 0.12) return Rock.uiAccent
        const l = Rock.light ? 0.46 : 0.72
        return Qt.hsla(tint.hslHue, Math.max(0.5, Math.min(0.86, tint.hslSaturation)), l, 1)
    }
    readonly property color edge: Rock.a(Rock.uiText, 0.10)
    readonly property color line: Rock.a(Rock.uiText, 0.14)

    Timer {
        running: popup.visible && popup.playing
        interval: 500
        repeat: true
        onTriggered: if (popup.hasPlayer) popup.p.positionChanged()
    }

    WheelHandler {
        function handleWheel(w) {
            const dy = w.angleDelta.y
            if (popup.p && popup.p.volumeSupported && dy !== 0) {
                w.accepted = true
                Media.setVol(popup.p.volume + (dy > 0 ? 0.03 : -0.03))
            }
        }
        onWheel: handleWheel(wheel)
    }

    Canvas {
        id: sampler
        width: 16
        height: 16
        opacity: 0.01
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate
        property string src: popup.artUrl

        function refresh() {
            if (src === "") { popup.tint = Rock.uiAccent; return }
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
                const R = d[i] / 255, G = d[i + 1] / 255, B = d[i + 2] / 255
                const A = d[i + 3] / 255
                const mx = Math.max(R, G, B), mn = Math.min(R, G, B)
                const sat = mx === 0 ? 0 : (mx - mn) / mx
                const wt = A * (sat * sat + 0.02) * (0.25 + mx) * (mx > 0.15 ? 1 : 0.1)
                r += R * wt; g += G * wt; b += B * wt; w += wt
            }
            popup.tint = w > 0.01 ? Qt.rgba(r / w, g / w, b / w, 1) : Rock.uiAccent
        }
    }

    function cycleLoop() {
        const pl = popup.p
        if (!pl || !pl.loopSupported) return
        if (pl.loopState === MprisLoopState.None) pl.loopState = MprisLoopState.Playlist
        else if (pl.loopState === MprisLoopState.Playlist) pl.loopState = MprisLoopState.Track
        else pl.loopState = MprisLoopState.None
    }

    function loopBadge() {
        if (loopMode === MprisLoopState.Track) return "1"
        return ""
    }

    component CtrlBtn: Item {
        id: btn
        property string icon: ""
        property bool active: false
        property bool primary: false
        property bool available: true
        property int size: 34
        property string badge: ""
        signal activated()

        implicitWidth: primary ? 56 : size
        implicitHeight: implicitWidth
        opacity: available ? 1 : 0.35
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: btn.primary
                ? (btnArea.containsMouse && btn.available ? Qt.lighter(popup.artAccent, 1.08) : popup.artAccent)
                : (btn.active
                    ? Rock.a(popup.artAccent, btnArea.containsMouse ? 0.28 : 0.18)
                    : (btnArea.containsMouse && btn.available ? Rock.a(Rock.uiText, 0.08) : "transparent"))
            border.width: btn.primary ? 0 : 1
            border.color: btn.active ? Rock.a(popup.artAccent, 0.55) : Rock.a(Rock.uiText, 0.10)
            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                visible: btn.primary
                anchors.fill: parent
                radius: width / 2
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                    GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
                }
            }

            Lbl {
                anchors.centerIn: parent
                text: btn.icon
                color: btn.primary ? Rock.uiOnActive : (btn.active ? popup.artAccent : Rock.uiText)
                font.pixelSize: btn.primary ? 19 : 13
                opacity: btn.primary ? 1 : (btn.active ? 1 : 0.82)
                scale: btnArea.pressed ? 0.86 : 1
                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
            }

            Rectangle {
                visible: btn.badge !== ""
                width: 13
                height: 13
                radius: 6.5
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 1
                anchors.bottomMargin: 1
                color: Rock.uiSurface2
                border.width: 1
                border.color: Rock.a(popup.artAccent, 0.7)
                Lbl {
                    anchors.centerIn: parent
                    text: btn.badge
                    color: popup.artAccent
                    font.pixelSize: 7
                    font.bold: true
                }
            }
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            anchors.margins: -2
            hoverEnabled: true
            enabled: btn.available
            cursorShape: btn.available ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.activated()
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 6

        Rectangle {
            id: card
            x: 0
            y: 0
            width: stage.width
            height: layout.implicitHeight + 36
            radius: 22
            color: Rock.uiSurface
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.lighter(Rock.uiSurface, 1.05) }
                GradientStop { position: 1.0; color: Qt.darker(Rock.uiSurface, 1.08) }
            }
            border.width: 1
            border.color: Rock.a(popup.artAccent, 0.34)
            clip: true
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Rectangle {
                width: 300
                height: 300
                radius: 150
                x: card.width / 2 - 150
                y: -176
                color: Rock.a(popup.artAccent, 0.10)
            }

            Rectangle {
                width: 168
                height: 168
                radius: 84
                x: card.width / 2 - 84
                y: -76
                color: Rock.a(popup.artAccent, 0.12)
            }

            Rectangle {
                x: 18
                y: 0
                width: card.width - 36
                height: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(popup.artAccent.r, popup.artAccent.g, popup.artAccent.b, 0.0) }
                    GradientStop { position: 0.5; color: popup.artAccent }
                    GradientStop { position: 1.0; color: Qt.rgba(popup.artAccent.r, popup.artAccent.g, popup.artAccent.b, 0.0) }
                }
            }

            ColumnLayout {
                id: layout
                x: 20
                y: 18
                width: card.width - 40
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: popup.playing ? popup.artAccent : Rock.uiSub
                        SequentialAnimation on opacity {
                            running: popup.playing
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }

                    Lbl {
                        text: I18n.t("СЕЙЧАС ИГРАЕТ")
                        color: Rock.uiSub
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                    }

                    Item { Layout.fillWidth: true }

                    CtrlBtn {
                        size: 26
                        icon: Media.isLoved ? "\uf004" : "\uf08a"
                        active: Media.isLoved
                        available: popup.hasPlayer
                        onActivated: Media.toggleLove()
                    }

                    Rectangle {
                        id: playerChip
                        visible: popup.identity !== ""
                        implicitWidth: Math.min(chipLbl.implicitWidth, 118) + 16
                        implicitHeight: 21
                        radius: 10
                        color: chipArea.containsMouse && Media.players.length > 1
                            ? Rock.a(popup.artAccent, 0.18) : Rock.a(Rock.uiText, 0.05)
                        border.width: 1
                        border.color: Rock.a(Rock.uiText, 0.10)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Lbl {
                            id: chipLbl
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, 118)
                            text: popup.identity.substring(0, 18).toUpperCase()
                            color: Rock.uiSub
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Media.players.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (Media.players.length > 1) Media.nextPlayer()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190

                    Canvas {
                        id: orbit
                        anchors.centerIn: parent
                        width: 184
                        height: 184
                        property real prog: popup.ratio
                        property color accentColor: popup.artAccent
                        property color baseColor: Rock.a(Rock.uiText, 0.12)

                        onProgChanged: requestPaint()
                        onAccentColorChanged: requestPaint()
                        onBaseColorChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const cx = width / 2, cy = height / 2
                            const r = Math.min(width, height) / 2 - 3

                            ctx.lineWidth = 1.5
                            ctx.strokeStyle = baseColor
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.stroke()

                            for (let i = 0; i < 16; i++) {
                                const a = i * Math.PI / 8
                                ctx.fillStyle = Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.55)
                                ctx.beginPath()
                                ctx.arc(cx + Math.cos(a) * (r + 6), cy + Math.sin(a) * (r + 6), 1, 0, Math.PI * 2)
                                ctx.fill()
                            }

                            if (prog > 0.001) {
                                const start = -Math.PI / 2
                                const end = start + prog * Math.PI * 2
                                ctx.strokeStyle = accentColor
                                ctx.lineWidth = 3
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(cx, cy, r, start, end)
                                ctx.stroke()

                                ctx.fillStyle = accentColor
                                ctx.beginPath()
                                ctx.arc(cx + Math.cos(end) * r, cy + Math.sin(end) * r, 3, 0, Math.PI * 2)
                                ctx.fill()
                            }
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        width: 148
                        height: 148
                        opacity: popup.playing ? 1 : 0.78
                        Behavior on opacity { NumberAnimation { duration: 220 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: Rock.uiSurface
                            border.width: 1
                            border.color: Rock.a(Rock.uiText, 0.12)
                        }

                        Image {
                            id: art
                            anchors.fill: parent
                            source: popup.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Lbl {
                            anchors.centerIn: parent
                            visible: !art.visible
                            text: "\uf001"
                            color: Rock.uiSub
                            font.pixelSize: 34
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: Rock.a(Rock.ink, 0.48)
                            opacity: artArea.containsMouse ? 1 : (popup.playing ? 0 : 0.55)
                            Behavior on opacity { NumberAnimation { duration: 160 } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 48
                                height: 48
                                radius: 24
                                color: Rock.a(Rock.uiSurface, 0.72)
                                border.width: 1
                                border.color: Rock.a(Rock.uiText, 0.22)

                                Lbl {
                                    anchors.centerIn: parent
                                    text: popup.playing ? "\uf04c" : "\uf04b"
                                    color: Rock.uiText
                                    font.pixelSize: 18
                                }
                            }
                        }

                        RoundMask {
                            anchors.fill: parent
                            radius: 20
                            maskColor: Rock.uiSurface
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: "transparent"
                            border.width: 1
                            border.color: Rock.a(Rock.uiText, 0.16)
                        }

                        MouseArea {
                            id: artArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (popup.p && popup.p.canTogglePlaying) popup.p.togglePlaying()
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Lbl {
                        Layout.fillWidth: true
                        text: popup.hasPlayer
                            ? (popup.p.trackTitle || I18n.t("Без названия"))
                            : I18n.t("Нет активного плеера")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 19
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: metaRow.implicitHeight

                        RowLayout {
                            id: metaRow
                            anchors.centerIn: parent
                            spacing: 6

                            Lbl {
                                Layout.maximumWidth: 220
                                text: popup.hasPlayer ? String(popup.p.trackArtist || "") : ""
                                color: popup.artAccent
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: popup.hasPlayer && String(popup.p.trackArtist || "") !== ""
                                           && String(popup.p.trackAlbum || "") !== ""
                                width: 3
                                height: 3
                                radius: 1.5
                                color: Rock.a(Rock.uiText, 0.35)
                            }

                            Lbl {
                                Layout.maximumWidth: 150
                                text: popup.hasPlayer ? String(popup.p.trackAlbum || "") : ""
                                color: Rock.a(Rock.uiSub, 0.85)
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Lbl {
                        Layout.preferredWidth: 34
                        text: Fmt.clock(popup.hasPlayer ? popup.p.position : 0)
                        color: Rock.uiSub
                        font.pixelSize: 10
                    }

                    Item {
                        id: seek
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18

                        readonly property real shown: dragRatio >= 0 ? dragRatio : popup.ratio
                        readonly property bool hot: seekArea.containsMouse || seekArea.pressed
                        property real dragRatio: -1

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: seek.hot ? 5 : 3
                            radius: height / 2
                            color: Rock.a(Rock.uiText, 0.14)
                            border.width: 1
                            border.color: Rock.a(Rock.uiText, 0.22)
                            Behavior on height { NumberAnimation { duration: 120 } }

                            Rectangle {
                                width: parent.width * seek.shown
                                height: parent.height
                                radius: height / 2
                                color: popup.artAccent
                            }
                        }

                        Rectangle {
                            width: seek.hot ? 12 : 9
                            height: width
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * seek.shown - width / 2))
                            color: Rock.uiText
                            border.width: 2
                            border.color: Rock.uiSurface
                            opacity: seek.hot ? 1 : 0.9
                            Behavior on width { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function ratioAt(mx) {
                                return Math.max(0, Math.min(1, (mx - 4) / (width - 8)))
                            }
                            onPressed: m => seek.dragRatio = ratioAt(m.x)
                            onPositionChanged: m => { if (pressed) seek.dragRatio = ratioAt(m.x) }
                            onReleased: {
                                if (popup.p && popup.p.canSeek && popup.p.length > 0 && seek.dragRatio >= 0)
                                    popup.p.position = seek.dragRatio * popup.p.length
                                seek.dragRatio = -1
                            }
                            onDoubleClicked: if (popup.p && popup.p.canSeek) popup.p.position = 0
                        }
                    }

                    Lbl {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: Fmt.hms(popup.hasPlayer ? popup.p.length : 0)
                        color: Rock.uiSub
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 20
                    color: Rock.a(Rock.uiSurface2, 0.55)
                    border.width: 1
                    border.color: Rock.a(Rock.uiText, 0.08)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        CtrlBtn {
                            size: 32
                            icon: "\uf074"
                            active: popup.hasPlayer && popup.p.shuffle
                            available: popup.hasPlayer && popup.p.shuffleSupported
                            onActivated: if (popup.p) popup.p.shuffle = !popup.p.shuffle
                        }

                        CtrlBtn {
                            size: 38
                            icon: "\uf048"
                            available: popup.hasPlayer && popup.p.canGoPrevious
                            onActivated: if (popup.p && popup.p.canGoPrevious) popup.p.previous()
                        }

                        CtrlBtn {
                            primary: true
                            icon: popup.playing ? "\uf04c" : "\uf04b"
                            available: popup.hasPlayer && popup.p.canTogglePlaying
                            onActivated: if (popup.p && popup.p.canTogglePlaying) popup.p.togglePlaying()
                        }

                        CtrlBtn {
                            size: 38
                            icon: "\uf051"
                            available: popup.hasPlayer && popup.p.canGoNext
                            onActivated: if (popup.p && popup.p.canGoNext) popup.p.next()
                        }

                        CtrlBtn {
                            size: 32
                            icon: "\uf021"
                            active: popup.loopActive
                            badge: popup.loopBadge()
                            available: popup.hasPlayer && popup.p.loopSupported
                            onActivated: popup.cycleLoop()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    spacing: 8
                    visible: popup.hasPlayer && popup.p.volumeSupported

                    Lbl {
                        text: popup.hasPlayer && popup.p.volume <= 0
                            ? "\uf026"
                            : (popup.hasPlayer && popup.p.volume < 0.5 ? "\uf027" : "\uf028")
                        color: Rock.uiSub
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (popup.p) Media.setVol(popup.p.volume > 0 ? 0 : 0.5)
                        }
                    }

                    Item {
                        id: vol
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14

                        readonly property real shown: popup.hasPlayer
                            ? Math.max(0, Math.min(1, popup.p.volume)) : 0
                        readonly property bool hot: volArea.containsMouse || volArea.pressed

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: vol.hot ? 5 : 3
                            radius: height / 2
                            color: Rock.a(Rock.uiText, 0.12)
                            border.width: 1
                            border.color: Rock.a(Rock.uiText, 0.20)
                            Behavior on height { NumberAnimation { duration: 120 } }

                            Rectangle {
                                width: parent.width * vol.shown
                                height: parent.height
                                radius: height / 2
                                color: Rock.a(popup.artAccent, 0.85)
                            }
                        }

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * vol.shown - width / 2))
                            color: Rock.uiText
                            opacity: vol.hot ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: volArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function setVol(mx) {
                                Media.setVol(Math.max(0, Math.min(1, (mx - 4) / (width - 8))))
                            }
                            onPressed: m => setVol(m.x)
                            onPositionChanged: m => { if (pressed) setVol(m.x) }
                        }
                    }

                    Lbl {
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                        text: Math.round((popup.hasPlayer ? popup.p.volume : 0) * 100) + "%"
                        color: Rock.uiSub
                        font.pixelSize: 9
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: Media.players.length > 1

                    Repeater {
                        model: Media.players
                        delegate: Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool current: Media.player === modelData
                            implicitWidth: chipLabel.implicitWidth + 20
                            implicitHeight: 22
                            radius: 11
                            color: chip.current
                                ? Rock.a(popup.artAccent, 0.18)
                                : (chipMouse.containsMouse ? Rock.a(Rock.uiText, 0.08) : "transparent")
                            border.width: 1
                            border.color: chip.current
                                ? Rock.a(popup.artAccent, 0.6)
                                : Rock.a(Rock.uiText, 0.12)

                            Lbl {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: String(chip.modelData.identity || "").substring(0, 14)
                                color: chip.current ? popup.artAccent : Rock.uiSub
                                font.pixelSize: 9
                                font.weight: chip.current ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: chipMouse
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
    }
}
