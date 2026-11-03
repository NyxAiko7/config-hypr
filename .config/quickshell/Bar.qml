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
    // Резервируется только высота панели; клики принимают острова,
    // а пустое пространство между ними перехватывается только когда
    // открыто какое-то меню — клик мимо закрывает его.
    implicitHeight: 380
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.keyboardFocus: launcherHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: launcherHere ? WlrLayer.Overlay : WlrLayer.Top
    exclusiveZone: Theme.barHeight
    color: "transparent"
    mask: Region {
        item: leftIsland
        Region { item: centerIsland }
        Region { item: rightIsland }
        Region { item: dismissRect }
    }

    property var sink: Pipewire.defaultAudioSink
    property var bat: UPower.displayDevice
    property var btAdapter: Bluetooth.defaultAdapter
    property var player: Media.player

    // лаунчер открывается на том мониторе, где ты сейчас работаешь
    readonly property bool launcherHere: {
        if (!UI.launcher) return false
        const fm = Hyprland.focusedMonitor
        if (!fm || !bar.screen) return true
        return fm.name === bar.screen.name
    }

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
    // часы всегда с точностью до секунд — тогда «ss» не нулится
    SystemClock { id: barClock; precision: SystemClock.Seconds }

    // секунды и дата в часах показываем только когда играет музыка
    readonly property bool showSeconds: miniPill.playing

    MusicPopup    { id: musicPopup;    barWindow: bar; anchorItem: miniPill; player: bar.player }
    CalendarPopup { id: calendarPopup; barWindow: bar; anchorItem: clockPill }
    WeatherPopup  { id: weatherPopup;  barWindow: bar; anchorItem: weatherPill }
    ControlCenter { id: controlCenter; barWindow: bar; anchorItem: statusPill }
    NotifCenter   { id: notifCenter;   barWindow: bar; anchorItem: bellPill }

    readonly property bool anyPopupOpen: musicPopup.visible || calendarPopup.visible
                                         || weatherPopup.visible || controlCenter.visible
                                         || notifCenter.visible || UI.anyPopupOpen

    // клик по пустому месту панели — закрыть всё открытое
    function closeAllPopups() {
        musicPopup.visible = false
        calendarPopup.visible = false
        weatherPopup.visible = false
        controlCenter.visible = false
        notifCenter.visible = false
        UI.launcher = false
        // подложка-оверлей (обои/сессия) сама ловит клики мимо — не трогаем,
        // иначе её окно перехватит второй клик и панель «застрянет»
    }

    Connections {
        target: UI
        function onToggleCenter() { notifCenter.toggle() }
        // клик мимо по панели: закрываем меню, только если оверлея нет
        function onClosePopups() { if (!UI.wallpaper && !UI.session) bar.closeAllPopups() }
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
    // потребление/зарядка в ваттах ("" если данных нет)
    function watts() {
        const w = Math.abs(bat.changeRate)
        return w >= 0.5 ? w.toFixed(1) + " Вт" : ""
    }
    function batIcon() {
        if (bat.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(bat.percentage * 5))]
    }
    // цвет заряда: критично / мало / зарядка / нормально
    function batColor() {
        if (bat.state === UPowerDeviceState.Charging) return Theme.accent2
        if (bat.percentage < 0.1) return Theme.warn
        if (bat.percentage < 0.2) return Theme.warn
        return Theme.text
    }

    // ───────── Клик мимо: закрыть открытое меню ─────────
    // Прозрачная полоса по всей ширине панели; участвует в mask только
    // когда что-то открыто — в остальное время клики проходят насквозь.
    Item {
        id: dismissRect
        visible: bar.anyPopupOpen
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.barHeight

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: {
                UI.launcher = false
                UI.closePopups()
            }
        }
    }

    // ───────── Левый остров ─────────
    BarIsland {
        id: leftIsland
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Theme.islandInset
        fill: Rock.cream
        shadowColor: Rock.pink
        tilt: -0.8

        // Лаунчер
        Pill {
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) { UI.launcher = false; UI.session = true }
                else UI.openLauncher("apps")
            }
            Lbl {
                text: "\uf303"
                color: Rock.pinkDeep
                font.pixelSize: 15
                scale: parent.hovered ? 1.12 : 1.0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
        }

        // Рабочие столы — точки с подсветкой занятых
        Pill {
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.id > 0
                    Layout.preferredWidth: modelData.focused ? 20 : 6
                    Layout.preferredHeight: 6
                    radius: 3
                    // занятые (есть окна) горят бирюзой, пустые — тусклым контуром
                    color: modelData.focused ? Rock.pinkDeep
                           : (modelData.windows !== undefined && modelData.windows.values.length > 0
                              ? Rock.cyan : Rock.a(Rock.ink, 0.22))
                    opacity: modelData.focused ? 1 : 0.9
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

        // Идёт запись экрана (клик — остановить)
        Pill {
            visible: Recorder.recording
            interactive: true
            onClicked: Recorder.stop()
            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: Rock.pinkDeep
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: Recorder.recording
                    NumberAnimation { to: 0.3; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }
            Lbl { text: Recorder.text(); color: Rock.pinkDeep; font.bold: true }
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
                color: Pomodoro.mode === "focus" ? Rock.pinkDeep : (Pomodoro.mode === "break" ? Rock.cyan : Rock.a(Rock.ink, 0.4))
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Pomodoro.running
                text: Pomodoro.text()
                font.bold: true
                color: Pomodoro.mode === "focus" ? Rock.pinkDeep : Rock.cyan
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
            color: Rock.a(Rock.ink, 0.58)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    // ═════════ Центральный остров: часы · погода · события · УВЕДОМЛЕНИЯ ═════════
    Item {
        id: centerIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.islandInset

        property real ttlFrac: 0
        property var lastNotif: null

        readonly property bool launchMode: bar.launcherHere
        readonly property bool notifMode: !launchMode && Notifs.current !== null
        readonly property bool eventMode: !launchMode && !notifMode && UI.eventActive
        readonly property var nn: Notifs.current !== null ? Notifs.current : lastNotif

        // в режиме уведомления остров растёт в основном вширь и совсем чуть вниз
        readonly property real notifW: Math.max(340, Math.min(Math.min(560, bar.width - 760), notifBox.implicitWidth + 36))

        readonly property real launchW: Math.max(420, Math.min(580, bar.width - 760))

        width: launchMode ? launchW
             : (notifMode ? notifW : (eventMode ? eventRow.implicitWidth + 30 : clockGroup.implicitWidth + 28))
        height: launchMode ? launchBox.implicitHeight + 16
              : (notifMode ? notifBox.implicitHeight + 22 : Theme.islandHeight)
        property real radiusNow: (launchMode || notifMode) ? 16 : (eventMode ? 13 : 11)
        readonly property bool cream: launchMode || notifMode
        clip: false

        Behavior on width  { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on radiusNow { NumberAnimation { duration: 260 } }

        IslandSurface {
            anchors.fill: parent
            radius: centerIsland.radiusNow
            fill: centerIsland.cream ? Rock.cream : Rock.ink2
            shadowColor: centerIsland.cream ? Rock.pink : Rock.yellow
            shadowOffset: 3
            active: centerIsland.launchMode || centerIsland.notifMode || centerIsland.eventMode
            pulse: centerIsland.eventMode
        }

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
            opacity: (centerIsland.launchMode || centerIsland.notifMode || centerIsland.eventMode) ? 0 : 1
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
                            color: Rock.cyan
                            font.pixelSize: Theme.iconSize
                        }
                        Lbl {
                            visible: Bt.percent(btItem.modelData) >= 0
                            text: Bt.percent(btItem.modelData) + "%"
                            color: Bt.percent(btItem.modelData) <= 20 ? Rock.pink : Rock.a(Rock.cream, 0.55)
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
                // Часы как на локскрине: объёмное время с цветными слоями,
                // рядом — жёлтый стикер с датой и розовый с секундами.
                Item {
                    Layout.preferredWidth: clockTime.width
                    Layout.preferredHeight: clockTime.height

                    Text {
                        x: 2; y: 2
                        text: clockTime.text
                        color: Rock.pinkDeep
                        font.family: Rock.display
                        font.pixelSize: 16
                        font.weight: Font.Black
                        font.letterSpacing: -0.5
                    }
                    Text {
                        x: 1; y: 1
                        text: clockTime.text
                        color: Rock.cyan
                        font.family: Rock.display
                        font.pixelSize: 16
                        font.weight: Font.Black
                        font.letterSpacing: -0.5
                    }
                    Text {
                        id: clockTime
                        text: Qt.formatDateTime(barClock.date, "HH:mm")
                        color: Rock.cream
                        font.family: Rock.display
                        font.pixelSize: 16
                        font.weight: Font.Black
                        font.letterSpacing: -0.5
                    }
                }

                RockChip {
                    fill: Rock.yellow
                    shadowColor: Rock.pink
                    offset: 1.5
                    padH: 8
                    padV: 2
                    radius: 6
                    Lbl {
                        text: Qt.formatDateTime(barClock.date, "ddd d").toUpperCase()
                        color: Rock.ink
                        font.family: Rock.display
                        font.pixelSize: 9
                        font.weight: Font.Black
                        font.letterSpacing: 0.6
                    }
                }
                RockChip {
                    fill: Rock.pink
                    shadowColor: Rock.cyan
                    offset: 1.5
                    padH: 7
                    padV: 2
                    radius: 6
                    Lbl {
                        text: Qt.formatDateTime(barClock.date, "ss")
                        color: Rock.cream
                        font.pixelSize: 10
                        font.weight: Font.Black
                    }
                }
            }
            Pill {
                id: weatherPill
                interactive: true
                visible: Weather.ready
                onClicked: weatherPopup.toggle()
                Lbl {
                    text: Weather.icon
                    color: Rock.cyan
                    font.pixelSize: 14
                    scale: parent.hovered ? 1.15 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                Lbl {
                    text: Weather.temp + "°"
                    color: Rock.cream
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 13
                }
                // вероятность осадков в ближайшие часы — если есть, то сразу видно
                Lbl {
                    visible: Weather.nextPrecip > 0
                    text: "\uf043 " + Weather.nextPrecip + "%"
                    color: Weather.nextPrecip >= 40 ? Rock.pink : Rock.a(Rock.cream, 0.55)
                    font.pixelSize: 10
                }
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
                    radius: 7
                    color: Rock.ink
                    border.width: 2
                    border.color: Rock.cream
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
                    color: Rock.pink
                    font.pixelSize: 13
                }
            }

            ColumnLayout {
                visible: UI.eventKind !== "level"
                spacing: -1
                Lbl {
                    Layout.maximumWidth: 260
                    text: UI.eventText
                    color: Rock.cream
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Lbl {
                    visible: UI.eventSub !== ""
                    Layout.maximumWidth: 260
                    text: UI.eventSub
                    color: Rock.a(Rock.cream, 0.55)
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            // уровень громкости / яркости
            Item {
                visible: UI.eventKind === "level"
                Layout.preferredWidth: 150
                Layout.preferredHeight: 6
                Layout.alignment: Qt.AlignVCenter
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: Rock.a(Rock.cream, 0.16)
                    border.width: 1
                    border.color: Rock.a(Rock.cream, 0.22)
                }
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, Levels.muted ? 0 : Levels.value))
                    height: parent.height
                    radius: 3
                    color: Levels.muted ? Rock.a(Rock.cream, 0.4) : Rock.yellow
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }
            Lbl {
                visible: UI.eventKind === "level"
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignRight
                text: Levels.muted ? "–" : Math.round(Levels.value * 100)
                color: Rock.a(Rock.cream, 0.6)
                font.pixelSize: 11
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
                            color: Rock.yellow
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
                color: Rock.a(Rock.cream, 0.55)
                font.pixelSize: 10
            }

            // палитра при смене темы
            Row {
                visible: UI.eventKind === "theme"
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                Repeater {
                    model: [Rock.pink, Rock.cyan, Rock.yellow, Rock.cream]
                    delegate: Rectangle {
                        required property var modelData
                        width: 14; height: 14; radius: 7
                        color: modelData
                        border.width: 2
                        border.color: Rock.ink
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
                    radius: 10
                    color: Rock.paper
                    border.width: 2
                    border.color: Rock.ink
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
                    radius: 10
                    maskColor: Rock.cream
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
                    color: Rock.pinkDeep
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
                        color: Rock.ink
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.maximumWidth: 120
                        text: centerIsland.nn ? (centerIsland.nn.appName || "") : ""
                        color: Rock.pinkDeep
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Lbl {
                        text: Notifs.timeAgo(centerIsland.nn)
                        color: Rock.a(Rock.ink, 0.5)
                        font.pixelSize: 10
                    }
                    Lbl {
                        visible: Notifs.pending > 0
                        text: "+" + Notifs.pending
                        color: Rock.pinkDeep
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: centerIsland.nn ? String(centerIsland.nn.body).replace(/\s*\n\s*/g, "  ") : ""
                    color: Rock.a(Rock.ink, 0.68)
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
                        implicitWidth: actLbl.implicitWidth + 18
                        implicitHeight: 24
                        radius: 7
                        color: actArea.containsMouse ? Rock.cream : Rock.yellow
                        border.width: 2
                        border.color: Rock.ink
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Lbl {
                            id: actLbl
                            anchors.centerIn: parent
                            text: actBtn.modelData.text
                            color: Rock.ink
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

        // ───────── режим ЛАУНЧЕРА: поиск и запуск приложений ─────────
        ColumnLayout {
            id: launchBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            width: centerIsland.launchW - 24
            spacing: 4
            opacity: centerIsland.launchMode ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }

            readonly property string mode: UI.launcherMode
            readonly property var results: mode === "clip" ? Clip.search(searchInput.text)
                                         : (mode === "windows" ? Wins.search(searchInput.text)
                                                               : Apps.search(searchInput.text))

            function launch(e) {
                UI.launcher = false
                if (e.kind === "clip") Clip.paste(e)
                else if (e.kind === "window") Wins.focus(e)
                else Apps.launch(e)
            }

            Connections {
                target: centerIsland
                function onLaunchModeChanged() {
                    if (centerIsland.launchMode) {
                        if (UI.launcherMode === "clip") Clip.reload()
                        searchInput.text = ""
                        resultList.currentIndex = 0
                        Qt.callLater(() => searchInput.forceActiveFocus())
                    }
                }
            }

            // строка поиска
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 10

                Lbl {
                    text: launchBox.mode === "clip" ? "\uf0ea" : (launchBox.mode === "windows" ? "\uf2d0" : "\uf002")
                    color: Rock.pinkDeep
                    font.pixelSize: 13
                    Layout.leftMargin: 6
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Rock.ink
                    font.family: Rock.mono
                    font.pixelSize: 14
                    selectionColor: Rock.pink
                    selectedTextColor: Rock.cream
                    selectByMouse: true
                    clip: true
                    onTextChanged: resultList.currentIndex = 0

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier
                        const n = launchBox.results.length
                        if (event.key === Qt.Key_Escape) {
                            UI.launcher = false; event.accepted = true
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                                   || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                            resultList.currentIndex = Math.min(n - 1, resultList.currentIndex + 1); event.accepted = true
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                                   || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                            resultList.currentIndex = Math.max(0, resultList.currentIndex - 1); event.accepted = true
                        } else if (event.key === Qt.Key_Delete && launchBox.mode === "windows") {
                            // Delete — закрыть выбранное окно
                            if (n > 0) { Wins.close(launchBox.results[resultList.currentIndex]); UI.launcher = false }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (n > 0) launchBox.launch(launchBox.results[resultList.currentIndex])
                            event.accepted = true
                        }
                    }

                    Lbl {
                        visible: searchInput.text === ""
                        text: launchBox.mode === "clip" ? "Буфер обмена…" : (launchBox.mode === "windows" ? "Переключить окно…" : "Приложение, 2+2, ? поиск, > команда")
                        color: Rock.a(Rock.ink, 0.45)
                        font.pixelSize: 14
                    }
                }

                Lbl {
                    visible: launchBox.results.length > 0
                    text: "\u21b5"
                    color: Rock.a(Rock.ink, 0.45)
                    font.pixelSize: 12
                    Layout.rightMargin: 6
                }
            }

            // результаты
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.preferredHeight: count * 40
                interactive: false
                clip: true
                model: launchBox.results
                currentIndex: 0
                highlightMoveDuration: 80

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: resultList.width
                    height: 40
                    radius: 8
                    color: ListView.isCurrentItem
                        ? Rock.a(Rock.pink, 0.18)
                        : "transparent"
                    border.width: ListView.isCurrentItem ? 1.5 : 0
                    border.color: Rock.a(Rock.ink, 0.35)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 12
                        Item {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Image {
                                anchors.fill: parent
                                source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon) : ""
                                sourceSize: Qt.size(44, 44)
                                smooth: true
                                visible: status === Image.Ready
                            }
                            Lbl {
                                anchors.centerIn: parent
                                visible: !!row.modelData.glyph && !row.modelData.icon
                                text: row.modelData.glyph || ""
                                color: Rock.pinkDeep
                                font.pixelSize: 15
                            }
                        }
                        Lbl {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: Rock.ink
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Lbl {
                            Layout.maximumWidth: 200
                            text: row.modelData.comment || row.modelData.genericName || ""
                            color: Rock.a(Rock.ink, 0.55)
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: resultList.currentIndex = row.index
                        onClicked: launchBox.launch(row.modelData)
                    }
                }
            }
        }

        // полоска оставшегося времени (для уведомлений и событий)
        Rectangle {
            visible: (centerIsland.eventMode && UI.eventKind !== "level") || (centerIsland.notifMode && Notifs.duration > 0)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, (centerIsland.width - 56) * centerIsland.ttlFrac)
            height: 3
            radius: 1.5
            color: centerIsland.cream ? Rock.pink : Rock.yellow
        }
        NumberAnimation {
            id: ttlAnim
            target: centerIsland
            property: "ttlFrac"
            from: 1; to: 0
            duration: centerIsland.notifMode ? Math.max(1, Notifs.duration) : UI.eventTotal
            paused: centerIsland.notifMode ? Notifs.hold : UI.eventHold
        }
    }

    // ───────── Правый остров ─────────
    BarIsland {
        id: rightIsland
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Theme.islandInset
        fill: Rock.ink2
        shadowColor: Rock.cyan
        tilt: 0.8

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
            Lbl { text: "\uf132"; color: Rock.cyan; font.pixelSize: Theme.iconSize }
            Lbl {
                Layout.maximumWidth: 90
                text: Net.vpnName
                color: Rock.a(Rock.cream, 0.55)
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // Обои и тема
        Pill {
            interactive: true
            onClicked: { UI.launcher = false; UI.session = false; UI.wallpaper = !UI.wallpaper }
            Lbl { text: "\uf1fc"; color: Rock.a(Rock.cream, 0.55); font.pixelSize: Theme.iconSize }
        }

        // Раскладка клавиатуры
        Pill {
            interactive: true
            onClicked: Kb.next()
            Lbl {
                text: Kb.layout
                color: Rock.cream
                font.family: Rock.display
                font.weight: Font.Black
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
                color: Rock.yellow
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Quick.night
                text: "\uf186"
                color: Rock.purple
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                text: Net.icon
                color: Net.connected ? Rock.cream : Rock.a(Rock.cream, 0.4)
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: bar.btAdapter !== null
                text: "\uf293"
                color: Bt.connected.length > 0 ? Rock.cyan
                     : (bar.btAdapter && bar.btAdapter.enabled ? Rock.cream : Rock.a(Rock.cream, 0.4))
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                text: bar.volIcon()
                color: (bar.sink && bar.sink.audio && bar.sink.audio.muted) ? Rock.a(Rock.cream, 0.4) : Rock.cream
                font.pixelSize: Theme.iconSize
            }
            RowLayout {
                visible: bar.bat.isLaptopBattery
                spacing: 5
                Lbl {
                    text: bar.batIcon()
                    color: bar.bat.percentage < 0.2 ? Rock.pink : Rock.cream
                    font.pixelSize: Theme.iconSize
                }
                Lbl {
                    text: Math.round(bar.bat.percentage * 100)
                    color: Rock.a(Rock.cream, 0.55)
                }
                Lbl {
                    visible: text !== ""
                    text: bar.watts()
                    color: bar.bat.state === UPowerDeviceState.Charging ? Rock.cyan : Rock.a(Rock.cream, 0.55)
                    font.pixelSize: 10
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
                color: Notifs.dnd ? Rock.pink : (Notifs.count > 0 ? Rock.yellow : Rock.a(Rock.cream, 0.45))
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Notifs.count > 0
                text: Notifs.count
                color: Rock.yellow
                font.bold: true
            }
        }
    }
}
