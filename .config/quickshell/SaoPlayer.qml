import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Плеер в стиле HUD Sword Art Online: голографическая карточка,
// гексагональная обложка, сегментные полосы и журнал последних треков.
BarPopup {
    id: popup
    alignment: "center"

    fill: "transparent"
    accent: "transparent"
    radius: 0
    borderWidth: 0
    decorated: false

    implicitWidth: 590
    implicitHeight: card.height + 34

    property int pulse: 0
    Timer {
        id: pulseTimer
        interval: 120
        repeat: true
        running: popup.visible && Media.playing
        onTriggered: popup.pulse += 1
    }

    function eqH(i) {
        const base = (Media.playing && Media.player !== null) ? 20 : 5
        return Math.max(3, base * (0.25 + 0.75 * Math.abs(Math.sin(pulse * 0.55 + i * 1.7))))
    }

    function cycleLoop() {
        const p = Media.player
        if (!p) return
        if (p.loopState === MprisLoopState.None) p.loopState = MprisLoopState.Playlist
        else if (p.loopState === MprisLoopState.Playlist) p.loopState = MprisLoopState.Track
        else p.loopState = MprisLoopState.None
    }
    readonly property int loopMode: Media.player ? Media.player.loopState : MprisLoopState.None
    readonly property bool loopActive: loopMode !== MprisLoopState.None
    function loopBadge() {
        if (loopMode === MprisLoopState.Track) return "TRK"
        if (loopMode === MprisLoopState.Playlist) return "ALL"
        return ""
    }

    property var recentTracks: []
    property string lastTrackKey: ""

    function rememberTrack() {
        const p = Media.player
        if (!p) return
        const title = String(p.trackTitle || "")
        const artist = String(p.trackArtist || "")
        if (title === "" && artist === "") return
        const key = artist + "|" + title
        if (key === lastTrackKey) return
        lastTrackKey = key
        const list = recentTracks.slice()
        for (let i = list.length - 1; i >= 0; i--)
            if (list[i].key === key) list.splice(i, 1)
        list.unshift({ key: key, title: title || I18n.t("Без названия"), artist: artist })
        if (list.length > 5) list.length = 5
        recentTracks = list
    }

    readonly property var dataLog: {
        const cur = Media.player
        const out = []
        const seen = ({})
        if (cur) {
            const title = String(cur.trackTitle || "")
            const artist = String(cur.trackArtist || "")
            if (title !== "" || artist !== "") {
                const key = artist + "|" + title
                out.push({ key: key, title: title || I18n.t("Без названия"), artist: artist, now: true })
                seen[key] = true
            }
        }
        const list = recentTracks
        for (let i = 0; i < list.length && out.length < 5; i++) {
            const e = list[i]
            if (seen[e.key]) continue
            out.push({ key: e.key, title: e.title, artist: e.artist, now: false })
            seen[e.key] = true
        }
        return out
    }

    Timer {
        interval: 1000
        repeat: true
        running: popup.visible
        onTriggered: popup.rememberTrack()
    }
    Component.onCompleted: rememberTrack()

    component HexBtn: Item {
        id: hex
        property string icon: ""
        property bool big: false
        property bool active: false
        property string badge: ""
        signal activated()
        implicitWidth: big ? 54 : 34
        implicitHeight: implicitWidth

        Rectangle {
            anchors.centerIn: parent
            width: hex.big ? parent.width : parent.width - 2
            height: width
            radius: 2
            rotation: 45
            color: hex.big
                ? (hexArea.containsMouse ? Qt.lighter(Rock.gold, 1.1) : Rock.gold)
                : (hexArea.containsMouse ? Rock.a(Rock.gold, 0.20)
                   : (hex.active ? Rock.a(Rock.gold, 0.18) : Rock.a(Rock.uiSurface2, 0.75)))
            border.width: hex.big ? 2 : 1
            border.color: hex.big ? Rock.starlight : Rock.a(Rock.gold, 0.7)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            anchors.centerIn: parent
            text: hex.icon
            color: hex.big ? Rock.ink : (hex.active ? Rock.gold : Rock.uiText)
            font.pixelSize: hex.big ? 19 : 12
        }

        Text {
            visible: hex.badge !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -4
            text: hex.badge
            color: Rock.gold
            font.family: Rock.display
            font.pixelSize: 6
            font.weight: Font.Black
            font.letterSpacing: 0.6
        }

        MouseArea {
            id: hexArea
            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hex.activated()
        }
    }

    Rectangle {
        id: card
        width: popup.implicitWidth - 20
        height: layout.implicitHeight + 36
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 5
        color: Rock.a(Rock.uiSurface, 0.97)
        border.width: 1
        border.color: Rock.uiEdge
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        SaoGrid { anchors.fill: parent; step: 26; animated: popup.visible }

        // верхняя HUD-линия
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 13
            x: 22
            height: 1
            color: Rock.a(Rock.gold, 0.35)
        }

        SaoFrame {
            anchors.fill: parent
            inset: 4
            cut: 11
            segments: 30
        }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 12

            // шапка
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 11; height: 11; radius: 1; rotation: 45
                    color: Rock.a(Rock.gold, 0.25)
                    border.width: 1
                    border.color: Rock.gold
                    Text {
                        anchors.centerIn: parent
                        text: "\uf001"
                        color: Rock.gold
                        font.pixelSize: 6
                        rotation: -45
                    }
                }

                ColumnLayout {
                    spacing: -2
                    Lbl {
                        text: "AINCRAD AUDIO"
                        color: Rock.gold
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 13
                        font.letterSpacing: 2
                    }
                    Lbl {
                        text: "NOW PLAYING · LINK CHANNEL"
                        color: Rock.a(Rock.uiText, 0.48)
                        font.pixelSize: 8
                        font.letterSpacing: 1.4
                    }
                }

                Item { Layout.fillWidth: true }

                Lbl {
                    text: Media.player ? String(Media.player.identity || "PLAYER").toUpperCase() : "NO SIGNAL"
                    color: Rock.a(Rock.gold, 0.8)
                    font.pixelSize: 8
                    font.weight: Font.Black
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                    Layout.maximumWidth: 130
                }
            }

            // обложка + телеметрия
            RowLayout {
                Layout.fillWidth: true
                spacing: 18

                Item {
                    Layout.preferredWidth: 156
                    Layout.preferredHeight: 156

                    // вращающееся гексагональное кольцо
                    Canvas {
                        anchors.fill: parent
                        opacity: 0.4
                        onWidthChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const cx = width / 2, cy = height / 2, r = width * 0.48
                            ctx.strokeStyle = Rock.a(Rock.gold, 0.55)
                            ctx.lineWidth = 1
                            for (const k of [1.0, 0.88]) {
                                ctx.beginPath()
                                for (let i = 0; i < 6; i++) {
                                    const a = -Math.PI / 2 + i * Math.PI / 3
                                    const x = cx + Math.cos(a) * r * k
                                    const y = cy + Math.sin(a) * r * k
                                    if (i === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.closePath()
                                ctx.stroke()
                            }
                        }
                        NumberAnimation on rotation {
                            running: Media.playing && popup.visible
                            from: 0
                            to: 360
                            duration: 42000
                            loops: Animation.Infinite
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 122
                        height: 122
                        radius: 6
                        color: Rock.uiSurface2
                        border.width: 1
                        border.color: Rock.uiEdge
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: Media.player ? (Media.player.trackArtUrl || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: Media.player !== null && Media.player.trackArtUrl !== ""
                        }
                        Lbl {
                            anchors.centerIn: parent
                            visible: Media.player === null || Media.player.trackArtUrl === ""
                            text: "\uf001"
                            color: Rock.uiSub
                            font.pixelSize: 34
                        }
                        RoundMask { anchors.fill: parent; radius: 6; maskColor: Rock.uiSurface2 }
                    }

                    SaoFrame {
                        anchors.fill: parent
                        inset: 10
                        cut: 12
                        segments: 10
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 156
                    spacing: 6

                    Lbl {
                        Layout.fillWidth: true
                        text: Media.player ? (Media.player.trackTitle || I18n.t("Без названия")) : I18n.t("Нет активного плеера")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 18
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: Media.player ? String(Media.player.trackArtist || "") : ""
                        color: Rock.gold
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: Media.player ? String(Media.player.trackAlbum || "") : ""
                        color: Rock.a(Rock.uiText, 0.45)
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                    // эквалайзер
                    Row {
                        Layout.alignment: Qt.AlignLeft
                        spacing: 3
                        Repeater {
                            model: 14
                            delegate: Rectangle {
                                required property int index
                                width: 4
                                height: popup.eqH(index)
                                radius: 1
                                color: index % 4 === 0 ? Rock.starlight : Rock.gold
                                opacity: Media.playing ? 0.95 : 0.4
                                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutSine } }
                            }
                        }
                    }

                    Lbl {
                        Layout.fillWidth: true
                        text: "HP  " + (Media.player ? Fmt.clock(Media.player.position || 0) : "0:00")
                              + "  /  " + (Media.player ? Fmt.hms(Media.player.length || 0) : "0:00")
                        color: Rock.a(Rock.uiText, 0.55)
                        font.family: Rock.mono
                        font.pixelSize: 9
                        font.letterSpacing: 0.6
                    }
                }
            }

            // сегментная полоса позиции
            Item {
                Layout.fillWidth: true
                implicitHeight: 16
                readonly property real frac: (Media.player && Media.player.length > 0)
                    ? Math.max(0, Math.min(1, (Media.player.position || 0) / Media.player.length)) : 0
                property real dragV: -1
                readonly property real shownV: dragV >= 0 ? dragV : frac

                SaoBar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 9
                    value: parent.shownV
                    segments: 42
                    gap: 2
                    fill: Rock.gold
                }

                Rectangle {
                    width: 9; height: 9; radius: 1; rotation: 45
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * parent.shownV - width / 2))
                    color: Rock.starlight
                    border.width: 1
                    border.color: Rock.gold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function setV(mx) {
                        const r = Math.max(0, Math.min(1, mx / width))
                        parent.dragV = r
                        if (Media.player && Media.player.canSeek && Media.player.length > 0)
                            Media.player.position = r * Media.player.length
                    }
                    onPressed: m => setV(m.x)
                    onPositionChanged: m => { if (pressed) setV(m.x) }
                    onReleased: { if (parent.dragV >= 0) parent.dragV = -1 }
                }
            }

            // транспорт
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                spacing: 12

                HexBtn {
                    icon: "\uf048"
                    onActivated: if (Media.player && Media.player.canGoPrevious) Media.player.previous()
                }
                HexBtn {
                    big: true
                    icon: (Media.playing && Media.player !== null) ? "\uf04c" : "\uf04b"
                    onActivated: if (Media.player && Media.player.canTogglePlaying) Media.player.togglePlaying()
                }
                HexBtn {
                    icon: "\uf051"
                    onActivated: if (Media.player && Media.player.canGoNext) Media.player.next()
                }
                HexBtn {
                    icon: "\uf021"
                    active: popup.loopActive
                    badge: popup.loopBadge()
                    onActivated: popup.cycleLoop()
                }

                Item { Layout.fillWidth: true }

                Lbl {
                    text: "\uf028"
                    color: Rock.uiSub
                    font.pixelSize: 12
                }
                Item {
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 14
                    readonly property real shown: (Media.player && Media.player.volumeSupported)
                        ? Math.max(0, Math.min(1, Media.player.volume)) : 0
                    property real dragV: -1
                    readonly property real shownV: dragV >= 0 ? dragV : shown
                    SaoBar {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 7
                        value: parent.shownV
                        segments: 16
                        gap: 2
                        fill: Rock.gold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        function setV(mx) {
                            const r = Math.max(0, Math.min(1, mx / width))
                            parent.dragV = r
                            Media.setVol(r)
                        }
                        onPressed: m => setV(m.x)
                        onPositionChanged: m => { if (pressed) setV(m.x) }
                        onReleased: { if (parent.dragV >= 0) Media.setVol(parent.dragV); parent.dragV = -1 }
                    }
                }
                Lbl {
                    Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((Media.player ? Media.player.volume : 0) * 100) + "%"
                    color: Rock.uiSub
                    font.pixelSize: 9
                }
            }

            // журнал данных
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8
                Lbl {
                    text: "DATA LOG"
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Rock.a(Rock.gold, 0.28) }
                Lbl {
                    text: popup.dataLog.length > 0 && popup.dataLog[0].now ? "ACTIVE" : "RECENT"
                    color: Rock.gold
                    font.pixelSize: 8
                    font.weight: Font.Black
                    font.letterSpacing: 1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: popup.dataLog
                    delegate: Rectangle {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool now: entry.modelData.now === true

                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 3
                        color: entry.now ? Rock.a(Rock.gold, 0.13)
                                         : (entryArea.containsMouse ? Rock.a(Rock.gold, 0.07) : "transparent")
                        border.width: entry.now ? 1 : 0
                        border.color: Rock.a(Rock.gold, 0.45)

                        MouseArea {
                            id: entryArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Rectangle {
                            visible: entry.now
                            width: 3
                            height: parent.height - 8
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: Rock.gold
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8
                            Lbl {
                                Layout.preferredWidth: 34
                                text: "0x" + ("0" + (entry.index + 1)).slice(-2)
                                color: entry.now ? Rock.gold : Rock.a(Rock.uiText, 0.38)
                                font.family: Rock.mono
                                font.pixelSize: 8
                            }
                            Lbl {
                                Layout.fillWidth: true
                                text: entry.modelData.title
                                color: entry.now ? Rock.uiText : Rock.a(Rock.uiText, 0.72)
                                font.family: Rock.display
                                font.weight: entry.now ? Font.Black : Font.Normal
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                            Lbl {
                                visible: entry.modelData.artist !== ""
                                Layout.maximumWidth: 150
                                text: entry.modelData.artist
                                color: Rock.a(Rock.gold, 0.7)
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                            Lbl {
                                visible: entry.now
                                text: "◆ LINK"
                                color: Rock.gold
                                font.pixelSize: 7
                                font.weight: Font.Black
                                font.letterSpacing: 0.8
                            }
                        }
                    }
                }
            }

            // переключение плееров
            RowLayout {
                visible: Media.players.length > 1
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Media.players
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool current: Media.player === modelData
                        implicitWidth: chipLbl.implicitWidth + 18
                        implicitHeight: 20
                        radius: 2
                        color: current ? Rock.a(Rock.gold, 0.16) : "transparent"
                        border.width: 1
                        border.color: current ? Rock.gold : Rock.a(Rock.uiText, 0.25)
                        Lbl {
                            id: chipLbl
                            anchors.centerIn: parent
                            text: String(chip.modelData.identity).substring(0, 12).toUpperCase()
                            color: chip.current ? Rock.gold : Rock.a(Rock.uiText, 0.55)
                            font.pixelSize: 8
                            font.weight: chip.current ? Font.Black : Font.Normal
                            font.letterSpacing: 0.6
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.pin(chip.current && Media.pinned === chip.modelData ? null : chip.modelData)
                        }
                    }
                }
            }
        }
    }
}
