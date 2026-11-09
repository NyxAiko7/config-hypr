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

    implicitWidth: 566
    implicitHeight: book.height + 32

    property int sparkFrame: 0
    Timer {
        id: sparkTimer
        interval: 140
        repeat: true
        running: popup.visible && Media.playing
        onTriggered: popup.sparkFrame += 1
    }

    function sparkH(i) {
        const base = (Media.playing && Media.player !== null) ? 18 : 5
        return Math.max(3, base * (0.3 + 0.7 * Math.abs(Math.sin(sparkFrame * 0.6 + i * 1.9))))
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
        if (loopMode === MprisLoopState.Track) return "I"
        if (loopMode === MprisLoopState.Playlist) return "∞"
        return ""
    }

    function roman(n) {
        const r = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        return r[n] || ("0" + (n + 1)).slice(-2)
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
        if (list.length > 4) list.length = 4
        recentTracks = list
    }

    readonly property var spellbook: {
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

    component RuneBtn: Item {
        id: rune
        property string icon: ""
        property bool big: false
        property bool active: false
        property string badge: ""
        signal activated()
        implicitWidth: big ? 50 : 30
        implicitHeight: implicitWidth

        Rectangle {
            anchors.centerIn: parent
            width: rune.big ? parent.width : parent.width
            height: width
            radius: rune.big ? width / 2 : 5
            rotation: rune.big ? 0 : 45
            color: rune.big
                ? (runeArea.containsMouse ? Qt.lighter(Rock.gold, 1.08) : Rock.gold)
                : (runeArea.containsMouse ? Rock.a(Rock.gold, 0.18) : Rock.a(Rock.uiSurface2, 0.55))
            border.width: rune.big ? 2 : 1
            border.color: rune.big ? Rock.uiEdge : Rock.a(Rock.gold, 0.7)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Rectangle {
            visible: rune.big
            anchors.centerIn: parent
            width: parent.width - 8
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Rock.a(Rock.uiEdge, 0.5)
        }

        Lbl {
            anchors.centerIn: parent
            rotation: rune.big ? 0 : -45
            text: rune.icon
            color: rune.big ? Rock.ink : (rune.active ? Rock.gold : Rock.uiText)
            font.pixelSize: rune.big ? 17 : 12
        }

        Rectangle {
            visible: rune.badge !== ""
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -1
            anchors.topMargin: -3
            width: 13
            height: 13
            radius: 7
            color: Rock.pink
            border.width: 1
            border.color: Rock.uiEdge
            Text {
                anchors.centerIn: parent
                text: rune.badge
                color: Rock.cream
                font.pixelSize: 7
                font.bold: true
            }
        }

        MouseArea {
            id: runeArea
            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rune.activated()
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 8

        Rectangle {
            x: 8
            y: 10
            width: book.width
            height: book.height
            radius: 10
            rotation: -1.1
            transformOrigin: Item.Center
            color: Rock.a(Rock.ink, 0.30)
            border.width: 1
            border.color: Rock.a(Rock.ink, 0.35)
        }

        Rectangle {
            id: book
            width: 526
            height: spread.implicitHeight + 36
            radius: 9
            color: Rock.uiSurface
            border.width: 2
            border.color: Rock.uiEdge
            clip: true

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.lighter(Rock.uiSurface, 1.03) }
                GradientStop { position: 0.49; color: Rock.uiSurface }
                GradientStop { position: 0.51; color: Qt.darker(Rock.uiSurface, 1.04) }
                GradientStop { position: 1.0; color: Qt.lighter(Rock.uiSurface, 1.02) }
            }

            MarisaPattern {
                anchors.fill: parent
                opacity: 0.4
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                width: 2
                color: Rock.a(Rock.uiEdge, 0.35)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                width: 8
                color: Rock.a(Rock.uiSurface2, 0.7)
            }

            RowLayout {
                id: spread
                x: 20
                y: 18
                width: parent.width - 40
                spacing: 34

                ColumnLayout {
                    id: leftPage
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Lbl {
                            text: "GRIMOIRE"
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 2.2
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Rock.a(Rock.uiEdge, 0.4) }
                        Lbl {
                            text: "✦ SPELLBOX"
                            color: Rock.a(Rock.gold, 0.9)
                            font.family: Rock.display
                            font.pixelSize: 8
                            font.letterSpacing: 1
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 142
                        Layout.preferredHeight: 142
                        Layout.topMargin: 2

                        MarisaDisc {
                            anchors.fill: parent
                            playing: Media.playing
                            artSource: Media.player ? Media.player.trackArtUrl : ""
                        }
                    }

                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.t("СЕЙЧАС ЗВУЧИТ")
                        color: Rock.a(Rock.uiSub, 0.8)
                        font.pixelSize: 7
                        font.letterSpacing: 1.8
                    }

                    Lbl {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Media.player ? (Media.player.trackTitle || I18n.t("Без названия")) : I18n.t("Тишина в гримуаре")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Lbl {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Media.player ? String(Media.player.trackArtist || "") : ""
                        color: Rock.pinkDeep
                        font.family: Rock.display
                        font.pixelSize: 10
                        font.italic: true
                        elide: Text.ElideRight
                    }

                    Item {
                        id: seek
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        Layout.topMargin: 1

                        readonly property real ratio: (Media.player && Media.player.length > 0)
                            ? Math.max(0, Math.min(1, (Media.player.position || 0) / Media.player.length)) : 0
                        property real drag: -1
                        readonly property real shown: drag >= 0 ? drag : ratio
                        readonly property bool hot: seekArea.containsMouse || seekArea.pressed

                        Repeater {
                            model: 11
                            delegate: Rectangle {
                                required property int index
                                x: parent.width * index / 10 - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                height: index % 5 === 0 ? 9 : 5
                                color: Rock.a(Rock.uiEdge, index % 5 === 0 ? 0.55 : 0.25)
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 2
                            color: Rock.a(Rock.uiText, 0.18)
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * seek.shown
                            height: 3
                            color: Rock.gold
                        }

                        Text {
                            text: "✦"
                            color: Rock.gold
                            font.pixelSize: seek.hot ? 16 : 13
                            y: parent.height / 2 - height / 2
                            x: Math.max(0, Math.min(parent.width - width, parent.width * seek.shown - width / 2))
                            Behavior on font.pixelSize { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function setV(mx) {
                                const r = Math.max(0, Math.min(1, mx / width))
                                seek.drag = r
                                if (Media.player && Media.player.canSeek && Media.player.length > 0)
                                    Media.player.position = r * Media.player.length
                            }
                            onPressed: m => setV(m.x)
                            onPositionChanged: m => { if (pressed) setV(m.x) }
                            onReleased: seek.drag = -1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Lbl {
                            text: Fmt.clock(Media.player ? Media.player.position : 0)
                            color: Rock.uiSub
                            font.pixelSize: 9
                        }
                        Item { Layout.fillWidth: true }
                        Lbl {
                            text: Fmt.hms(Media.player ? Media.player.length : 0)
                            color: Rock.uiSub
                            font.pixelSize: 9
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        Layout.topMargin: 2
                        spacing: 9

                        RuneBtn {
                            icon: "\uf051"
                            onActivated: if (Media.player && Media.player.canGoPrevious) Media.player.previous()
                        }
                        RuneBtn {
                            icon: (Media.playing && Media.player !== null) ? "\uf04c" : "\uf04b"
                            big: true
                            onActivated: if (Media.player && Media.player.canTogglePlaying) Media.player.togglePlaying()
                        }
                        RuneBtn {
                            icon: "\uf048"
                            onActivated: if (Media.player && Media.player.canGoNext) Media.player.next()
                        }
                        RuneBtn {
                            icon: "\uf021"
                            active: popup.loopActive
                            badge: popup.loopBadge()
                            onActivated: popup.cycleLoop()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Layout.topMargin: 3
                        Lbl {
                            text: I18n.t("ЧЕРНИЛА")
                            color: Rock.a(Rock.uiSub, 0.85)
                            font.pixelSize: 7
                            font.letterSpacing: 1.4
                        }
                        Item {
                            id: vol
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            readonly property real shown: Media.player ? Math.max(0, Math.min(1, Media.player.volume)) : 0
                            property real drag: -1
                            readonly property real val: drag >= 0 ? drag : shown

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 2
                                color: Rock.a(Rock.uiText, 0.16)
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * vol.val
                                height: 4
                                color: Rock.pink
                            }
                            Text {
                                text: "◆"
                                color: Rock.pinkDeep
                                font.pixelSize: 10
                                y: parent.height / 2 - height / 2
                                x: Math.max(0, Math.min(parent.width - width, parent.width * vol.val - width / 2))
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                function setV(mx) {
                                    const r = Math.max(0, Math.min(1, mx / width))
                                    vol.drag = r
                                    Media.setVol(r)
                                }
                                onPressed: m => setV(m.x)
                                onPositionChanged: m => { if (pressed) setV(m.x) }
                                onReleased: { if (vol.drag >= 0) Media.setVol(vol.drag); vol.drag = -1 }
                            }
                        }
                        Lbl {
                            Layout.preferredWidth: 30
                            horizontalAlignment: Text.AlignRight
                            text: Math.round((Media.player ? Media.player.volume : 0) * 100) + "%"
                            color: Rock.uiSub
                            font.pixelSize: 9
                        }
                    }
                }

                ColumnLayout {
                    id: rightPage
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Lbl {
                            text: I18n.t("КНИГА ЗАКЛИНАНИЙ")
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.4
                        }
                        Item { Layout.fillWidth: true }
                        Lbl {
                            text: popup.roman(Math.max(0, popup.spellbook.length - 1))
                            color: Rock.a(Rock.gold, 0.8)
                            font.family: Rock.display
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Rock.a(Rock.uiEdge, 0.45)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: popup.spellbook
                            delegate: Rectangle {
                                id: entry
                                required property var modelData
                                required property int index
                                readonly property bool now: entry.modelData.now === true

                                Layout.fillWidth: true
                                implicitHeight: entry.now ? 56 : 40
                                radius: entry.now ? 6 : 4
                                color: entry.now ? Rock.a(Rock.gold, 0.16) : "transparent"
                                border.width: entry.now ? 1 : 0
                                border.color: Rock.a(Rock.gold, 0.6)

                                Rectangle {
                                    visible: entry.now
                                    width: 4
                                    height: parent.height - 10
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Rock.pink
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 9
                                    spacing: 8

                                    Lbl {
                                        Layout.preferredWidth: 22
                                        text: entry.now ? "✦" : popup.roman(entry.index + 1)
                                        color: entry.now ? Rock.gold : Rock.a(Rock.uiSub, 0.75)
                                        font.family: Rock.display
                                        font.pixelSize: entry.now ? 13 : 10
                                        font.bold: entry.now
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        spacing: -2
                                        Lbl {
                                            Layout.fillWidth: true
                                            text: entry.modelData.title
                                            color: Rock.uiText
                                            font.family: Rock.display
                                            font.pixelSize: entry.now ? 12 : 10
                                            font.bold: entry.now
                                            elide: Text.ElideRight
                                        }
                                        Lbl {
                                            Layout.fillWidth: true
                                            visible: entry.modelData.artist !== ""
                                            text: entry.modelData.artist
                                            color: Rock.a(Rock.gold, 0.8)
                                            font.pixelSize: 8
                                            font.italic: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Lbl {
                                        visible: entry.now
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                        text: Media.player ? Fmt.hms(Media.player.length) : "0:00"
                                        color: Rock.uiSub
                                        font.pixelSize: 9
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Lbl {
                            text: I18n.t("ИСКРЫ")
                            color: Rock.a(Rock.uiSub, 0.8)
                            font.pixelSize: 7
                            font.letterSpacing: 1.2
                        }
                        Item { Layout.fillWidth: true }
                        Row {
                            spacing: 3
                            Repeater {
                                model: 5
                                delegate: Item {
                                    required property int index
                                    width: 3
                                    height: 20
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: 3
                                        radius: 1.5
                                        height: popup.sparkH(index)
                                        color: index % 2 === 0 ? Rock.gold : Rock.pinkDeep
                                        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: Media.players.length > 1
                        Lbl {
                            text: I18n.t("ФАМИЛЬЯРЫ")
                            color: Rock.a(Rock.uiSub, 0.8)
                            font.pixelSize: 7
                            font.letterSpacing: 1
                        }
                        Repeater {
                            model: Math.min(2, Media.players.length)
                            delegate: Rectangle {
                                required property int index
                                readonly property var pl: Media.players[index]
                                readonly property bool current: Media.player === pl
                                implicitWidth: famLbl.implicitWidth + 14
                                implicitHeight: 16
                                radius: 3
                                color: current ? Rock.a(Rock.pink, 0.18) : "transparent"
                                border.width: 1
                                border.color: current ? Rock.pinkDeep : Rock.a(Rock.uiEdge, 0.5)
                                Lbl {
                                    id: famLbl
                                    anchors.centerIn: parent
                                    text: pl ? String(pl.identity).substring(0, 8) : ""
                                    color: famLbl.parent.current ? Rock.pinkDeep : Rock.uiSub
                                    font.pixelSize: 7
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Media.pin(famLbl.parent.current && Media.pinned === pl ? null : pl)
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -6
                width: 16
                height: 40
                radius: 2
                color: Rock.pink
                border.width: 1
                border.color: Rock.a(Rock.uiEdge, 0.6)
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -13
                width: 16
                height: 16
                color: Rock.pink
                transform: Rotation { origin.x: 8; origin.y: 0; angle: 45 }
            }
        }

        Lbl {
            anchors.horizontalCenter: book.horizontalCenter
            anchors.top: book.bottom
            anchors.topMargin: 3
            text: "✦"
            color: Rock.gold
            font.pixelSize: 14
        }
    }
}
