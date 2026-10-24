import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

BarPopup {
    id: cc
    alignment: "right"
    implicitWidth: 360
    property string page: "main"      // "main" | "wifi" | "bt"
    implicitHeight: page === "main" ? content.implicitHeight + 32 : 500

    property var sink: Pipewire.defaultAudioSink
    property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btConnectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string userName: Quickshell.env("USER") || "user"

    PwObjectTracker { objects: [cc.sink] }

    onVisibleChanged: {
        SysStats.active = visible
        if (visible) { Brightness.refresh(); Net.refresh() }
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
    function batIcon() {
        const d = UPower.displayDevice
        if (d.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(d.percentage * 5))]
    }

    // ───────── Плитка-переключатель ─────────
    component Tile: Rectangle {
        id: tile
        property string icon
        property string title
        property string subtitle
        property bool active: false
        signal clicked()
        signal rightClicked()
        property bool expandable: false
        signal expand()

        implicitHeight: 64
        radius: 18
        color: active ? (tileArea.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                      : (tileArea.containsMouse ? Qt.lighter(Theme.surface, 1.18) : Theme.surface)
        Behavior on color { ColorAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: tile.expandable ? 40 : 12
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: tile.active
                    ? Qt.rgba(Theme.textOnAccent.r, Theme.textOnAccent.g, Theme.textOnAccent.b, 0.14)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                Lbl {
                    anchors.centerIn: parent
                    text: tile.icon
                    color: tile.active ? Theme.textOnAccent : Theme.text
                    font.pixelSize: 16
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
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 28; height: 28; radius: 14
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

    // ───────── Толстый ползунок (как в мобильных ОС) ─────────
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
            // клик по иконке — действие (например, mute)
            MouseArea {
                width: track.height
                height: track.height
                cursorShape: Qt.PointingHandCursor
                onClicked: sl.iconClicked()
            }
        }
    }

    // ───────── Кнопка медиа ─────────
    component MBtn: Rectangle {
        property string icon
        property bool primary: false
        signal activated()
        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        color: primary ? (mArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
                       : (mArea.containsMouse ? Qt.lighter(Theme.surface, 1.4) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        Lbl {
            anchors.centerIn: parent
            text: parent.icon
            color: parent.primary ? Theme.textOnAccent : Theme.text
            font.pixelSize: 11
        }
        MouseArea {
            id: mArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    // ───────── Карточка статистики ─────────
    component Stat: Rectangle {
        id: st
        property string label
        property int value: 0
        implicitHeight: 62
        radius: 18
        color: Theme.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Lbl { text: st.label; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                Lbl { text: st.value + "%"; font.bold: true }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 4
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

    ColumnLayout {
        id: content
        visible: cc.page === "main"
        anchors.fill: parent
        anchors.margins: 16
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
                spacing: 1
                Lbl { text: cc.userName; font.bold: true; font.pixelSize: 14 }
                RowLayout {
                    visible: UPower.displayDevice.isLaptopBattery
                    spacing: 6
                    Lbl {
                        text: cc.batIcon()
                        color: UPower.displayDevice.percentage < 0.2 ? Theme.warn : Theme.accent2
                        font.pixelSize: 12
                    }
                    Lbl {
                        color: Theme.muted
                        font.pixelSize: 11
                        text: Math.round(UPower.displayDevice.percentage * 100) + "% · "
                            + (UPower.displayDevice.state === UPowerDeviceState.Charging ? "заряжается" : "от батареи")
                    }
                }
            }
            Item { Layout.fillWidth: true }
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
                icon: SwayNC.dnd ? "\uf1f6" : "\uf0f3"
                title: "Не беспокоить"
                subtitle: SwayNC.dnd ? "Включено" : "Выключено"
                active: SwayNC.dnd
                onClicked: SwayNC.toggleDnd()
                onRightClicked: SwayNC.toggle()
            }
            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: cc.volIcon()
                title: "Звук"
                subtitle: (cc.sink && cc.sink.audio && !cc.sink.audio.muted) ? "Включён" : "Выключен"
                active: cc.sink && cc.sink.audio ? !cc.sink.audio.muted : false
                onClicked: if (cc.sink && cc.sink.audio) cc.sink.audio.muted = !cc.sink.audio.muted
                onRightClicked: Quickshell.execDetached(["pavucontrol"])
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
                onMoved: v => Brightness.set(v)
            }
        }

        // ── Мини-плеер ──
        Rectangle {
            visible: Media.player !== null
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 18
            color: Theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 10
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                    clip: true
                    Image {
                        id: mArt
                        anchors.fill: parent
                        source: Media.player ? Media.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Lbl {
                        anchors.centerIn: parent
                        visible: !mArt.visible
                        text: "\uf001"
                        color: Theme.muted
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Lbl {
                        Layout.fillWidth: true
                        text: Media.player ? (Media.player.trackTitle || "Без названия") : ""
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: Media.player ? Media.player.trackArtist : ""
                        color: Theme.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
                MBtn {
                    icon: "\uf048"
                    onActivated: if (Media.player && Media.player.canGoPrevious) Media.player.previous()
                }
                MBtn {
                    primary: true
                    icon: (Media.player && Media.player.playbackState === MprisPlaybackState.Playing) ? "\uf04c" : "\uf04b"
                    onActivated: if (Media.player && Media.player.canTogglePlaying) Media.player.togglePlaying()
                }
                MBtn {
                    icon: "\uf051"
                    onActivated: if (Media.player && Media.player.canGoNext) Media.player.next()
                }
            }
        }

        // ── Статистика ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Stat { Layout.fillWidth: true; Layout.preferredWidth: 1; label: "CPU"; value: SysStats.cpu }
            Stat { Layout.fillWidth: true; Layout.preferredWidth: 1; label: "RAM"; value: SysStats.mem }
        }
    }

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
}
