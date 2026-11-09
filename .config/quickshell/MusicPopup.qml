import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// MusicPopup — кассетный плеер/усилитель: катушки, бумажная этикетка, эквалайзер,
// очередь треков как сет-лист, кнопки-стикеры. Палитра — как погодный постер (Bocchi the Rock!).

BarPopup {
    id: popup
    alignment: "center"
    property var player: null            // оставлено для совместимости с Bar.qml
    fill: "transparent"
    accent: "transparent"
    radius: 0
    borderWidth: 0
    decorated: false

    implicitWidth: 432
    implicitHeight: card.height + 26

    property int eqFrame: 0
    Timer {
        id: eqTimer
        interval: 150
        repeat: true
        running: popup.visible && Media.playing
        onTriggered: popup.eqFrame += 1
    }

    function eqH(i) {
        const base = (Media.playing && Media.player !== null) ? 16 : 5
        const v = base * (0.35 + 0.65 * Math.abs(Math.sin(eqFrame * 0.55 + i * 1.7)))
        return Math.max(3, v)
    }
    function eqBarColor() {
        return (Media.playing && Media.player !== null) ? Rock.pink : Rock.a(Rock.uiText, 0.3)
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
        if (loopMode === MprisLoopState.Track) return "1"
        if (loopMode === MprisLoopState.Playlist) return "A"
        return ""
    }

    // ── сет-лист: текущий трек + недавняя история ──
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
        if (list.length > 4) list.length = 4
        recentTracks = list
    }

    readonly property var setlist: {
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
        for (let i = 0; i < list.length && out.length < 4; i++) {
            const e = list[i]
            if (seen[e.key]) continue
            out.push({ key: e.key, title: e.title, artist: e.artist, now: false })
            seen[e.key] = true
        }
        return out
    }

    Timer {
        id: trackDebounce
        interval: 200
        onTriggered: popup.rememberTrack()
    }
    Connections {
        target: Media
        function onTrackTitleChanged() { trackDebounce.restart() }
        function onPlayerChanged() { trackDebounce.restart() }
    }
    Component.onCompleted: rememberTrack()
    onVisibleChanged: if (visible) rememberTrack()

    component Reel: Rectangle {
        id: reel
        width: 42
        height: 42
        radius: 21
        color: Rock.comic ? Rock.uiSurface2 : Rock.a(Rock.uiActive, 0.9)
        border.width: Rock.comic ? Rock.uiBorder : 1
        border.color: Rock.comic ? Rock.uiEdge : Rock.marisa ? Rock.ink : Rock.a(Rock.gold, 0.72)

        NumberAnimation on rotation {
            running: Media.playing
            from: 0
            to: 360
            duration: 2600
            loops: Animation.Infinite
        }

        Repeater {
            model: Rock.comic ? 3 : 0
            Rectangle {
                required property int index
                width: 6
                height: 6
                radius: 3
                color: Rock.pink
                border.width: 1.5
                border.color: Rock.uiEdge
                x: 21 + Math.cos(index * Math.PI * 2 / 3) * 12 - width / 2
                y: 21 + Math.sin(index * Math.PI * 2 / 3) * 12 - height / 2
            }
        }

        Repeater {
            model: Rock.comic ? 0 : 3
            Rectangle {
                required property int index
                width: 4
                height: 4
                radius: 2
                color: index === 0 ? (Rock.marisa ? Rock.uiText : Rock.cream) : (Rock.marisa ? Rock.a(Rock.uiText, 0.6) : Rock.gold)
                x: 21 + Math.cos(index * Math.PI * 2 / 3 + Math.PI / 6) * 16 - width / 2
                y: 21 + Math.sin(index * Math.PI * 2 / 3 + Math.PI / 6) * 16 - height / 2
            }
        }

        Rectangle {
            visible: Rock.comic
            anchors.centerIn: parent
            width: 13
            height: 13
            radius: 6.5
            color: Rock.pink
            border.width: 2
            border.color: Rock.uiEdge
        }

        Rectangle {
            visible: !Rock.comic
            anchors.centerIn: parent
            width: 16
            height: 16
            radius: 8
            color: "transparent"
            border.width: 1
            border.color: Rock.a(Rock.gold, 0.55)
        }

        Rectangle {
            visible: !Rock.comic
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: 3.5
            color: Rock.gold
            border.width: 1
            border.color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.75)
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 8

        Rectangle {
            visible: Rock.comic
            x: 9
            y: 11
            width: card.width
            height: card.height
            radius: 18
            color: Rock.pink
            border.width: 3
            border.color: Rock.uiEdge
            rotation: -1.1
            transformOrigin: Item.Center
        }

        Rectangle {
            id: card
            width: 404
            height: layout.implicitHeight + 34
            radius: Rock.comic ? 18 : Rock.marisa ? 8 : Rock.sao ? 4 : 14
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            clip: true
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MarisaPattern {
                anchors.fill: parent
                opacity: 0.48
            }

            MarisaTrim {
                visible: Rock.marisa
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 5
                height: 3
                cell: 3
            }

            MarisaFrame {
                anchors.fill: parent
                inset: 6
                frameRadius: Math.max(2, card.radius - 3)
            }

            Rectangle {
                visible: !Rock.comic
                x: 18
                y: 8
                width: card.width - 36
                height: 1
                color: Rock.a(Rock.gold, 0.45)
            }
            Lbl {
                visible: !Rock.comic
                x: card.width / 2 - width / 2
                y: 1
                text: "✦"
                color: Rock.gold
                font.pixelSize: 11
            }

            ColumnLayout {
                id: layout
                x: 17
                y: 17
                width: card.width - 34
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Lbl {
                        text: Rock.comic ? "BOCCHI BOOMBOX" : Rock.marisa ? "MARISA SPELLBOX" : Rock.sao ? "AINCRAD AUDIO LINK" : "ASTRAL AUDIO LINK"
                        color: Rock.comic ? Rock.pinkDeep : Rock.gold
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Rock.a(Rock.uiText, 0.2)
                    }
                    Lbl {
                        text: Rock.comic ? "SIDE A" : Rock.marisa ? "GRIMOIRE SIDE" : Rock.sao ? "LINK CHANNEL" : "ORBITAL LINK"
                        color: Rock.comic ? Rock.uiSub : Rock.a(Rock.gold, 0.8)
                        font.pixelSize: 8
                        font.letterSpacing: 0.8
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    spacing: 16

                    Reel {}

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 8

                        Item {
                            Layout.alignment: Qt.AlignCenter
                            width: 92
                            height: 92

                            // Гримуар: вращающийся магический диск вместо обычной обложки.
                            MarisaDisc {
                                anchors.fill: parent
                                playing: Media.playing
                                artSource: Media.player ? Media.player.trackArtUrl : ""
                            }

                            Rectangle {
                                visible: !Rock.marisa
                                anchors.fill: parent
                                radius: 16
                                color: Rock.uiSurface2
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                Image {
                                    anchors.fill: parent
                                    source: Media.player ? Media.player.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: Media.player !== null && Media.player.trackArtUrl !== ""
                                }
                                Lbl {
                                    anchors.centerIn: parent
                                    visible: Media.player === null || Media.player.trackArtUrl === ""
                                    text: "\uf001"
                                    color: Rock.uiSub
                                    font.pixelSize: 30
                                }
                                RoundMask { anchors.fill: parent; radius: 16; maskColor: Rock.uiSurface2 }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 42
                            radius: Rock.comic ? 8 : Rock.marisa ? 4 : Rock.sao ? 3 : 9
                            color: Rock.uiSurface2
                            border.width: Rock.uiBorder
                            border.color: Rock.uiEdge
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 2
                                Lbl {
                                    Layout.fillWidth: true
                                    text: Media.player ? (Media.player.trackTitle || I18n.t("Без названия")) : ""
                                    color: Rock.uiText
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                                Lbl {
                                    Layout.fillWidth: true
                                    text: Media.player ? String(Media.player.trackArtist || "") : ""
                                    color: Rock.pinkDeep
                                    font.pixelSize: 10
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            spacing: 4
                            Rectangle { width: 4; height: eqH(0); radius: 2; color: eqBarColor() }
                            Rectangle { width: 4; height: eqH(1); radius: 2; color: eqBarColor() }
                            Rectangle { width: 4; height: eqH(2); radius: 2; color: eqBarColor() }
                            Rectangle { width: 4; height: eqH(3); radius: 2; color: eqBarColor() }
                            Rectangle { width: 4; height: eqH(4); radius: 2; color: eqBarColor() }
                        }
                    }

                    Reel {}
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 7
                    Lbl {
                        text: Rock.comic ? I18n.t("СЕТ-ЛИСТ") : Rock.marisa ? I18n.t("КНИГА ЗАКЛИНАНИЙ") : I18n.t("АРХИВ ТРЕКОВ")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 13
                        font.letterSpacing: 1.2
                    }
                    Rectangle { Layout.fillWidth: true; height: 2; color: Rock.a(Rock.uiText, 0.2) }
                    RockChip {
                        visible: popup.setlist.length > 0
                        fill: Rock.comic ? Rock.pink : Rock.gold
                        shadowColor: Rock.comic ? Rock.yellow : "transparent"
                        offset: Rock.comic ? 2 : 0
                        radius: 5
                        padH: 6
                        padV: 1
                        Lbl {
                            text: Rock.comic ? ((popup.setlist.length > 0 && popup.setlist[0].now) ? I18n.t("СЕЙЧАС") : I18n.t("ИГРАЛО"))
                                             : ((popup.setlist.length > 0 && popup.setlist[0].now) ? (Rock.marisa ? "SPELL" : "SIGNAL") : (Rock.marisa ? "GRIMOIRE" : "ARCHIVE"))
                            color: Rock.comic ? Rock.cream : Rock.ink
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 7
                            font.letterSpacing: 0.8
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: popup.setlist
                        delegate: Rectangle {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property bool now: entry.modelData.now === true

                            Layout.fillWidth: true
                            implicitHeight: entry.now ? 42 : 32
                            radius: entry.now ? 10 : 8
                            color: entry.now ? (Rock.comic ? Rock.yellow : Rock.a(Rock.gold, 0.14)) : Rock.uiSurface2
                            border.width: Rock.uiBorder
                            border.color: Rock.uiEdge

                            Rectangle {
                                visible: !Rock.marisa
                                width: 7
                                height: parent.height - 10
                                radius: 3.5
                                anchors.left: parent.left
                                anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                color: entry.now ? (Rock.comic ? Rock.pink : Rock.gold)
                                                 : (Rock.comic ? (entry.index % 2 === 1 ? Rock.cyan : Rock.purple)
                                                               : Rock.a(entry.index % 2 === 1 ? Rock.cyan : Rock.gold, 0.55))
                            }

                            Text {
                                visible: Rock.marisa
                                anchors.left: parent.left
                                anchors.leftMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.now ? "✦" : (entry.index % 2 === 1 ? "✧" : "·")
                                color: entry.now ? Rock.gold : Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.5)
                                font.pixelSize: entry.now ? 12 : 10
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 17
                                anchors.rightMargin: 10
                                spacing: 7

                                Lbl {
                                    Layout.preferredWidth: 20
                                    text: ("0" + (entry.index + 1)).slice(-2)
                                    color: entry.now ? (Rock.comic ? Rock.pinkDeep : Rock.gold) : Rock.uiSub
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 9
                                }
                                Lbl {
                                    Layout.fillWidth: true
                                    text: entry.modelData.title
                                    color: Rock.uiText
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: entry.now ? 11 : 10
                                    elide: Text.ElideRight
                                }
                                Lbl {
                                    visible: entry.modelData.artist !== ""
                                    Layout.maximumWidth: 132
                                    text: entry.modelData.artist
                                    color: Rock.comic ? Rock.pinkDeep : Rock.a(Rock.gold, 0.82)
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                                Lbl {
                                    visible: entry.now
                                    Layout.preferredWidth: 46
                                    horizontalAlignment: Text.AlignRight
                                    text: Media.player ? Fmt.hms(Media.player.length) : "0:00"
                                    color: Rock.uiSub
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    spacing: 8
                    MediaBtn {
                        big: true
                        icon: (Media.playing && Media.player !== null) ? "\uf04c" : "\uf04b"
                        accentColor: Rock.pinkDeep
                        on: Media.playing
                        onActivated: if (Media.player && Media.player.canTogglePlaying) Media.player.togglePlaying()
                    }
                    MediaBtn {
                        sticker: true
                        icon: "\uf048"
                        on: false
                        onActivated: if (Media.player && Media.player.canGoNext) Media.player.next()
                    }
                    MediaBtn {
                        sticker: true
                        icon: "\uf051"
                        on: false
                        onActivated: if (Media.player && Media.player.canGoPrevious) Media.player.previous()
                    }
                    MediaBtn {
                        sticker: true
                        icon: "\uf021"
                        on: loopActive
                        badge: loopBadge()
                        onActivated: cycleLoop()
                    }
                }

                // ── перемотка ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    spacing: 8
                    Lbl {
                        Layout.preferredWidth: 38
                        text: Fmt.clock(Media.player ? Media.player.position : 0)
                        color: Rock.uiSub
                        font.pixelSize: 10
                    }
                    Item {
                        id: seekTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        readonly property real shown: (Media.player && Media.player.length > 0) ? Math.max(0, Math.min(1, (Media.player.position || 0) / Media.player.length)) : 0
                        property real dragV: -1
                        readonly property real shownV: dragV >= 0 ? dragV : shown
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Rock.a(Rock.uiText, 0.16)
                            Rectangle { width: parent.width * seekTrack.shownV; height: parent.height; radius: 3; color: Rock.marisa ? Rock.gold : Rock.pink }
                        }
                        Rectangle {
                            visible: !Rock.marisa
                            width: 10; height: 10; radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * seekTrack.shownV - width / 2))
                            color: Rock.uiText
                        }
                        Text {
                            visible: Rock.marisa
                            text: "✦"
                            color: Rock.gold
                            font.pixelSize: 13
                            y: parent.height / 2 - height / 2
                            x: Math.max(0, Math.min(parent.width - width, parent.width * seekTrack.shownV - width / 2))
                        }
                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function setV(mx) {
                                const r = Math.max(0, Math.min(1, mx / width))
                                seekTrack.dragV = r
                                if (Media.player && Media.player.canSeek && Media.player.length > 0)
                                    Media.player.position = r * Media.player.length
                            }
                            onPressed: m => setV(m.x)
                            onPositionChanged: m => { if (pressed) setV(m.x) }
                            onReleased: { if (seekTrack.dragV >= 0) seekTrack.dragV = -1 }
                        }
                    }
                    Lbl {
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        text: Fmt.hms(Media.player ? Media.player.length : 0)
                        color: Rock.uiSub
                        font.pixelSize: 10
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    spacing: 8
                    Lbl {
                        text: (Media.player && Media.player.volume > 0) ? "\uf028" : "\uf026"
                        color: Rock.uiSub
                        font.pixelSize: 12
                    }
                    Item {
                        id: volTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14
                        readonly property real shown: (Media.player && Media.player.volumeSupported) ? Math.max(0, Math.min(1, Media.player.volume)) : 0
                        property real dragV: -1
                        readonly property real shownV: dragV >= 0 ? dragV : shown
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 7
                            radius: 3.5
                            color: Rock.a(Rock.uiText, 0.16)
                            Rectangle { width: parent.width * volTrack.shownV; height: parent.height; radius: 3.5; color: Rock.marisa ? Rock.gold : Rock.pink }
                        }
                        Rectangle {
                            visible: !Rock.marisa
                            width: 12
                            height: 12
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * volTrack.shownV - width / 2))
                            color: Rock.uiText
                        }
                        Text {
                            visible: Rock.marisa
                            text: "✦"
                            color: Rock.gold
                            font.pixelSize: 14
                            y: parent.height / 2 - height / 2
                            x: Math.max(0, Math.min(parent.width - width, parent.width * volTrack.shownV - width / 2))
                        }
                        MouseArea {
                            id: volArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function setV(mx) {
                                const r = Math.max(0, Math.min(1, mx / width))
                                volTrack.dragV = r
                                Media.setVol(r)
                            }
                            onPressed: m => setV(m.x)
                            onPositionChanged: m => { if (pressed) setV(m.x) }
                            onReleased: { if (volTrack.dragV >= 0) Media.setVol(volTrack.dragV); volTrack.dragV = -1 }
                        }
                    }
                    Lbl {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: Math.round((Media.player ? Media.player.volume : 0) * 100) + "%"
                        color: Rock.uiSub
                        font.pixelSize: 10
                    }
                }

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
                            implicitWidth: chipLbl.implicitWidth + 20
                            implicitHeight: 22
                            radius: 11
                            color: current ? Rock.a(Rock.pink, 0.18) : (chipArea.containsMouse ? Rock.a(Rock.uiText, 0.08) : "transparent")
                            border.width: current ? 2 : 1
                            border.color: current ? Rock.pinkDeep : Rock.a(Rock.uiText, 0.35)
                            Lbl {
                                id: chipLbl
                                anchors.centerIn: parent
                                text: String(chip.modelData.identity).substring(0, 14)
                                color: chip.current ? Rock.pinkDeep : Rock.uiSub
                                font.pixelSize: 10
                                font.bold: chip.current
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

        Rectangle {
            visible: Rock.comic
            x: 22
            y: -6
            width: 74
            height: 18
            radius: 2
            color: Rock.a(Rock.yellow, 0.85)
            border.width: 1
            border.color: Rock.a(Rock.uiText, 0.25)
            rotation: -7
            z: 20
        }
        Rectangle {
            visible: Rock.comic
            x: card.width - 96
            y: -6
            width: 74
            height: 18
            radius: 2
            color: Rock.a(Rock.cyan, 0.7)
            border.width: 1
            border.color: Rock.a(Rock.uiText, 0.25)
            rotation: 6
            z: 20
        }
        Lbl {
            visible: Rock.comic
            x: card.width - 24
            y: card.height - 6
            text: "\uf005"
            color: Rock.yellow
            font.pixelSize: 16
            rotation: 14
            z: 20
        }
    }
}
