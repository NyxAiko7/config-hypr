import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

BarPopup {
    id: cc
    alignment: "right"
    implicitWidth: 388
    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: Rock.uiRadius

    property string page: "main"
    readonly property real maxH: (barWindow.screen ? barWindow.screen.height : 900) - 110
    implicitHeight: page === "main" ? Math.min(content.implicitHeight + 32, maxH)
                                   : (page === "wifi" ? Math.min(600, maxH) : 500)

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var btAdapter: Bluetooth.defaultAdapter
    readonly property string userName: Quickshell.env("USER") || "user"
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property real volume: (sink && sink.audio) ? Math.max(0, Math.min(1, sink.audio.volume)) : 0
    readonly property var upower: UPower.displayDevice

    PwObjectTracker { objects: [cc.sink, cc.source] }

    onVisibleChanged: {
        Net.detailsActive = visible
        if (visible) { Brightness.refresh(); Net.refresh(); Quick.refresh() }
        else page = "main"
    }

    Connections {
        target: UI
        function onWifiSsidChanged() { if (UI.wifiSsid !== "") cc.visible = false }
    }

    function volIcon() {
        if (!sink || !sink.audio || sink.audio.muted) return "\uf026"
        return volume < 0.01 ? "\uf026" : (volume < 0.5 ? "\uf027" : "\uf028")
    }
    function batIcon() {
        const d = cc.upower
        if (!d) return "\uf240"
        if (d.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(d.percentage * 5))]
    }
    function batteryLine() {
        const d = cc.upower
        if (!d || !d.isLaptopBattery) return I18n.t("Питание")
        return Math.round(d.percentage * 100) + "% · "
            + (d.state === UPowerDeviceState.Charging ? I18n.t("заряжается") : I18n.t("от батареи"))
    }

    // ───────── Узел орбиты ─────────
    component Node: Item {
        id: node
        property string icon: ""
        property string label: ""
        property bool active: false
        property color tint: Rock.cyan
        signal activated()

        implicitWidth: 62
        implicitHeight: 64
        width: implicitWidth
        height: implicitHeight
        scale: nodeArea.containsMouse ? 1.05 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Rectangle {
            id: halo
            anchors.horizontalCenter: parent.horizontalCenter
            width: 50
            height: 50
            radius: 25
            color: node.active ? Rock.a(node.tint, 0.18) : Rock.a(Rock.uiSurface2, 0.35)
            border.width: 1
            border.color: node.active ? node.tint : Rock.a(Rock.uiEdge, 0.45)
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Rock.a(node.active ? node.tint : Rock.uiEdge, 0.35)
            }

            Lbl {
                anchors.centerIn: parent
                text: node.icon
                color: node.active ? node.tint : Rock.uiSub
                font.pixelSize: 16
            }

            Rectangle {
                visible: node.active
                width: 6
                height: 6
                radius: 3
                color: node.tint
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 7
            }
        }

        Lbl {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: halo.bottom
            anchors.topMargin: 3
            text: node.label
            color: node.active ? Rock.uiText : Rock.a(Rock.uiSub, 0.8)
            font.pixelSize: 7
            font.letterSpacing: 0.7
        }

        MouseArea {
            id: nodeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: node.activated()
        }
    }

    // ───────── Канал (ползунок со шкалой) ─────────
    component Channel: Item {
        id: ch
        property string icon: ""
        property string label: ""
        property real value: 0
        property color tint: Rock.pink
        signal moved(real v)
        signal iconClicked()

        implicitHeight: 40

        RowLayout {
            anchors.fill: parent
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 27
                Layout.preferredHeight: 27
                radius: 14
                color: Rock.a(ch.tint, 0.14)
                border.width: 1
                border.color: Rock.a(ch.tint, 0.6)
                Lbl {
                    anchors.centerIn: parent
                    text: ch.icon
                    color: ch.tint
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ch.iconClicked()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    Lbl {
                        Layout.fillWidth: true
                        text: ch.label
                        color: Rock.a(Rock.uiSub, 0.85)
                        font.pixelSize: 7
                        font.letterSpacing: 1.3
                    }
                    Lbl {
                        text: Math.round(ch.value * 100)
                        color: Rock.uiText
                        font.family: Rock.display
                        font.pixelSize: 10
                        font.weight: Font.Black
                    }
                }

                Item {
                    id: track
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    readonly property bool hot: area.containsMouse || area.pressed
                    readonly property real shown: Math.max(0, Math.min(1, ch.value))

                    Repeater {
                        model: 11
                        delegate: Rectangle {
                            required property int index
                            x: track.width * index / 10 - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: index % 5 === 0 ? 7 : 4
                            color: Rock.a(Rock.uiEdge, index % 5 === 0 ? 0.55 : 0.25)
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 2
                        color: Rock.a(Rock.uiText, 0.16)
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: track.width * track.shown
                        height: track.hot ? 5 : 3
                        color: ch.tint
                        Behavior on height { NumberAnimation { duration: 100 } }
                    }

                    Rectangle {
                        width: track.hot ? 10 : 8
                        height: width
                        rotation: 45
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(track.width - width, track.width * track.shown - width / 2))
                        color: ch.tint
                        border.width: 1
                        border.color: Rock.uiSurface
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function setV(mx) { ch.moved(Math.max(0, Math.min(1, mx / width))) }
                        onPressed: m => setV(m.x)
                        onPositionChanged: m => { if (pressed) setV(m.x) }
                    }
                }
            }
        }
    }

    component MicroBtn: Rectangle {
        id: mb
        property string icon: ""
        property bool big: false
        signal activated()

        implicitWidth: big ? 30 : 25
        implicitHeight: implicitWidth
        radius: width / 2
        color: big ? Rock.pink : (mbArea.containsMouse ? Rock.a(Rock.pink, 0.16) : "transparent")
        border.width: big ? 0 : 1
        border.color: Rock.a(Rock.uiEdge, mbArea.containsMouse ? 0.7 : 0.25)
        Behavior on color { ColorAnimation { duration: 120 } }

        Lbl {
            anchors.centerIn: parent
            text: mb.icon
            color: mb.big ? Rock.uiOnActive : (mbArea.containsMouse ? Rock.uiText : Rock.uiSub)
            font.pixelSize: mb.big ? 13 : 11
        }

        MouseArea {
            id: mbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.activated()
        }
    }

    // ───────── Компактный плеер ─────────
    component MediaStrip: Item {
        id: strip
        readonly property var p: Media.player
        readonly property real ratio: (p && p.length > 0)
            ? Math.max(0, Math.min(1, p.position / p.length)) : 0

        visible: p !== null
        implicitHeight: visible ? 58 : 0

        Timer {
            running: strip.visible && Media.playing
            interval: 1000
            repeat: true
            onTriggered: if (Media.player) Media.player.positionChanged()
        }

        Rectangle {
            anchors.fill: parent
            radius: Rock.uiRadiusSm
            color: Rock.uiSurface2
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                anchors.topMargin: 7
                anchors.bottomMargin: 10
                spacing: 9

                Item {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        color: Rock.a(Rock.pink, 0.12)
                        border.width: 1
                        border.color: Rock.a(Rock.uiEdge, 0.6)
                    }
                    Image {
                        id: cover
                        anchors.fill: parent
                        anchors.margins: 2
                        source: Media.trackArtUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Lbl {
                        anchors.centerIn: parent
                        visible: !cover.visible
                        text: "\uf001"
                        color: Rock.uiSub
                        font.pixelSize: 12
                    }
                    RoundMask {
                        anchors.fill: parent
                        anchors.margins: 2
                        visible: cover.visible
                        radius: 9
                        maskColor: Rock.uiSurface2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 0
                    Lbl {
                        Layout.fillWidth: true
                        text: Media.trackTitle || I18n.t("Без названия")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: Media.trackArtist
                        color: Rock.pinkDeep
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                MicroBtn {
                    icon: "\uf048"
                    onActivated: if (strip.p && strip.p.canGoPrevious) strip.p.previous()
                }
                MicroBtn {
                    big: true
                    icon: Media.playing ? "\uf04c" : "\uf04b"
                    onActivated: if (strip.p && strip.p.canTogglePlaying) strip.p.togglePlaying()
                }
                MicroBtn {
                    icon: "\uf051"
                    onActivated: if (strip.p && strip.p.canGoNext) strip.p.next()
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                color: Rock.a(Rock.uiText, 0.10)

                Rectangle {
                    width: parent.width * strip.ratio
                    height: parent.height
                    color: Rock.pink
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    // ───────── Панель ссылок на подробности ─────────
    component PageLink: Rectangle {
        id: link
        property string label
        signal picked()

        implicitWidth: linkLbl.implicitWidth + 22
        implicitHeight: 21
        radius: 4
        color: linkArea.containsMouse ? Rock.a(Rock.pink, 0.14) : "transparent"
        border.width: 1
        border.color: Rock.a(Rock.uiEdge, linkArea.containsMouse ? 0.9 : 0.5)
        Behavior on color { ColorAnimation { duration: 120 } }

        Lbl {
            id: linkLbl
            anchors.centerIn: parent
            text: "› " + link.label
            color: linkArea.containsMouse ? Rock.uiText : Rock.a(Rock.uiSub, 0.9)
            font.pixelSize: 7
            font.letterSpacing: 1.1
        }
        MouseArea {
            id: linkArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.picked()
        }
    }

    Flickable {
        id: mainScroll
        visible: cc.page === "main"
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: mainScroll.width
            spacing: 13

            // ── Шапка ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Rock.a(Rock.pink, 0.10)
                        border.width: 1
                        border.color: Rock.a(Rock.pink, 0.45)
                    }
                    Avatar {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        source: PanelConfig.avatarUrl
                        letter: cc.userName.charAt(0).toUpperCase()
                        bg: Rock.pink
                        fg: Rock.uiOnActive
                        borderWidth: 1
                        borderColor: Rock.a(Rock.uiEdge, 0.6)
                        fontFamily: Rock.display
                        fontWeight: Font.Black
                        fontSize: 15
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: -1
                    Lbl {
                        Layout.fillWidth: true
                        text: I18n.t("ЦЕНТР УПРАВЛЕНИЯ")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 15
                        font.letterSpacing: 0.4
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: "ORBITAL CONTROL · " + cc.userName.toUpperCase()
                        color: Rock.pinkDeep
                        font.pixelSize: 7
                        font.weight: Font.Black
                        font.letterSpacing: 1.5
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 4
                        Lbl {
                            visible: cc.upower && cc.upower.isLaptopBattery
                            text: cc.batIcon()
                            color: (cc.upower && cc.upower.percentage < 0.2) ? Rock.pinkDeep : Rock.uiSub
                            font.pixelSize: 10
                        }
                        Lbl {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: Rock.a(Rock.uiSub, 0.75)
                            font.pixelSize: 8
                            text: cc.batteryLine()
                        }
                    }
                }

                IconBtn {
                    size: 29
                    icon: "\uf013"
                    iconColor: Rock.uiSub
                    hoverColor: Rock.a(Rock.uiText, 0.10)
                    onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.wallpaper = false; UI.settings = true }
                }
                IconBtn {
                    size: 29
                    icon: "\uf1fc"
                    iconColor: Rock.uiSub
                    hoverColor: Rock.a(Rock.uiText, 0.10)
                    onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.settings = false; UI.wallpaper = true }
                }
                IconBtn {
                    size: 29
                    icon: "\uf011"
                    iconColor: Rock.uiSub
                    hoverColor: Rock.a(Rock.uiText, 0.10)
                    onClicked: { cc.visible = false; UI.launcher = false; UI.wallpaper = false; UI.session = true }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Rock.a(Rock.uiEdge, 0.4)
            }

            // ── Орбита переключателей ──
            Item {
                id: orbit
                Layout.fillWidth: true
                Layout.preferredHeight: 244

                readonly property real cx: width / 2
                readonly property real cy: 112
                readonly property real ringR: Math.min(88, width * 0.255)

                Canvas {
                    id: rings
                    anchors.fill: parent
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    Connections {
                        target: Theme
                        function onAccentChanged() { rings.requestPaint() }
                        function onTextChanged() { rings.requestPaint() }
                    }
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const cx = orbit.cx, cy = orbit.cy, r = orbit.ringR

                        ctx.lineWidth = 1
                        ctx.strokeStyle = Rock.a(Rock.uiEdge, 0.5)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.stroke()

                        ctx.strokeStyle = Rock.a(Rock.uiEdge, 0.22)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r * 0.72, 0, Math.PI * 2)
                        ctx.stroke()

                        ctx.strokeStyle = Rock.a(Rock.uiText, 0.18)
                        for (let i = 0; i < 60; i++) {
                            const a = i * Math.PI * 2 / 60
                            const r1 = r * (i % 5 === 0 ? 0.90 : 0.95)
                            ctx.beginPath()
                            ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                            ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
                            ctx.stroke()
                        }

                        ctx.strokeStyle = Rock.a(Rock.pink, 0.55)
                        ctx.lineWidth = 1.5
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 0.36)
                        ctx.stroke()

                        ctx.strokeStyle = Rock.a(Rock.pink, 0.22)
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, Math.PI * 0.62, Math.PI * 1.12)
                        ctx.stroke()
                    }
                }

                // центральное ядро: громкость
                Item {
                    id: core
                    width: 86
                    height: 86
                    x: orbit.cx - width / 2
                    y: orbit.cy - height / 2

                    Canvas {
                        id: coreArc
                        anchors.fill: parent
                        readonly property real level: cc.volume
                        readonly property bool muted: cc.sink && cc.sink.audio ? cc.sink.audio.muted : false
                        onLevelChanged: requestPaint()
                        onMutedChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        Connections {
                            target: Theme
                            function onAccentChanged() { coreArc.requestPaint() }
                        }
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const c = width / 2, r = c - 3
                            ctx.lineWidth = 2
                            ctx.strokeStyle = Rock.a(Rock.uiEdge, 0.45)
                            ctx.beginPath()
                            ctx.arc(c, c, r, 0, Math.PI * 2)
                            ctx.stroke()

                            if (!muted && level > 0.001) {
                                ctx.strokeStyle = Rock.pink
                                ctx.lineCap = "round"
                                ctx.lineWidth = 3
                                ctx.beginPath()
                                ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + level * Math.PI * 2)
                                ctx.stroke()
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: width / 2
                        color: coreArea.containsMouse ? Rock.uiHover : Rock.uiSurface2
                        border.width: 1
                        border.color: Rock.a(Rock.uiEdge, 0.7)
                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: -2
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: cc.volIcon()
                            color: (cc.sink && cc.sink.audio && cc.sink.audio.muted) ? Rock.pinkDeep : Rock.uiSub
                            font.pixelSize: 9
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: Math.round(cc.volume * 100)
                            color: Rock.uiText
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 19
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: (cc.sink && cc.sink.audio && cc.sink.audio.muted) ? "MUTE" : "VOL"
                            color: Rock.a(Rock.uiSub, 0.8)
                            font.pixelSize: 6
                            font.letterSpacing: 1.4
                        }
                    }

                    MouseArea {
                        id: coreArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (cc.sink && cc.sink.audio) cc.sink.audio.muted = !cc.sink.audio.muted
                    }

                    WheelHandler {
                        onWheel: w => {
                            if (!cc.sink || !cc.sink.audio || w.angleDelta.y === 0) return
                            cc.sink.audio.volume = Math.max(0, Math.min(1, cc.volume + (w.angleDelta.y > 0 ? 0.02 : -0.02)))
                            w.accepted = true
                        }
                    }
                }

                Node {
                    x: orbit.cx + Math.cos(-Math.PI / 2) * orbit.ringR - width / 2
                    y: orbit.cy + Math.sin(-Math.PI / 2) * orbit.ringR - 25
                    icon: Net.icon
                    label: Net.kind === "ethernet" ? "ETHERNET" : "WI-FI"
                    active: Net.wifiEnabled || Net.kind === "ethernet"
                    tint: Rock.cyan
                    onActivated: Net.toggleWifi()
                }
                Node {
                    x: orbit.cx + Math.cos(-Math.PI / 6) * orbit.ringR - width / 2
                    y: orbit.cy + Math.sin(-Math.PI / 6) * orbit.ringR - 25
                    icon: "\uf293"
                    label: "BLUETOOTH"
                    active: cc.btAdapter ? cc.btAdapter.enabled : false
                    tint: Rock.cyan
                    onActivated: if (cc.btAdapter) cc.btAdapter.enabled = !cc.btAdapter.enabled
                }
                Node {
                    x: orbit.cx + Math.cos(Math.PI / 6) * orbit.ringR - width / 2
                    y: orbit.cy + Math.sin(Math.PI / 6) * orbit.ringR - 25
                    icon: "\uf186"
                    label: I18n.t("НОЧНОЙ")
                    active: Quick.night
                    tint: Rock.purple
                    onActivated: Quick.toggleNight()
                }
                Node {
                    x: orbit.cx + Math.cos(Math.PI / 2) * orbit.ringR - width / 2
                    y: orbit.cy + Math.sin(Math.PI / 2) * orbit.ringR - 25
                    icon: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                    label: I18n.t("ТИШИНА")
                    active: Notifs.dnd
                    tint: Rock.pink
                    onActivated: Notifs.dnd = !Notifs.dnd
                }
                Node {
                    x: orbit.cx + Math.cos(Math.PI * 5 / 6) * orbit.ringR - width / 2
                    y: orbit.cy + Math.sin(Math.PI * 5 / 6) * orbit.ringR - 25
                    icon: "\uf132"
                    label: "VPN"
                    active: Net.vpn
                    tint: Rock.pink
                    onActivated: Net.toggleVpn()
                }
                Node {
                    x: orbit.cx + Math.cos(Math.PI * 7 / 6) * orbit.ringR - width / 2
                    y: orbit.cy + Math.sin(Math.PI * 7 / 6) * orbit.ringR - 25
                    icon: "\uf0f4"
                    label: I18n.t("НЕ СПАТЬ")
                    active: UI.caffeine
                    tint: Rock.gold
                    onActivated: {
                        UI.caffeine = !UI.caffeine
                        UI.flash("\uf0f4", I18n.t("Не засыпать"), UI.caffeine ? I18n.t("Включено") : I18n.t("Выключено"), "", "info", "")
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                PageLink { label: I18n.t("СЕТЬ"); onPicked: cc.page = "wifi" }
                PageLink { label: I18n.t("СИГНАЛ"); onPicked: cc.page = "bt" }
                PageLink { label: I18n.t("ЗВУК"); onPicked: cc.page = "audio" }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Rock.a(Rock.uiEdge, 0.4)
            }

            // ── Плеер ──
            MediaStrip { Layout.fillWidth: true }

            // ── Каналы ──
            Channel {
                Layout.fillWidth: true
                icon: cc.volIcon()
                label: I18n.t("ГРОМКОСТЬ")
                value: cc.volume
                tint: Rock.pink
                onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v }
                onIconClicked: if (cc.sink && cc.sink.audio) cc.sink.audio.muted = !cc.sink.audio.muted
            }
            Channel {
                Layout.fillWidth: true
                visible: Brightness.available
                icon: "\uf185"
                label: I18n.t("СВЕТ")
                value: Brightness.value
                tint: Rock.gold
                onMoved: v => Brightness.set(v)
            }

            // ── Микрофон ──
            RowLayout {
                Layout.fillWidth: true
                visible: cc.source !== null
                spacing: 8

                Lbl {
                    text: cc.micMuted ? "\uf131" : "\uf130"
                    color: cc.micMuted ? Rock.pinkDeep : Rock.uiSub
                    font.pixelSize: 11
                }
                Lbl {
                    Layout.fillWidth: true
                    text: cc.micMuted ? I18n.t("Микрофон заглушён") : I18n.t("Микрофон открыт")
                    color: Rock.a(Rock.uiSub, 0.85)
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 20
                    radius: 4
                    color: micArea.containsMouse ? Rock.a(Rock.uiText, 0.08) : "transparent"
                    border.width: 1
                    border.color: Rock.a(Rock.uiEdge, 0.5)
                    Lbl {
                        anchors.centerIn: parent
                        text: cc.micMuted ? I18n.t("ОТКРЫТЬ") : I18n.t("ЗАГЛУШИТЬ")
                        color: Rock.uiSub
                        font.pixelSize: 7
                        font.letterSpacing: 0.6
                    }
                    MouseArea {
                        id: micArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (cc.source && cc.source.audio) cc.source.audio.muted = !cc.source.audio.muted
                    }
                }
            }
        }
    }

    // ───────── Подстраницы ─────────
    WifiPage {
        anchors.fill: parent
        anchors.margins: 16
        visible: cc.page === "wifi"
        active: cc.visible && cc.page === "wifi"
        onBack: cc.page = "main"
    }
    BtPage {
        anchors.fill: parent
        anchors.margins: 16
        visible: cc.page === "bt"
        active: cc.visible && cc.page === "bt"
        onBack: cc.page = "main"
    }
    AudioPage {
        anchors.fill: parent
        anchors.margins: 16
        visible: cc.page === "audio"
        active: cc.visible && cc.page === "audio"
        onBack: cc.page = "main"
    }
}
