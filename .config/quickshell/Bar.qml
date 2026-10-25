import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray

PanelWindow {
    id: bar

    WlrLayershell.namespace: "qs-bar"
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 10; right: 10 }

    // окно выше самой панели — чтобы остров мог расти вниз.
    // Резервируется только высота панели, а клики принимают лишь сами острова.
    implicitHeight: 280
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.barHeight
    color: "transparent"
    mask: Region {
        item: leftIsland
        Region { item: centerIsland }
        Region { item: rightIsland }
    }

    property var sink: Pipewire.defaultAudioSink
    property var bat: UPower.displayDevice
    property var btAdapter: Bluetooth.defaultAdapter
    property var player: Media.player

    // значок активного окна
    readonly property string activeIcon: {
        const t = ToplevelManager.activeToplevel
        if (!t || !t.appId) return ""
        let e = null
        try { e = DesktopEntries.byId(t.appId) || DesktopEntries.heuristicLookup(t.appId) } catch (err) {}
        return (e && e.icon) ? Quickshell.iconPath(e.icon) : ""
    }

    PwObjectTracker { objects: [bar.sink] }
    IdleInhibitor { window: bar; enabled: UI.caffeine }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    MusicPopup    { id: musicPopup;    barWindow: bar; anchorItem: miniPill; player: bar.player }
    CalendarPopup { id: calendarPopup; barWindow: bar; anchorItem: clockPill }
    WeatherPopup  { id: weatherPopup;  barWindow: bar; anchorItem: weatherPill }
    ControlCenter { id: controlCenter; barWindow: bar; anchorItem: statusPill }
    NotifCenter   { id: notifCenter;   barWindow: bar; anchorItem: bellPill }

    // открыть центр уведомлений из любого места (IPC, события)
    Connections {
        target: UI
        function onToggleCenter() { notifCenter.toggle() }
    }

    function runEventAction(a) {
        if (a === "media") musicPopup.toggle()
        else if (a === "bt") { controlCenter.page = "bt"; controlCenter.toggle() }
        else if (a === "wifi") { controlCenter.page = "wifi"; controlCenter.toggle() }
        else if (a === "cc") controlCenter.toggle()
        else if (a === "notifs") notifCenter.toggle()
        else if (a === "wallpaper") UI.wallpaper = true
        else if (a === "weather") weatherPopup.toggle()
    }

    function fmtTime(s) {
        if (!isFinite(s) || s < 0) return "0:00"
        return Math.floor(s / 60) + ":" + ("0" + Math.floor(s % 60)).slice(-2)
    }

    // пока показывается событие трека, плашка с часами скрыта — обновляем позицию тут
    Timer {
        running: UI.eventActive && UI.eventKind === "media" && Media.player !== null
                 && Media.player.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: Media.player.positionChanged()
    }

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
        id: leftIsland
        anchors.left: parent.left
        anchors.top: parent.top

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

        // Таймер фокуса: клик — старт/стоп, ПКМ — следующая фаза
        Pill {
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) { if (Pomodoro.running) Pomodoro.skip(); else Pomodoro.start("break") }
                else if (Pomodoro.running) Pomodoro.stop()
                else Pomodoro.start("focus")
            }
            Lbl {
                text: Pomodoro.mode === "break" ? "\uf0f4" : "\uf017"
                color: Pomodoro.mode === "focus" ? Theme.accent : (Pomodoro.mode === "break" ? Theme.accent2 : Theme.muted)
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Pomodoro.running
                text: Pomodoro.text()
                font.bold: true
                color: Pomodoro.mode === "focus" ? Theme.accent : Theme.accent2
            }
        }

        // Значок и заголовок активного окна
        Image {
            id: winIcon
            Layout.leftMargin: 4
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: bar.activeIcon
            sourceSize: Qt.size(32, 32)
            smooth: true
            visible: status === Image.Ready
        }
        Lbl {
            Layout.leftMargin: winIcon.visible ? 0 : 6
            Layout.rightMargin: 8
            Layout.maximumWidth: 220
            text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
            color: Theme.muted
            elide: Text.ElideRight
        }
    }

    // ═════════ Центральный остров: часы · погода · события · УВЕДОМЛЕНИЯ ═════════
    Rectangle {
        id: centerIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        property real ttlFrac: 0
        property var lastNotif: null

        readonly property bool notifMode: Notifs.current !== null
        readonly property bool eventMode: !notifMode && UI.eventActive
        readonly property var nn: Notifs.current !== null ? Notifs.current : lastNotif

        // в режиме уведомления остров растёт в основном вширь и совсем чуть вниз
        readonly property real notifW: Math.max(340, Math.min(Math.min(560, bar.width - 760), notifBox.implicitWidth + 36))

        width: notifMode ? notifW : (eventMode ? eventRow.implicitWidth + 24 : clockGroup.implicitWidth + 24)
        height: notifMode ? notifBox.implicitHeight + 18 : Theme.barHeight
        radius: notifMode ? 22 : Theme.islandRadius
        color: Theme.bg
        clip: true
        border.width: 1
        border.color: (notifMode || eventMode)
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
            : Theme.hairline

        Behavior on width  { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on radius { NumberAnimation { duration: 260 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        Connections {
            target: Notifs
            function onCurrentChanged() { if (Notifs.current) centerIsland.lastNotif = Notifs.current }
            function onKeyChanged() { ttlAnim.restart() }
        }
        Connections {
            target: UI
            function onEventKeyChanged() { ttlAnim.restart() }
        }

        // Клики по острову, пока он в режиме уведомления или события.
        // Лежит ниже содержимого, поэтому кнопки внутри работают сами.
        MouseArea {
            anchors.fill: parent
            enabled: centerIsland.notifMode || centerIsland.eventMode
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (centerIsland.notifMode) {
                    // ЛКМ — действие по умолчанию (и убрать), ПКМ — скрыть в историю, СКМ — удалить
                    const n = Notifs.current
                    if (mouse.button === Qt.RightButton) Notifs.hide()
                    else if (mouse.button === Qt.MiddleButton) Notifs.dismissCurrent()
                    else {
                        const d = Notifs.defaultAction(n)
                        if (d) { d.invoke(); Notifs.dismissCurrent() }
                        else Notifs.hide()
                    }
                    return
                }
                if (mouse.button === Qt.RightButton) { UI.dismissEvent(); return }
                if (mouse.button === Qt.MiddleButton) {
                    if (UI.eventKind === "media" && Media.player && Media.player.canTogglePlaying)
                        Media.player.togglePlaying()
                    return
                }
                const a = UI.eventAction
                UI.dismissEvent()
                if (a !== "") bar.runEventAction(a)
            }
        }

        // наведение удерживает показ (работает и над кнопками внутри)
        HoverHandler {
            enabled: centerIsland.notifMode || centerIsland.eventMode
            onHoveredChanged: {
                if (centerIsland.notifMode) Notifs.hold = hovered
                else UI.eventHold = hovered && UI.eventActive
            }
        }

        // ───────── обычный режим ─────────
        RowLayout {
            id: clockGroup
            anchors.centerIn: parent
            spacing: 2
            opacity: (centerIsland.notifMode || centerIsland.eventMode) ? 0 : 1
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Подключённые Bluetooth-устройства: иконка и заряд
            Pill {
                id: btPill
                interactive: true
                visible: Bt.connected.length > 0
                onClicked: { controlCenter.page = "bt"; controlCenter.toggle() }
                Repeater {
                    model: Bt.connected
                    delegate: RowLayout {
                        id: btItem
                        required property var modelData
                        spacing: 5
                        Lbl {
                            text: Bt.iconFor(btItem.modelData)
                            color: Theme.accent
                            font.pixelSize: Theme.iconSize
                        }
                        Lbl {
                            visible: Bt.percent(btItem.modelData) >= 0
                            text: Bt.percent(btItem.modelData) + "%"
                            color: Bt.percent(btItem.modelData) <= 20 ? Theme.warn : Theme.muted
                            font.pixelSize: 11
                        }
                    }
                }
            }

            MiniMedia {
                id: miniPill
                onOpenRequested: musicPopup.toggle()
            }

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

        // ───────── режим события ─────────
        RowLayout {
            id: eventRow
            anchors.centerIn: parent
            spacing: 10
            opacity: centerIsland.eventMode ? 1 : 0
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
                                running: centerIsland.eventMode && UI.eventKind === "media"
                                NumberAnimation { to: 15; duration: 260 + eq.index * 70; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 4;  duration: 300 + eq.index * 60; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }
            }

            // время трека в событии
            Lbl {
                visible: UI.eventKind === "media" && Media.player !== null
                Layout.alignment: Qt.AlignVCenter
                text: bar.fmtTime(Media.player ? Media.player.position : 0) + " / " + bar.fmtTime(Media.player ? Media.player.length : 0)
                color: Theme.muted
                font.pixelSize: 10
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

        // ───────── режим УВЕДОМЛЕНИЯ: компактно, в две строки ─────────
        RowLayout {
            id: notifBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 9
            width: centerIsland.notifW - 36
            spacing: 12
            opacity: centerIsland.notifMode ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 220 } }

            // аватар (или значок приложения); у аватара значок приложения — крошечным бейджем
            Item {
                id: avatar
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                readonly property bool hasPic: picImg.status === Image.Ready

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: Theme.surface
                    visible: !avatar.hasPic
                }
                Image {
                    id: picImg
                    anchors.fill: parent
                    source: Notifs.contentImage(centerIsland.nn)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: avatar.hasPic
                }
                RoundMask {
                    anchors.fill: parent
                    radius: 11
                    maskColor: Theme.bg
                    visible: avatar.hasPic
                }
                Image {
                    id: appIcon
                    width: avatar.hasPic ? 14 : 22
                    height: width
                    x: avatar.hasPic ? avatar.width - width + 3 : (avatar.width - width) / 2
                    y: avatar.hasPic ? avatar.height - height + 3 : (avatar.height - height) / 2
                    source: Notifs.appIconSource(centerIsland.nn)
                    sourceSize: Qt.size(44, 44)
                    smooth: true
                    visible: status === Image.Ready
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: !avatar.hasPic && appIcon.status !== Image.Ready
                    text: "\uf0f3"
                    color: Theme.accent
                    font.pixelSize: 14
                }
            }

            // строка 1: кто написал  ·····  приложение · время
            // строка 2: сообщение
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Lbl {
                        Layout.fillWidth: true
                        text: centerIsland.nn ? centerIsland.nn.summary : ""
                        font.bold: true
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.maximumWidth: 120
                        text: centerIsland.nn ? (centerIsland.nn.appName || "") : ""
                        color: Theme.accent
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                    Lbl {
                        text: Notifs.timeAgo(centerIsland.nn)
                        color: Theme.muted
                        font.pixelSize: 10
                    }
                    Lbl {
                        visible: Notifs.pending > 0
                        text: "+" + Notifs.pending
                        color: Theme.accent
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: centerIsland.nn ? String(centerIsland.nn.body).replace(/\s*\n\s*/g, "  ") : ""
                    opacity: 0.75
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // действия приложения — небольшие кнопки справа
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6
                visible: Notifs.actionList(centerIsland.nn).length > 0
                Repeater {
                    model: Notifs.actionList(centerIsland.nn).slice(0, 2)
                    delegate: Rectangle {
                        id: actBtn
                        required property var modelData
                        implicitWidth: actLbl.implicitWidth + 20
                        implicitHeight: 26
                        radius: 13
                        color: actArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Lbl {
                            id: actLbl
                            anchors.centerIn: parent
                            text: actBtn.modelData.text
                            color: Theme.textOnAccent
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: actArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { actBtn.modelData.invoke(); Notifs.dismissCurrent() }
                        }
                    }
                }
            }
        }

        // полоска оставшегося времени (для уведомлений и событий)
        Rectangle {
            visible: centerIsland.eventMode || (centerIsland.notifMode && Notifs.duration > 0)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, (centerIsland.width - 56) * centerIsland.ttlFrac)
            height: 1.5
            radius: 1
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
        }
        NumberAnimation {
            id: ttlAnim
            target: centerIsland
            property: "ttlFrac"
            from: 1; to: 0
            duration: centerIsland.notifMode ? Math.max(1, Notifs.duration) : UI.eventDuration
            paused: centerIsland.notifMode ? Notifs.hold : UI.eventHold
        }
    }

    // ───────── Правый остров ─────────
    Island {
        id: rightIsland
        anchors.right: parent.right
        anchors.top: parent.top

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

        // VPN: виден, пока включён (клик — выключить, если профиль в NetworkManager)
        Pill {
            visible: Net.vpn
            interactive: Net.vpnManaged
            onClicked: Net.toggleVpn()
            Lbl { text: "\uf132"; color: Theme.accent2; font.pixelSize: Theme.iconSize }
            Lbl {
                Layout.maximumWidth: 90
                text: Net.vpnName
                color: Theme.muted
                font.pixelSize: 11
                elide: Text.ElideRight
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
                visible: UI.caffeine
                text: "\uf0f4"
                color: Theme.accent
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Quick.night
                text: "\uf186"
                color: Theme.accent2
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                text: Net.icon
                color: Net.connected ? Theme.text : Theme.muted
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: bar.btAdapter !== null
                text: "\uf293"
                color: Bt.connected.length > 0 ? Theme.accent
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

        // Уведомления → центр уведомлений
        Pill {
            id: bellPill
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd
                else if (mouse.button === Qt.MiddleButton) Notifs.clearAll()
                else notifCenter.toggle()
            }
            Lbl {
                text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                color: Notifs.dnd ? Theme.warn : (Notifs.count > 0 ? Theme.accent : Theme.muted)
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Notifs.count > 0
                text: Notifs.count
                color: Theme.accent
                font.bold: true
            }
        }
    }
}
