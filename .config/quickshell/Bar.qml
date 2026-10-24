import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray

PanelWindow {
    id: bar

    WlrLayershell.namespace: "qs-bar"
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 10; right: 10 }
    implicitHeight: Theme.barHeight
    color: "transparent"

    property var sink: Pipewire.defaultAudioSink
    property var bat: UPower.displayDevice
    property var btAdapter: Bluetooth.defaultAdapter
    readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

    property var player: Media.player

    PwObjectTracker { objects: [bar.sink] }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    MusicPopup    { id: musicPopup;    barWindow: bar; anchorItem: musicPill; player: bar.player }
    CalendarPopup { id: calendarPopup; barWindow: bar; anchorItem: clockPill }
    WeatherPopup  { id: weatherPopup;  barWindow: bar; anchorItem: weatherPill }
    ControlCenter { id: controlCenter; barWindow: bar; anchorItem: statusPill }

    function volIcon() {
        if (!sink || !sink.audio || sink.audio.muted) return "\uf026"
        const v = sink.audio.volume
        return v < 0.01 ? "\uf026" : (v < 0.5 ? "\uf027" : "\uf028")
    }
    function batIcon() {
        if (bat.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(bat.percentage * 5))]
    }

    // ── Остров: скруглённая плашка, содержимое лежит в ряд ──
    component Island: Rectangle {
        default property alias content: inner.data
        height: Theme.barHeight
        width: inner.implicitWidth + 12
        radius: Theme.islandRadius
        color: Theme.bg
        border.width: 1
        border.color: Theme.hairline

        RowLayout {
            id: inner
            anchors.centerIn: parent
            spacing: 2
        }
    }

    // ───────── Левый остров ─────────
    Island {
        anchors.left: parent.left

        // Лаунчер
        Pill {
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) { UI.launcher = false; UI.session = true }
                else { UI.session = false; UI.launcher = !UI.launcher }
            }
            Lbl {
                text: "\uf303"
                color: Theme.accent
                font.pixelSize: 15
            }
        }

        // Рабочие столы — точки
        Pill {
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.id > 0
                    Layout.preferredWidth: modelData.focused ? 20 : 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: modelData.focused ? Theme.accent : Theme.muted
                    opacity: modelData.focused ? 1 : 0.6
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 220 } }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.activate()
                    }
                }
            }
        }

        // Музыка
        Pill {
            id: musicPill
            interactive: true
            visible: bar.player !== null
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) { if (bar.player.canTogglePlaying) bar.player.togglePlaying() }
                else if (mouse.button === Qt.RightButton) { if (bar.player.canGoNext) bar.player.next() }
                else musicPopup.toggle()
            }
            Lbl {
                text: (bar.player && bar.player.playbackState === MprisPlaybackState.Playing) ? "\uf04b" : "\uf04c"
                color: (bar.player && bar.player.playbackState === MprisPlaybackState.Playing) ? Theme.accent : Theme.muted
                font.pixelSize: 10
            }
            Lbl {
                Layout.maximumWidth: 180
                elide: Text.ElideRight
                color: Theme.muted
                text: bar.player
                    ? (bar.player.trackArtist ? bar.player.trackArtist + " – " : "") + bar.player.trackTitle
                    : ""
            }
        }

        // Заголовок окна
        Lbl {
            Layout.leftMargin: 6
            Layout.rightMargin: 8
            Layout.maximumWidth: 220
            text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
            color: Theme.muted
            elide: Text.ElideRight
        }
    }

    // ───────── Центральный остров: часы · погода · динамические события ─────────
    Rectangle {
        id: centerIsland
        anchors.centerIn: parent
        height: Theme.barHeight
        width: (UI.eventActive ? eventRow.implicitWidth : clockGroup.implicitWidth) + 24
        radius: Theme.islandRadius
        color: Theme.bg
        clip: true
        border.width: 1
        border.color: UI.eventActive
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
            : Theme.hairline

        Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // обычный режим
        RowLayout {
            id: clockGroup
            anchors.centerIn: parent
            spacing: 2
            opacity: UI.eventActive ? 0 : 1
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Pill {
                id: clockPill
                interactive: true
                onClicked: calendarPopup.toggle()
                Lbl {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.bold: true
                }
                Lbl {
                    text: Qt.formatDateTime(clock.date, "ddd, d MMM")
                    color: Theme.muted
                }
            }
            Pill {
                id: weatherPill
                interactive: true
                visible: Weather.ready
                onClicked: weatherPopup.toggle()
                Lbl { text: Weather.icon; color: Theme.accent2; font.pixelSize: 14 }
                Lbl { text: Weather.temp + "°" }
            }
        }

        // режим события
        RowLayout {
            id: eventRow
            anchors.centerIn: parent
            spacing: 10
            opacity: UI.eventActive ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Theme.surface
                    visible: evArt.status !== Image.Ready
                }
                Image {
                    id: evArt
                    anchors.fill: parent
                    source: UI.eventArt
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: evArt.status !== Image.Ready
                    text: UI.eventIcon
                    color: Theme.accent
                    font.pixelSize: 13
                }
            }

            ColumnLayout {
                spacing: -1
                Lbl {
                    Layout.maximumWidth: 260
                    text: UI.eventText
                    font.bold: true
                    elide: Text.ElideRight
                }
                Lbl {
                    visible: UI.eventSub !== ""
                    Layout.maximumWidth: 260
                    text: UI.eventSub
                    color: Theme.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            // эквалайзер для музыки
            Row {
                visible: UI.eventKind === "media"
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Repeater {
                    model: 4
                    delegate: Item {
                        id: eq
                        required property int index
                        width: 3
                        height: 16
                        Rectangle {
                            id: barRect
                            anchors.bottom: parent.bottom
                            width: 3
                            radius: 1.5
                            height: 5
                            color: Theme.accent
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                running: UI.eventActive && UI.eventKind === "media"
                                NumberAnimation { to: 15; duration: 260 + eq.index * 70; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 4;  duration: 300 + eq.index * 60; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }
            }

            // палитра при смене темы
            Row {
                visible: UI.eventKind === "theme"
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                Repeater {
                    model: [Theme.accent, Theme.accent2, Theme.text, Theme.surface]
                    delegate: Rectangle {
                        required property var modelData
                        width: 14; height: 14; radius: 7
                        color: modelData
                        border.width: 1
                        border.color: Theme.hairline
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: UI.eventActive
            onClicked: UI.eventActive = false
        }
    }

    // ───────── Правый остров ─────────
    Island {
        anchors.right: parent.right

        // Трей
        Pill {
            visible: SystemTray.items.values.length > 0
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    id: trayItem
                    required property var modelData
                    Layout.preferredWidth: 15
                    Layout.preferredHeight: 15

                    Image {
                        anchors.fill: parent
                        source: trayItem.modelData.icon
                        sourceSize: Qt.size(30, 30)
                        smooth: true
                    }

                    TrayMenu {
                        id: trayMenu
                        barWindow: bar
                        anchorItem: trayItem
                        handle: trayItem.modelData.menu
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            const it = trayItem.modelData
                            if (mouse.button === Qt.MiddleButton) it.secondaryActivate()
                            else if (mouse.button === Qt.RightButton || it.onlyMenu) { if (it.hasMenu) trayMenu.toggle() }
                            else it.activate()
                        }
                    }
                }
            }
        }

        // Обои и тема
        Pill {
            interactive: true
            onClicked: { UI.launcher = false; UI.session = false; UI.wallpaper = !UI.wallpaper }
            Lbl { text: "\uf1fc"; color: Theme.muted; font.pixelSize: Theme.iconSize }
        }

        // Раскладка клавиатуры
        Pill {
            interactive: true
            onClicked: Kb.next()
            Lbl {
                text: Kb.layout
                font.bold: true
                font.pixelSize: 11
            }
        }

        // Статус → центр управления
        Pill {
            id: statusPill
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    if (bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted
                } else controlCenter.toggle()
            }
            onScrolled: wheel => {
                if (bar.sink && bar.sink.audio)
                    bar.sink.audio.volume = Math.max(0, Math.min(1.0,
                        bar.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
            }

            Lbl {
                text: Net.icon
                color: Net.connected ? Theme.text : Theme.muted
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: bar.btAdapter !== null
                text: "\uf293"
                color: bar.btConnected > 0 ? Theme.accent
                     : (bar.btAdapter && bar.btAdapter.enabled ? Theme.text : Theme.muted)
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                text: bar.volIcon()
                color: (bar.sink && bar.sink.audio && bar.sink.audio.muted) ? Theme.muted : Theme.text
                font.pixelSize: Theme.iconSize
            }
            RowLayout {
                visible: bar.bat.isLaptopBattery
                spacing: 5
                Lbl {
                    text: bar.batIcon()
                    color: bar.bat.percentage < 0.2 ? Theme.warn : Theme.text
                    font.pixelSize: Theme.iconSize
                }
                Lbl {
                    text: Math.round(bar.bat.percentage * 100)
                    color: Theme.muted
                }
            }
        }

        // Уведомления → SwayNC
        Pill {
            id: bellPill
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) SwayNC.toggleDnd()
                else if (mouse.button === Qt.MiddleButton) SwayNC.clear()
                else SwayNC.toggle()
            }
            Lbl {
                text: SwayNC.dnd ? "\uf1f6" : "\uf0f3"
                color: SwayNC.dnd ? Theme.warn : (SwayNC.count > 0 ? Theme.accent : Theme.muted)
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: SwayNC.count > 0
                text: SwayNC.count
                color: Theme.accent
                font.bold: true
            }
        }
    }
}
