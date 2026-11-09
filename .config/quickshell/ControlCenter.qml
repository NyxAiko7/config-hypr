import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

BarPopup {
    id: cc
    alignment: "right"
    implicitWidth: 396
    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: Rock.comic ? 22 : Rock.marisa ? 8 : Rock.sao ? 4 : 18

    property string page: "main"      // "main" | "wifi" | "bt" | "audio"
    readonly property real maxH: (barWindow.screen ? barWindow.screen.height : 900) - 110
    implicitHeight: page === "main" ? Math.min(content.implicitHeight + 32, maxH)
                                   : (page === "wifi" ? Math.min(600, maxH) : 500)

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btConnectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string userName: Quickshell.env("USER") || "user"
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    PwObjectTracker { objects: [cc.sink, cc.source] }

    onVisibleChanged: {
        SysStats.active = visible
        Net.detailsActive = visible
        if (visible) { Brightness.refresh(); Net.refresh(); Quick.refresh() }
        else page = "main"
    }

    // при запросе пароля закрываем меню
    Connections {
        target: UI
        function onWifiSsidChanged() { if (UI.wifiSsid !== "") cc.visible = false }
    }

    function volIcon() {
        if (!sink || !sink.audio || sink.audio.muted) return "\uf026"
        const v = sink.audio.volume
        return v < 0.01 ? "\uf026" : (v < 0.5 ? "\uf027" : "\uf028")
    }
    function sinkGlyph() {
        const s = sink ? (String(sink.name) + " " + String(sink.description)).toLowerCase() : ""
        if (s.indexOf("headphone") >= 0 || s.indexOf("headset") >= 0 || s.indexOf("bluez") >= 0) return "\uf025"
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return "\uf108"
        return "\uf028"
    }
    function etaText() {
        const d = UPower.displayDevice
        const sec = d.state === UPowerDeviceState.Charging ? d.timeToFull : d.timeToEmpty
        if (!sec || sec <= 0) return ""
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60)
        return " (" + (h > 0 ? h + I18n.t(" ч ") : "") + m + I18n.t(" мин)")
    }
    function powerText() {
        const d = UPower.displayDevice
        const w = Math.abs(d.changeRate)
        let t = w >= 0.5 ? " · " + w.toFixed(1) + I18n.t(" Вт") : ""
        if (d.healthSupported && d.healthPercentage > 0) t += I18n.t(" · здоровье ") + Math.round(d.healthPercentage) + "%"
        return t
    }
    function batIcon() {
        const d = UPower.displayDevice
        if (d.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(d.percentage * 5))]
    }

    // ───────── Плитка ─────────
    component Tile: Item {
        id: tile
        property string icon
        property string title
        property string subtitle
        property bool active: false
        property bool expandable: false
        signal clicked()
        signal rightClicked()
        signal expand()

        implicitHeight: 68

        Rectangle {
            visible: Rock.comic
            x: 4
            y: 4
            width: tile.width - 4
            height: tile.height - 4
            radius: Rock.comic ? 16 : Rock.sao ? 4 : 16
            color: Rock.pink
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
        }

        Rectangle {
            id: card
            width: tile.width - 4
            height: tile.height - 4
            radius: Rock.comic ? 16 : Rock.sao ? 4 : 16
            color: tile.active
                ? (tileArea.containsMouse ? Qt.lighter(Rock.uiActive, 1.06) : Rock.uiActive)
                : (tileArea.containsMouse ? Rock.uiHover : Rock.uiSurface)
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            Behavior on color { ColorAnimation { duration: 140 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: tile.expandable ? 32 : 10
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 10
                    rotation: Rock.comic ? -4 : 0
                    color: tile.active ? Rock.pink : Rock.cyan
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                    Lbl {
                        anchors.centerIn: parent
                        text: tile.icon
                        color: tile.active ? (Rock.comic || Rock.marisa ? Rock.cream : Rock.ink) : Rock.ink
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 15
                        rotation: Rock.comic ? 4 : 0
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 0
                    Lbl {
                        Layout.fillWidth: true
                        text: tile.title
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: tile.subtitle
                        font.pixelSize: 10
                        color: Rock.uiSub
                        opacity: 0.66
                        elide: Text.ElideRight
                    }
                }
            }
            MouseArea {
                id: tileArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
            }
        }

        Rectangle {
            visible: tile.expandable
            anchors.right: card.right
            anchors.rightMargin: 5
            anchors.verticalCenter: card.verticalCenter
            width: 24; height: 24; radius: 12
            color: chevArea.containsMouse ? Rock.a(Rock.uiText, 0.12) : "transparent"
            border.width: chevArea.containsMouse ? 1.5 : 0
            border.color: Rock.uiEdge
            Lbl {
                anchors.centerIn: parent
                text: "\uf054"
                color: Rock.uiText
                font.pixelSize: 9
            }
            MouseArea {
                id: chevArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.expand()
            }
        }
    }

    // ───────── Толстый ползунок ─────────
    component Slide: Item {
        id: sl
        property string icon
        property real value: 0
        property color shadowColor: Rock.cyan
        signal moved(real v)
        signal iconClicked()
        implicitHeight: 46

        Rectangle {
            visible: Rock.comic
            x: 3
            y: 4
            width: sl.width - 3
            height: 42
            radius: 21
            color: sl.shadowColor
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
        }

        Rectangle {
            id: track
            width: sl.width - 3
            height: 42
            radius: 21
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            clip: true

            Rectangle {
                width: track.height + (track.width - track.height) * Math.max(0, Math.min(1, sl.value))
                height: track.height
                radius: height / 2
                color: Rock.pink
            }
            Lbl {
                anchors.verticalCenter: parent.verticalCenter
                x: (track.height - width) / 2
                text: sl.icon
                color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                font.pixelSize: 15
            }
            Lbl {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 16
                text: Math.round(sl.value * 100)
                color: Rock.uiText
                font.family: Rock.display
                font.weight: Font.Black
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function setFrom(mx) {
                    sl.moved(Math.max(0, Math.min(1, (mx - height / 2) / (width - height))))
                }
                onPressed: m => setFrom(m.x)
                onPositionChanged: m => setFrom(m.x)
            }
            MouseArea {
                width: track.height
                height: track.height
                cursorShape: Qt.PointingHandCursor
                onClicked: sl.iconClicked()
            }
        }
    }

    // ───────── Кнопка быстрого действия ─────────
    component QuickBtn: Item {
        id: qb
        property string icon
        property string label
        property bool active: false
        signal activated()
        implicitHeight: 60

        Rectangle {
            visible: Rock.comic
            x: 3
            y: 4
            width: qb.width - 3
            height: qb.height - 4
            radius: 14
            color: Rock.pink
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
        }

        Rectangle {
            id: card
            width: qb.width - 3
            height: qb.height - 4
            radius: 14
            color: qb.active
                ? (qArea.containsMouse ? Qt.lighter(Rock.uiActive, 1.06) : Rock.uiActive)
                : (qArea.containsMouse ? Rock.uiHover : Rock.uiSurface)
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            Behavior on color { ColorAnimation { duration: 140 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: qb.icon
                    color: qb.active ? Rock.pinkDeep : Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 15
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: qb.label
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 8
                }
            }
            MouseArea {
                id: qArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: qb.activated()
            }
        }
    }

    // ───────── Карточка статистики ─────────
    component Stat: Item {
        id: st
        property string label
        property int value: 0
        property string sub: ""
        implicitHeight: 70

        Rectangle {
            visible: Rock.comic
            x: 3
            y: 4
            width: st.width - 3
            height: st.height - 4
            radius: 14
            color: Rock.cyan
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
        }

        Rectangle {
            id: card
            width: st.width - 3
            height: st.height - 4
            radius: 14
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Lbl {
                        text: st.label
                        color: Rock.uiSub
                        font.pixelSize: 9
                        font.weight: Font.Black
                        font.letterSpacing: 0.8
                        Layout.fillWidth: true
                    }
                    Lbl {
                        text: st.sub
                        color: Rock.pinkDeep
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        visible: st.sub !== ""
                    }
                }
                Lbl {
                    text: st.value + "%"
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 18
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 5
                    radius: 2.5
                    color: Rock.a(Rock.uiText, 0.14)
                    border.width: 1
                    border.color: Rock.a(Rock.uiText, 0.3)
                    Rectangle {
                        width: (parent.width - 2) * Math.min(1, st.value / 100)
                        height: parent.height - 2
                        anchors.left: parent.left
                        anchors.leftMargin: 1
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                        color: st.value > 85 ? Rock.orange : Rock.cyan
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    // ───────── Главная страница (прокручивается, если не помещается) ─────────
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
            spacing: 14

            // ── Шапка ──
            Item {
                Layout.fillWidth: true
                implicitHeight: headCard.height + 6

                Rectangle {
                    visible: Rock.comic
                    x: 4
                    y: 5
                    width: headCard.width
                    height: headCard.height
                    radius: Rock.comic ? 16 : Rock.sao ? 4 : 16
                    color: Rock.pink
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                }

                Rectangle {
                    id: headCard
                    width: parent.width - 4
                    height: 70
                    radius: Rock.comic ? 16 : Rock.sao ? 4 : 16
                    color: Rock.uiSurface2
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                }

                Canvas {
                    width: 96
                    height: 56
                    anchors.right: headCard.right
                    anchors.top: headCard.top
                    opacity: 0.16
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = Rock.pinkDeep
                        for (let y = 5; y < height; y += 7)
                            for (let x = 5; x < width; x += 7) {
                                ctx.beginPath()
                                ctx.arc(x, y, 1.1, 0, Math.PI * 2)
                                ctx.fill()
                            }
                    }
                }

                RowLayout {
                    anchors.fill: headCard
                    anchors.margins: 10
                    spacing: 10

                    Avatar {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        rotation: Rock.comic ? -5 : 0

                        source: PanelConfig.avatarUrl
                        letter: cc.userName.charAt(0).toUpperCase()
                        bg: Rock.pink
                        fg: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                        borderWidth: Rock.uiBorder
                        borderColor: Rock.uiEdge
                        fontFamily: Rock.display
                        fontWeight: Font.Black
                        fontSize: 18
                        textRotation: Rock.comic ? 5 : 0
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
                            font.letterSpacing: 0.3
                            elide: Text.ElideRight
                        }
                        Lbl {
                            Layout.fillWidth: true
                            text: (Rock.comic ? "KESSOKU CONTROL" : Rock.marisa ? "GRIMOIRE CONTROL" : Rock.sao ? "SYSTEM CONTROL" : "ASTRAL CONTROL") + " · " + cc.userName
                            color: Rock.pinkDeep
                            font.pixelSize: 8
                            font.weight: Font.Black
                            font.letterSpacing: 1.2
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 4
                            Lbl {
                                visible: UPower.displayDevice.isLaptopBattery
                                text: cc.batIcon()
                                color: UPower.displayDevice.percentage < 0.2 ? Rock.pinkDeep : Rock.uiSub
                                font.pixelSize: 10
                            }
                            Lbl {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: Rock.uiSub
                                opacity: 0.72
                                font.pixelSize: 9
                                text: (UPower.displayDevice.isLaptopBattery
                                        ? Math.round(UPower.displayDevice.percentage * 100) + "% · "
                                          + (UPower.displayDevice.state === UPowerDeviceState.Charging ? I18n.t("заряжается") : I18n.t("от батареи")) + cc.etaText() + cc.powerText() + " · "
                                        : "")
                                    + I18n.t("работает ") + SysStats.uptimeText
                            }
                        }
                    }

                    IconBtn {
                        size: 30
                        icon: "\uf013"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(Rock.uiText, 0.12)
                        onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.wallpaper = false; UI.settings = true }
                    }
                    IconBtn {
                        size: 30
                        icon: "\uf1fc"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(Rock.uiText, 0.12)
                        onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.settings = false; UI.wallpaper = true }
                    }
                    Rectangle {
                        implicitWidth: 30; implicitHeight: 30; radius: 15
                        color: pwrArea.containsMouse ? Rock.a(Rock.uiText, 0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Lbl { anchors.centerIn: parent; text: "\uf011"; color: Rock.uiSub; font.pixelSize: 14 }
                        MouseArea {
                            id: pwrArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { cc.visible = false; UI.launcher = false; UI.session = true }
                        }
                    }
                }
            }

            // ── Плитки ──
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Net.icon
                    title: Net.kind === "ethernet" ? "Ethernet" : "Wi-Fi"
                    subtitle: Net.kind === "ethernet" ? I18n.t("Подключено")
                            : (Net.connected ? Net.connection : (Net.wifiEnabled ? I18n.t("Не подключено") : I18n.t("Выключено")))
                    active: Net.wifiEnabled || Net.kind === "ethernet"
                    onClicked: Net.toggleWifi()
                    expandable: true
                    onExpand: cc.page = "wifi"
                    onRightClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "\uf293"
                    title: "Bluetooth"
                    subtitle: !cc.btAdapter ? I18n.t("Недоступно")
                        : (cc.btAdapter.enabled
                            ? (cc.btConnectedDevices.length > 0
                                ? cc.btConnectedDevices.map(d => d.name || d.deviceName).join(", ")
                                : I18n.t("Включён"))
                            : I18n.t("Выключен"))
                    active: cc.btAdapter ? cc.btAdapter.enabled : false
                    onClicked: if (cc.btAdapter) cc.btAdapter.enabled = !cc.btAdapter.enabled
                    expandable: true
                    onExpand: cc.page = "bt"
                    onRightClicked: Quickshell.execDetached(["blueman-manager"])
                }
                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                    title: I18n.t("Тишина")
                    subtitle: Notifs.dnd ? I18n.t("Не беспокоить") : I18n.t("Уведомления")
                    active: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                    onRightClicked: UI.toggleCenter()
                }
                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "\uf0f4"
                    title: I18n.t("Не засыпать")
                    subtitle: UI.caffeine ? I18n.t("Экран не гаснет") : I18n.t("Выключено")
                    active: UI.caffeine
                    onClicked: {
                        UI.caffeine = !UI.caffeine
                        UI.flash("\uf0f4", I18n.t("Не засыпать"), UI.caffeine ? I18n.t("Включено") : I18n.t("Выключено"), "", "info", "")
                    }
                }
            }

            // ── Музыка ──
            Item {
                Layout.fillWidth: true
                visible: mediaCard.visible
                implicitHeight: mediaCard.visible ? mediaCard.height + 5 : 0

                Rectangle {
                    visible: Rock.comic
                    x: 4
                    y: 5
                    width: mediaCard.width
                    height: mediaCard.height
                    radius: 18
                    color: Rock.pink
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                }

                MediaCard {
                    id: mediaCard
                    width: parent.width - 4
                    active: cc.visible && cc.page === "main"
                }
            }

            // ── Ползунки ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Slide {
                    Layout.fillWidth: true
                    icon: cc.volIcon()
                    value: (cc.sink && cc.sink.audio) ? cc.sink.audio.volume : 0
                    onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v }
                    onIconClicked: if (cc.sink && cc.sink.audio) cc.sink.audio.muted = !cc.sink.audio.muted
                }
                Slide {
                    Layout.fillWidth: true
                    visible: Brightness.available
                    icon: "\uf185"
                    value: Brightness.value
                    shadowColor: Rock.yellow
                    onMoved: v => Brightness.set(v)
                }

                // устройство вывода + микрофон
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 48

                    Rectangle {
                        visible: Rock.comic
                        x: 3
                        y: 4
                        width: parent.width - 3
                        height: 44
                        radius: Rock.comic ? 16 : Rock.sao ? 4 : 16
                        color: Rock.cyan
                        border.width: Rock.uiBorder
                        border.color: Rock.uiEdge
                    }

                    Rectangle {
                        id: audioCard
                        width: parent.width - 3
                        height: 44
                        radius: Rock.comic ? 16 : Rock.sao ? 4 : 16
                        color: audioArea.containsMouse ? Rock.uiHover : Rock.uiSurface
                        border.width: Rock.uiBorder
                        border.color: Rock.uiEdge
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: audioArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.page = "audio"
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            spacing: 10
                            Lbl { text: cc.sinkGlyph(); color: Rock.pinkDeep; font.pixelSize: 14; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignHCenter }
                            Lbl {
                                Layout.fillWidth: true
                                text: cc.sink ? (cc.sink.description || cc.sink.nickname || cc.sink.name) : I18n.t("Нет устройства вывода")
                                color: Rock.uiSub
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            IconBtn {
                                size: 30
                                visible: cc.source !== null
                                icon: cc.micMuted ? "\uf131" : "\uf130"
                                iconColor: cc.micMuted ? Rock.pinkDeep : Rock.uiSub
                                hoverColor: Rock.a(Rock.uiText, 0.1)
                                onClicked: if (cc.source && cc.source.audio) cc.source.audio.muted = !cc.source.audio.muted
                            }
                            Lbl { text: "\uf054"; color: Rock.uiSub; font.pixelSize: 10 }
                        }
                    }
                }
            }

            // ── Быстрые действия ──
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 8
                columnSpacing: 8

                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf125"; label: I18n.t("Область")
                    onActivated: { cc.visible = false; Quick.screenshot(true) }
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf030"; label: I18n.t("Экран")
                    onActivated: { cc.visible = false; Quick.screenshot(false) }
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf03d"; label: Recorder.recording ? I18n.t("Стоп") : I18n.t("Запись")
                    active: Recorder.recording
                    onActivated: { cc.visible = false; Recorder.toggle(true) }
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf1fb"; label: I18n.t("Пипетка")
                    onActivated: { cc.visible = false; Quick.pick() }
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf132"; label: "VPN"
                    active: Net.vpn
                    onActivated: Net.toggleVpn()
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf186"; label: I18n.t("Ночной")
                    active: Quick.night
                    onActivated: Quick.toggleNight()
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: Quick.profileIcon; label: Quick.profileName
                    active: Quick.profile === "performance"
                    onActivated: Quick.cycleProfile()
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf0ea"; label: I18n.t("Буфер")
                    onActivated: { cc.visible = false; Clip.reload(); UI.openLauncher("clip") }
                }
            }

            // ── Статистика ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Stat {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    label: "CPU"; value: SysStats.cpu
                    sub: SysStats.temp > 0 ? SysStats.temp + "°" : ""
                }
                Stat { Layout.fillWidth: true; Layout.preferredWidth: 1; label: "RAM"; value: SysStats.mem }
                Stat { Layout.fillWidth: true; Layout.preferredWidth: 1; label: I18n.t("ДИСК"); value: SysStats.disk }
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

    // ───────── Скотч на постере ─────────
    Rectangle {
        visible: Rock.comic
        x: 22
        y: 2
        width: 64
        height: 14
        radius: 2
        color: Rock.a(Rock.yellow, 0.82)
        border.width: 1
        border.color: Rock.a(Rock.uiText, 0.28)
        rotation: -7
        z: 10
    }
    Rectangle {
        visible: Rock.comic
        x: parent.width - 86
        y: 2
        width: 64
        height: 14
        radius: 2
        color: Rock.a(Rock.cyan, 0.78)
        border.width: 1
        border.color: Rock.a(Rock.uiText, 0.28)
        rotation: 6
        z: 10
    }
}
