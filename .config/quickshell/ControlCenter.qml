import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

BarPopup {
    id: cc
    alignment: "right"
    implicitWidth: 380

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
        return " (" + (h > 0 ? h + " ч " : "") + m + " мин)"
    }
    function batIcon() {
        const d = UPower.displayDevice
        if (d.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(d.percentage * 5))]
    }

    // ───────── Плитка ─────────
    component Tile: Rectangle {
        id: tile
        property string icon
        property string title
        property string subtitle
        property bool active: false
        property bool expandable: false
        signal clicked()
        signal rightClicked()
        signal expand()

        implicitHeight: 62
        radius: 18
        color: active ? (tileArea.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                      : (tileArea.containsMouse ? Qt.lighter(Theme.surface, 1.18) : Theme.surface)
        Behavior on color { ColorAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: tile.expandable ? 34 : 10
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: tile.active
                    ? Qt.rgba(Theme.textOnAccent.r, Theme.textOnAccent.g, Theme.textOnAccent.b, 0.14)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                Lbl {
                    anchors.centerIn: parent
                    text: tile.icon
                    color: tile.active ? Theme.textOnAccent : Theme.text
                    font.pixelSize: 15
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Lbl {
                    Layout.fillWidth: true
                    text: tile.title
                    font.bold: true
                    color: tile.active ? Theme.textOnAccent : Theme.text
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: tile.subtitle
                    font.pixelSize: 10
                    color: tile.active ? Theme.textOnAccent : Theme.muted
                    opacity: tile.active ? 0.72 : 1
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
        Rectangle {
            visible: tile.expandable
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26; radius: 13
            color: chevArea.containsMouse
                ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16) : "transparent"
            Lbl {
                anchors.centerIn: parent
                text: "\uf054"
                color: tile.active ? Theme.textOnAccent : Theme.muted
                font.pixelSize: 10
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
        signal moved(real v)
        signal iconClicked()
        implicitHeight: 42

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            color: Theme.surface
            clip: true

            Rectangle {
                width: track.height + (track.width - track.height) * Math.max(0, Math.min(1, sl.value))
                height: track.height
                radius: height / 2
                color: Theme.accent
            }
            Lbl {
                anchors.verticalCenter: parent.verticalCenter
                x: (track.height - width) / 2
                text: sl.icon
                color: Theme.textOnAccent
                font.pixelSize: 15
            }
            Lbl {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 16
                text: Math.round(sl.value * 100)
                color: sl.value > 0.9 ? Theme.textOnAccent : Theme.muted
                font.pixelSize: 11
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
    component QuickBtn: Rectangle {
        id: qb
        property string icon
        property string label
        property bool active: false
        signal activated()
        implicitHeight: 58
        radius: 16
        color: active ? (qArea.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                      : (qArea.containsMouse ? Qt.lighter(Theme.surface, 1.18) : Theme.surface)
        Behavior on color { ColorAnimation { duration: 140 } }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 3
            Lbl {
                Layout.alignment: Qt.AlignHCenter
                text: qb.icon
                color: qb.active ? Theme.textOnAccent : Theme.text
                font.pixelSize: 15
            }
            Lbl {
                Layout.alignment: Qt.AlignHCenter
                text: qb.label
                color: qb.active ? Theme.textOnAccent : Theme.muted
                font.pixelSize: 9
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

    // ───────── Карточка статистики ─────────
    component Stat: Rectangle {
        id: st
        property string label
        property int value: 0
        property string sub: ""
        implicitHeight: 64
        radius: 16
        color: Theme.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                Lbl { text: st.label; color: Theme.muted; font.pixelSize: 10; Layout.fillWidth: true }
                Lbl { text: st.sub; color: Theme.muted; font.pixelSize: 9; visible: st.sub !== "" }
            }
            Lbl { text: st.value + "%"; font.bold: true; font.pixelSize: 15 }
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 2
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                Rectangle {
                    width: parent.width * Math.min(1, st.value / 100)
                    height: parent.height
                    radius: 2
                    color: st.value > 85 ? Theme.warn : Theme.accent2
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
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
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: Theme.accent
                    Lbl {
                        anchors.centerIn: parent
                        text: cc.userName.charAt(0).toUpperCase()
                        color: Theme.textOnAccent
                        font.bold: true
                        font.pixelSize: 17
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 1
                    Lbl { text: cc.userName; font.bold: true; font.pixelSize: 14 }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6
                        Lbl {
                            visible: UPower.displayDevice.isLaptopBattery
                            text: cc.batIcon()
                            color: UPower.displayDevice.percentage < 0.2 ? Theme.warn : Theme.accent2
                            font.pixelSize: 12
                        }
                        Lbl {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.pixelSize: 11
                            text: (UPower.displayDevice.isLaptopBattery
                                    ? Math.round(UPower.displayDevice.percentage * 100) + "% · "
                                      + (UPower.displayDevice.state === UPowerDeviceState.Charging ? "заряжается" : "от батареи") + cc.etaText() + " · "
                                    : "")
                                + "работает " + SysStats.uptimeText
                        }
                    }
                }
                IconBtn {
                    size: 38
                    icon: "\uf1fc"
                    onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.wallpaper = true }
                }
                Rectangle {
                    implicitWidth: 38; implicitHeight: 38; radius: 19
                    color: pwrArea.containsMouse ? Theme.surface : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Lbl { anchors.centerIn: parent; text: "\uf011"; color: Theme.muted; font.pixelSize: 15 }
                    MouseArea {
                        id: pwrArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { cc.visible = false; UI.launcher = false; UI.session = true }
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
                    subtitle: Net.kind === "ethernet" ? "Подключено"
                            : (Net.connected ? Net.connection : (Net.wifiEnabled ? "Не подключено" : "Выключено"))
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
                    subtitle: !cc.btAdapter ? "Недоступно"
                        : (cc.btAdapter.enabled
                            ? (cc.btConnectedDevices.length > 0
                                ? cc.btConnectedDevices.map(d => d.name || d.deviceName).join(", ")
                                : "Включён")
                            : "Выключен")
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
                    title: "Тишина"
                    subtitle: Notifs.dnd ? "Не беспокоить" : "Уведомления"
                    active: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                    onRightClicked: UI.toggleCenter()
                }
                Tile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "\uf0f4"
                    title: "Не засыпать"
                    subtitle: UI.caffeine ? "Экран не гаснет" : "Выключено"
                    active: UI.caffeine
                    onClicked: {
                        UI.caffeine = !UI.caffeine
                        UI.flash("\uf0f4", "Не засыпать", UI.caffeine ? "Включено" : "Выключено", "", "info", "")
                    }
                }
            }

            // ── Музыка ──
            MediaCard {
                Layout.fillWidth: true
                active: cc.visible && cc.page === "main"
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
                    onMoved: v => Brightness.set(v)
                }

                // устройство вывода + микрофон
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 16
                    color: audioArea.containsMouse ? Qt.lighter(Theme.surface, 1.18) : Theme.surface
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
                        anchors.leftMargin: 14
                        anchors.rightMargin: 8
                        spacing: 10
                        Lbl { text: cc.sinkGlyph(); color: Theme.accent2; font.pixelSize: 14; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignHCenter }
                        Lbl {
                            Layout.fillWidth: true
                            text: cc.sink ? (cc.sink.description || cc.sink.nickname || cc.sink.name) : "Нет устройства вывода"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        IconBtn {
                            size: 30
                            visible: cc.source !== null
                            icon: cc.micMuted ? "\uf131" : "\uf130"
                            iconColor: cc.micMuted ? Theme.warn : Theme.muted
                            onClicked: if (cc.source && cc.source.audio) cc.source.audio.muted = !cc.source.audio.muted
                        }
                        Lbl { text: "\uf054"; color: Theme.muted; font.pixelSize: 10 }
                    }
                }
            }

            // ── Быстрые действия ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf125"; label: "Область"
                    onActivated: { cc.visible = false; Quick.screenshot(true) }
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf030"; label: "Экран"
                    onActivated: { cc.visible = false; Quick.screenshot(false) }
                }
                QuickBtn {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf1fb"; label: "Пипетка"
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
                    icon: "\uf186"; label: "Ночной"
                    active: Quick.night
                    onActivated: Quick.toggleNight()
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
                Stat { Layout.fillWidth: true; Layout.preferredWidth: 1; label: "ДИСК"; value: SysStats.disk }
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
