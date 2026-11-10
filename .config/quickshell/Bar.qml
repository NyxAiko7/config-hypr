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

    readonly property bool v: PanelConfig.vertical
    readonly property bool atBottom: PanelConfig.atBottom
    readonly property bool atLeft: PanelConfig.atLeft
    readonly property bool atRight: PanelConfig.atRight
    readonly property int vThickness: Theme.barHeight + 2

    WlrLayershell.namespace: "qs-bar"
    anchors {
        top: !atBottom
        bottom: v || atBottom
        left: !atRight
        right: !atLeft
    }
    margins {
        top: v ? 10 : (atBottom ? 0 : 8)
        bottom: v ? 10 : (atBottom ? 8 : 0)
        left: atLeft ? 8 : (v ? 0 : 10)
        right: atRight ? 8 : (v ? 0 : 10)
    }

    // окно выше самой панели — чтобы остров мог расти вниз.
    // Резервируется только высота панели; клики принимают острова,
    // а пустое пространство между ними перехватывается только когда
    // открыто какое-то меню — клик мимо закрывает его.
    implicitWidth: v ? 470 : 0
    implicitHeight: v ? 0 : 470
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.keyboardFocus: launcherHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: launcherHere ? WlrLayer.Overlay : WlrLayer.Top
    exclusiveZone: v ? vThickness : Theme.barHeight
    color: "transparent"
    mask: Region {
        item: leftIsland
        Region { item: centerIsland }
        Region { item: rightIsland }
        Region { item: notifToast }
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

    readonly property var musicPanel:   musicPopup
    readonly property var calendarPanel: calendarPopup
    readonly property var controlPanel:  controlCenter
    readonly property var notifPanel:    notifCenter

    readonly property bool anyPopupOpen: musicPanel.visible || calendarPanel.visible
                                         || weatherPopup.visible || controlPanel.visible
                                         || notifPanel.visible || UI.anyPopupOpen

    // клик по пустому месту панели — закрыть всё открытое
    function closeAllPopups() {
        musicPopup.visible = false
        calendarPopup.visible = false
        weatherPopup.visible = false
        controlCenter.visible = false
        notifCenter.visible = false
        helpPopup.visible = false
        UI.launcher = false
        UI.settings = false
        // подложка-оверлей (обои/сессия) сама ловит клики мимо — не трогаем,
        // иначе её окно перехватит второй клик и панель «застрянет»
    }

    Connections {
        target: UI
        function onToggleCenter() { notifPanel.toggle() }
        function onToggleHelp() { helpPopup.toggle() }
        // клик мимо по панели: закрываем меню, только если оверлея нет
        function onClosePopups() { if (!UI.wallpaper && !UI.session) bar.closeAllPopups() }
    }

    function toastX(t) {
        if (bar.v) {
            return bar.atRight
                ? (bar.width - t.width - 18 + (Notifs.current !== null ? t.slide : t.width + 70))
                : (bar.vThickness + 22 - (Notifs.current !== null ? t.slide : -(t.width + 70)))
        }
        return (bar.width - t.width - 18) + (Notifs.current !== null ? t.slide : t.width + 70)
    }

    function toastY(t) {
        if (bar.v) return 18
        return bar.atBottom ? (bar.height - Theme.barHeight - t.height - 14) : (Theme.barHeight + 14)
    }

    function runEventAction(a) {
        if (a === "media") musicPanel.toggle()
        else if (a === "bt") { controlPanel.page = "bt"; controlPanel.toggle() }
        else if (a === "wifi") { controlPanel.page = "wifi"; controlPanel.toggle() }
        else if (a === "cc") controlPanel.toggle()
        else if (a === "notifs") notifPanel.toggle()
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
        return w >= 0.5 ? w.toFixed(1) + I18n.t(" Вт") : ""
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
        width: bar.v ? Theme.barHeight : parent.width
        height: bar.v ? parent.height : Theme.barHeight
        x: bar.v ? (bar.atRight ? parent.width - width : 0) : 0
        y: bar.v ? 0 : (bar.atBottom ? parent.height - height : 0)

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
        anchors.left: (!bar.v || bar.atLeft) ? parent.left : undefined
        anchors.right: (bar.v && bar.atRight) ? parent.right : undefined
        anchors.top: bar.atBottom ? undefined : parent.top
        anchors.bottom: bar.atBottom ? parent.bottom : undefined
        anchors.topMargin: bar.atBottom ? 0 : (bar.v ? 0 : Theme.islandInset)
        anchors.bottomMargin: bar.atBottom ? Theme.islandInset : 0
        fill: Rock.islandFill
        shadowColor: Rock.gold
        tilt: 0

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
            visible: PanelConfig.showWorkspaces
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool occupied: modelData.windows !== undefined
                        && modelData.windows.values.length > 0
                    visible: modelData.id > 0
                    Layout.preferredWidth: Rock.marisa ? (modelData.focused ? 19 : 12)
                                           : Rock.sao ? (modelData.focused ? 14 : 10)
                                                      : (modelData.focused ? 20 : 6)
                    Layout.preferredHeight: Rock.marisa ? 16 : Rock.sao ? 10 : 6
                    radius: Rock.marisa ? 0 : Rock.sao ? 1 : 3
                    rotation: Rock.sao ? 45 : 0
                    border.width: Rock.sao ? 1 : 0
                    border.color: Rock.sao
                        ? (modelData.focused ? Rock.gold
                           : (occupied ? Rock.a(Rock.gold, 0.55) : Rock.a(Rock.gold, 0.22)))
                        : "transparent"
                    // занятые (есть окна) горят бирюзой, пустые — тусклым контуром.
                    // В гримуаре Марисы рабочие столы — звёзды: зажжённая, пустая или занятая.
                    color: Rock.marisa ? "transparent"
                           : Rock.sao ? (modelData.focused ? Rock.a(Rock.gold, 0.28) : "transparent")
                                      : (modelData.focused ? Rock.pinkDeep
                                         : (occupied ? Rock.cyan : Rock.a(Rock.uiText, 0.22)))
                    opacity: Rock.marisa || Rock.sao ? 1 : (modelData.focused ? 1 : 0.9)
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 220 } }
                    Text {
                        anchors.centerIn: parent
                        visible: Rock.marisa
                        text: modelData.focused ? "✦" : (parent.occupied ? "✧" : "·")
                        color: modelData.focused ? Rock.gold
                               : (parent.occupied ? Rock.a(Rock.barText, 0.55) : Rock.a(Rock.barText, 0.22))
                        font.pixelSize: modelData.focused ? 16 : 11
                        font.weight: Font.Black
                    }
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
            visible: Recorder.recording && PanelConfig.modules.record
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
            Lbl { visible: !bar.v; text: Recorder.text(); color: Rock.pinkDeep; font.bold: true }
        }

        // Таймер фокуса: клик — старт/стоп, ПКМ — следующая фаза
        Pill {
            visible: PanelConfig.modules.pomodoro
            interactive: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) { if (Pomodoro.running) Pomodoro.skip(); else Pomodoro.start("break") }
                else if (Pomodoro.running) Pomodoro.stop()
                else Pomodoro.start("focus")
            }
            Lbl {
                text: Pomodoro.mode === "break" ? "\uf0f4" : "\uf017"
                color: Pomodoro.mode === "focus" ? Rock.pinkDeep : (Pomodoro.mode === "break" ? Rock.cyan : Rock.a(Rock.uiText, 0.4))
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: Pomodoro.running && !bar.v
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
            visible: PanelConfig.showTitle && status === Image.Ready
        }
        Lbl {
            visible: PanelConfig.showTitle && !bar.v
            Layout.leftMargin: winIcon.visible ? 0 : 6
            Layout.rightMargin: 8
            Layout.maximumWidth: 220
            text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
            color: Rock.a(Rock.uiText, 0.58)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    // ═════════ Центральный остров: часы · погода · события ═════════
    Item {
        id: centerIsland
        anchors.left: (bar.v && bar.atLeft) ? parent.left : undefined
        anchors.right: (bar.v && bar.atRight) ? parent.right : undefined
        anchors.horizontalCenter: bar.v ? undefined : parent.horizontalCenter
        anchors.top: (!bar.v && !bar.atBottom) ? parent.top : undefined
        anchors.bottom: (!bar.v && bar.atBottom) ? parent.bottom : undefined
        anchors.verticalCenter: bar.v ? parent.verticalCenter : undefined
        anchors.topMargin: (!bar.v && !bar.atBottom) ? Theme.islandInset : 0
        anchors.bottomMargin: (!bar.v && bar.atBottom) ? Theme.islandInset : 0

        property real ttlFrac: 0

        readonly property bool launchMode: bar.launcherHere
        readonly property bool eventMode: !launchMode && UI.eventActive
        readonly property color eventAccent: Rock.uiAccent
        readonly property color eventTone: {
            switch (UI.eventKind) {
            case "media":     return Rock.accent2
            case "battery":   return Rock.orange
            case "rec":       return Rock.orange
            case "net":
            case "wifi":
            case "bt":
            case "weather":   return Rock.cyan
            case "theme":
            case "wallpaper": return Rock.accent
            default:          return Rock.accent
            }
        }
        readonly property string eventCategory: {
            switch (UI.eventKind) {
            case "media":     return I18n.t("СЕЙЧАС ИГРАЕТ")
            case "level":     return Levels.kind === "brightness" ? I18n.t("ЭКРАН") : I18n.t("ЗВУК")
            case "theme":     return I18n.t("ОФОРМЛЕНИЕ")
            case "wallpaper": return I18n.t("ОБОИ")
            case "battery":   return I18n.t("ПИТАНИЕ")
            case "net":
            case "wifi":      return I18n.t("СЕТЬ")
            case "bt":        return "BLUETOOTH"
            case "layout":    return I18n.t("РАСКЛАДКА")
            case "notif":     return I18n.t("УВЕДОМЛЕНИЯ")
            case "weather":   return I18n.t("ПОГОДА")
            case "rec":       return I18n.t("ЗАПИСЬ")
            default:          return I18n.t("СИСТЕМА")
            }
        }
        readonly property string eventTitle: UI.eventKind === "level"
            ? (Levels.kind === "brightness" ? I18n.t("Яркость") : (Levels.muted ? I18n.t("Без звука") : I18n.t("Громкость")))
            : UI.eventText
        readonly property string eventSubtitle: UI.eventKind === "level"
            ? (Rock.comic ? "KESSOKU MIX" : Rock.marisa ? "SPARK LEVEL" : "ASTRAL LEVEL")
            : UI.eventSub

        readonly property real launchW: {
            const avail = bar.v ? bar.width : (bar.screen ? bar.screen.width : bar.width)
            return Math.max(420, Math.min(580, avail - (bar.v ? 40 : 760)))
        }

        width: launchMode ? launchW
             : (eventMode ? eventRow.width + 30
             : Math.max(bar.v ? 40 : 0, clockGroup.implicitWidth + (bar.v ? 16 : 28)))
        height: launchMode ? launchBox.implicitHeight + 16
              : (eventMode ? Math.max(Theme.islandHeight, eventRow.implicitHeight + 22)
              : (bar.v ? Math.max(Theme.islandHeight, clockGroup.implicitHeight + 16)
                       : Theme.islandHeight))
        property real radiusNow: launchMode ? Rock.panelRadius + 5
                                  : (eventMode ? Rock.panelRadius + 2 : Rock.panelRadius)
        readonly property bool cream: launchMode
        clip: false

        Behavior on width  { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on radiusNow { NumberAnimation { duration: 260 } }

        IslandSurface {
            anchors.fill: parent
            radius: centerIsland.radiusNow
            fill: centerIsland.launchMode ? Rock.uiSurface : Rock.islandFill
            shadowColor: centerIsland.eventMode ? centerIsland.eventTone : Rock.gold
            accent: centerIsland.eventMode ? centerIsland.eventTone : Rock.uiAccent
            shadowOffset: 0
            active: centerIsland.launchMode || centerIsland.eventMode
            pulse: centerIsland.eventMode
        }

        // подвеска-звезда под островом — только в гримуаре Марисы
        Item {
            visible: Rock.marisa && !bar.v && !centerIsland.launchMode && !centerIsland.eventMode
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -1
            width: 16
            height: 18

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 1
                height: 6
                color: Rock.a(Rock.gold, 0.65)
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                width: 12
                height: 12
                radius: 2
                rotation: 45
                color: Rock.ink2
                border.width: 1
                border.color: Rock.gold
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 4
                text: "M"
                color: Rock.gold
                font.family: Rock.display
                font.pixelSize: 9
                font.weight: Font.Black
            }
        }

        // HUD-маяк Aincrad под островом
        Item {
            visible: Rock.sao && !bar.v && !centerIsland.launchMode && !centerIsland.eventMode
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -1
            width: 18
            height: 20

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 1
                height: 7
                color: Rock.a(Rock.gold, 0.7)
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: 9
                height: 9
                rotation: 45
                color: Rock.a(Rock.gold, 0.18)
                border.width: 1
                border.color: Rock.gold
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 6
                width: 3
                height: 3
                rotation: 45
                color: Rock.starlight
            }
        }

        Connections {
            target: UI
            function onEventKeyChanged() { ttlAnim.restart() }
        }

        // Клики по острову, пока он в режиме события.
        // Лежит ниже содержимого, поэтому кнопки внутри работают сами.
        MouseArea {
            anchors.fill: parent
            enabled: centerIsland.eventMode
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
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
            enabled: centerIsland.eventMode
            onHoveredChanged: UI.eventHold = hovered && UI.eventActive
        }

        // ───────── обычный режим ─────────
        GridLayout {
            id: clockGroup
            anchors.centerIn: parent
            flow: bar.v ? GridLayout.TopToBottom : GridLayout.LeftToRight
            columns: bar.v ? 1 : 1000
            rowSpacing: bar.v ? 5 : 2
            columnSpacing: bar.v ? 5 : 2
            opacity: (centerIsland.launchMode || centerIsland.eventMode) ? 0 : 1
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Подключённые Bluetooth-устройства: иконка и заряд
            Pill {
                id: btPill
                interactive: true
                visible: Bt.connected.length > 0 && PanelConfig.modules.bt
                onClicked: { controlPanel.page = "bt"; controlPanel.toggle() }
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
                            color: Bt.percent(btItem.modelData) <= 20 ? Rock.pink : Rock.a(Rock.barText, 0.55)
                            font.pixelSize: 11
                        }
                    }
                }
            }

            MiniMedia {
                id: miniPill
                visible: PanelConfig.modules.music && miniPill.p !== null
                onOpenRequested: musicPanel.toggle()
            }

            Pill {
                id: clockPill
                interactive: true
                onClicked: calendarPanel.toggle()
                // Часы как на локскрине: объёмное время с цветными слоями,
                // рядом — жёлтый стикер с датой и розовый с секундами.
                Lbl {
                    visible: Rock.marisa
                    text: "✦"
                    color: Rock.gold
                    font.pixelSize: 9
                }
                Item {
                    Layout.preferredWidth: clockTime.width
                    Layout.preferredHeight: clockTime.height

                    Text {
                        x: 2; y: 2
                        text: clockTime.text
                        color: Rock.marisa ? Rock.pink : Rock.pinkDeep
                        font.family: Rock.display
                        font.pixelSize: bar.v ? 12 : 16
                        font.weight: Font.Black
                        font.letterSpacing: -0.5
                    }
                    Text {
                        x: 1; y: 1
                        text: clockTime.text
                        color: Rock.marisa ? Rock.gold : Rock.cyan
                        font.family: Rock.display
                        font.pixelSize: bar.v ? 12 : 16
                        font.weight: Font.Black
                        font.letterSpacing: -0.5
                    }
                    Text {
                        id: clockTime
                        text: Qt.formatDateTime(barClock.date, "HH:mm")
                        color: Rock.marisa ? Rock.barText : Rock.cream
                        font.family: Rock.display
                        font.pixelSize: bar.v ? 12 : 16
                        font.weight: Font.Black
                        font.letterSpacing: -0.5
                    }
                }

                RockChip {
                    visible: !bar.v && !Rock.marisa
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
                    visible: !bar.v && !Rock.marisa
                    fill: Rock.pink
                    shadowColor: Rock.cyan
                    offset: 1.5
                    padH: 7
                    padV: 2
                    radius: 6
                    Lbl {
                        text: Qt.formatDateTime(barClock.date, "ss")
                        color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                        font.pixelSize: 10
                        font.weight: Font.Black
                    }
                }

                ColumnLayout {
                    visible: Rock.marisa && !bar.v
                    spacing: -3
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(barClock.date, "ddd").toUpperCase()
                        color: Rock.barSub
                        font.family: Rock.display
                        font.pixelSize: 7
                        font.bold: true
                        font.letterSpacing: 1.4
                    }
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(barClock.date, "d MMM")
                        color: Rock.barText
                        font.family: Rock.display
                        font.pixelSize: 8
                        font.italic: true
                    }
                }
                Item {
                    visible: Rock.marisa && !bar.v
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Rectangle {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        radius: 2
                        rotation: 45
                        color: Rock.a(Rock.pink, 0.16)
                        border.width: 1
                        border.color: Rock.pinkDeep
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(barClock.date, "ss")
                        color: Rock.pinkDeep
                        font.family: Rock.display
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
            }
            Pill {
                id: weatherPill
                interactive: true
                visible: Weather.ready && PanelConfig.modules.weather
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
                    color: Rock.marisa ? Rock.barText : Rock.cream
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 13
                }
                // вероятность осадков в ближайшие часы — если есть, то сразу видно
                Lbl {
                    visible: Weather.nextPrecip > 0
                    text: "\uf043 " + Weather.nextPrecip + "%"
                    color: Weather.nextPrecip >= 40 ? Rock.pink : Rock.a(Rock.barText, 0.55)
                    font.pixelSize: 10
                }
            }
        }

        // ───────── режим события ─────────
        ColumnLayout {
            id: eventRow
            anchors.centerIn: parent
            width: Math.min(440, Math.max(334, (bar.screen ? bar.screen.width : 860) * 0.27))
            spacing: 10
            opacity: centerIsland.eventMode ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 220 } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Item {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: 52
                        height: 52
                        radius: 26
                        color: Rock.a(centerIsland.eventTone, 0.10)
                        border.width: 1
                        border.color: Rock.a(centerIsland.eventTone, 0.18)
                    }

                    Canvas {
                        id: outerScanner
                        anchors.centerIn: parent
                        width: 54
                        height: 54
                        property color tone: centerIsland.eventTone
                        onToneChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            const cx = width / 2
                            const cy = height / 2
                            ctx.strokeStyle = tone
                            ctx.lineWidth = 2
                            ctx.lineCap = "round"
                            for (let i = 0; i < 12; i++) {
                                const a0 = i * Math.PI / 6
                                ctx.beginPath()
                                ctx.arc(cx, cy, 24, a0, a0 + Math.PI / 12)
                                ctx.stroke()
                            }
                        }

                        RotationAnimation on rotation {
                            running: centerIsland.eventMode
                            from: 0
                            to: 360
                            duration: 12000
                            loops: Animation.Infinite
                        }
                    }

                    Canvas {
                        id: innerScanner
                        anchors.centerIn: parent
                        width: 46
                        height: 46
                        property color tone: centerIsland.eventTone
                        onToneChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            const cx = width / 2
                            const cy = height / 2
                            ctx.strokeStyle = tone
                            ctx.globalAlpha = 0.55
                            ctx.lineWidth = 1.5
                            ctx.lineCap = "round"
                            for (let i = 0; i < 8; i++) {
                                const a0 = i * Math.PI / 4
                                ctx.beginPath()
                                ctx.arc(cx, cy, 19, a0, a0 + Math.PI / 10)
                                ctx.stroke()
                            }
                        }

                        RotationAnimation on rotation {
                            running: centerIsland.eventMode
                            from: 360
                            to: 0
                            duration: 8500
                            loops: Animation.Infinite
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        radius: 18
                        color: Rock.uiSurface2
                        border.width: 1
                        border.color: Rock.a(centerIsland.eventTone, 0.55)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Rock.a(centerIsland.eventTone, 0.30) }
                            GradientStop { position: 1.0; color: Rock.a(Rock.uiSurface2, 0.75) }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: 16
                        color: Rock.uiSurface2
                        visible: evArt.status !== Image.Ready || UI.eventKind === "level"
                    }

                    Image {
                        id: evArt
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: UI.eventArt
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready && UI.eventKind !== "level"
                    }

                    Lbl {
                        anchors.centerIn: parent
                        visible: evArt.status !== Image.Ready || UI.eventKind === "level"
                        text: UI.eventIcon
                        color: centerIsland.eventTone
                        font.pixelSize: 15
                    }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 1.5
                        rotation: 45
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 1
                        anchors.rightMargin: 2
                        color: centerIsland.eventTone
                        border.width: 1
                        border.color: Rock.a(Rock.cream, 0.7)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: centerIsland.eventTone
                            SequentialAnimation on opacity {
                                running: centerIsland.eventMode
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 620 }
                                NumberAnimation { to: 1; duration: 620 }
                            }
                        }

                        Lbl {
                            Layout.fillWidth: true
                            text: centerIsland.eventCategory
                            color: centerIsland.eventTone
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 1.4
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 4
                            height: 4
                            radius: 1
                            rotation: 45
                            color: Rock.a(centerIsland.eventTone, 0.6)
                        }
                    }

                    Lbl {
                        Layout.fillWidth: true
                        text: centerIsland.eventTitle
                        color: Rock.cream
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 15
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Lbl {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: centerIsland.eventSubtitle
                        color: Rock.a(Rock.cream, 0.52)
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    ColumnLayout {
                        visible: UI.eventKind === "level"
                        spacing: -3

                        Lbl {
                            Layout.alignment: Qt.AlignRight
                            text: Levels.muted ? "—" : Math.round(Levels.value * 100)
                            color: centerIsland.eventTone
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 24
                        }

                        Lbl {
                            Layout.alignment: Qt.AlignRight
                            text: Levels.kind === "brightness" ? "LUX" : "VOL"
                            color: Rock.a(Rock.cream, 0.35)
                            font.pixelSize: 7
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                    }

                    Row {
                        visible: UI.eventKind !== "level"
                        Layout.alignment: Qt.AlignRight
                        spacing: 3

                        Repeater {
                            model: 5
                            delegate: Item {
                                id: eq
                                required property int index
                                width: 3
                                height: 18

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    radius: 1.5
                                    height: 4 + ((eq.index * 5 + 3) % 12)
                                    color: centerIsland.eventTone
                                    opacity: 0.45 + (eq.index % 3) * 0.22
                                    SequentialAnimation on height {
                                        loops: Animation.Infinite
                                        running: centerIsland.eventMode && UI.eventKind === "media"
                                        NumberAnimation { to: 16; duration: 240 + eq.index * 80; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 4;  duration: 280 + eq.index * 65; easing.type: Easing.InOutSine }
                                    }
                                }
                            }
                        }
                    }

                    Lbl {
                        visible: UI.eventKind === "media" && Media.player !== null
                        Layout.alignment: Qt.AlignRight
                        text: bar.fmtTime(Media.player ? Media.player.position : 0) + " / " + bar.fmtTime(Media.player ? Media.player.length : 0)
                        color: Rock.a(Rock.cream, 0.55)
                        font.pixelSize: 8
                    }

                    Row {
                        visible: UI.eventKind !== "level" && UI.eventKind !== "media"
                        Layout.alignment: Qt.AlignRight
                        spacing: 4

                        Lbl {
                            text: "LINK"
                            color: Rock.a(centerIsland.eventTone, 0.55)
                            font.pixelSize: 7
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        Item {
                            width: 4
                            height: 10

                            Rectangle {
                                anchors.centerIn: parent
                                width: 4
                                height: 4
                                radius: 2
                                color: centerIsland.eventTone
                                SequentialAnimation on opacity {
                                    running: centerIsland.eventMode
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.2; duration: 700 }
                                    NumberAnimation { to: 1; duration: 700 }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: timeline
                Layout.fillWidth: true
                Layout.preferredHeight: 8

                readonly property int n: 36

                Repeater {
                    model: timeline.n
                    delegate: Rectangle {
                        required property int index
                        readonly property real step: (timeline.width + 2) / timeline.n
                        x: index * step
                        width: Math.max(2, step - 2)
                        height: index % 6 === 0 ? 6 : 3
                        y: (timeline.height - height) / 2
                        radius: 1.5
                        color: index / (timeline.n - 1) <= centerIsland.ttlFrac
                            ? (index % 6 === 0 ? centerIsland.eventTone
                                               : Rock.a(centerIsland.eventTone, 0.72))
                            : Rock.a(centerIsland.cream, 0.10)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                Rectangle {
                    width: 8
                    height: 8
                    radius: 1.5
                    rotation: 45
                    x: Math.max(0, Math.min(timeline.width - width,
                                            centerIsland.ttlFrac * timeline.width - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    color: centerIsland.eventTone
                    border.width: 1
                    border.color: Rock.a(centerIsland.cream, 0.35)
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
            spacing: 6
            opacity: (centerIsland.launchMode && !Rock.sao) ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }

            readonly property string mode: UI.launcherMode
            readonly property string glyph: mode === "clip" ? "\uf0ea" : (mode === "windows" ? "\uf2d0" : "\uf303")
            readonly property var results: mode === "clip" ? Clip.search(searchInput.text)
                                         : (mode === "windows" ? Wins.search(searchInput.text)
                                                               : Apps.search(searchInput.text))

            function launch(e) {
                UI.launcher = false
                if (e.kind === "clip") Clip.paste(e)
                else if (e.kind === "window") Wins.focus(e)
                else Apps.launch(e)
            }

            // переключить режим на месте, не закрывая лаунчер
            function setMode(m) {
                if (UI.launcherMode === m) return
                UI.launcherMode = m
                if (m === "clip") Clip.reload()
                searchInput.text = ""
                resultList.currentIndex = 0
                Qt.callLater(() => searchInput.forceActiveFocus())
            }

            // ctrl+tab листает режимы по кругу
            function cycleMode(back) {
                const order = ["apps", "windows", "clip"]
                const i = order.indexOf(UI.launcherMode)
                setMode(order[(i + (back ? order.length - 1 : 1)) % order.length])
            }

            Connections {
                target: centerIsland
                function onLaunchModeChanged() {
                    if (centerIsland.launchMode && !Rock.sao) {
                        if (UI.launcherMode === "clip") Clip.reload()
                        searchInput.text = ""
                        resultList.currentIndex = 0
                        Qt.callLater(() => searchInput.forceActiveFocus())
                    }
                }
            }

            // переключатель режимов: запуск · окна · буфер
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { key: "apps", label: I18n.t("ЗАПУСК"), glyph: "\uf303" },
                        { key: "windows", label: I18n.t("ОКНА"), glyph: "\uf2d0" },
                        { key: "clip", label: I18n.t("БУФЕР"), glyph: "\uf0ea" }
                    ]
                    delegate: Rectangle {
                        id: modeTab
                        required property var modelData
                        readonly property bool active: launchBox.mode === modeTab.modelData.key

                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Rock.uiRadiusSm
                        color: modeTab.active ? Rock.uiActive
                                              : (tabArea.containsMouse ? Rock.uiHover : Rock.a(Rock.uiSurface2, 0.55))
                        border.width: Rock.uiBorder
                        border.color: modeTab.active ? Rock.uiAccent : Rock.a(Rock.uiText, 0.16)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Lbl {
                                text: modeTab.modelData.glyph
                                color: modeTab.active ? Rock.uiAccent : Rock.a(Rock.uiText, 0.5)
                                font.pixelSize: 9
                            }
                            Lbl {
                                text: modeTab.modelData.label
                                color: modeTab.active ? Rock.uiText : Rock.a(Rock.uiText, 0.55)
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 9
                                font.letterSpacing: 0.6
                            }
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: launchBox.setMode(modeTab.modelData.key)
                        }
                    }
                }

                // сколько найдено прямо сейчас
                Lbl {
                    visible: launchBox.results.length > 0
                    text: "× " + launchBox.results.length
                    color: Rock.a(Rock.uiText, 0.4)
                    font.family: Rock.mono
                    font.pixelSize: 9
                }
            }

            // строка поиска
            Item {
                Layout.fillWidth: true
                implicitHeight: searchCard.height + 6

                Rectangle {
                    visible: Rock.comic
                    x: 4
                    y: 5
                    width: searchCard.width
                    height: searchCard.height
                    radius: 12
                    color: Rock.cyan
                    border.width: 2
                    border.color: Rock.ink
                }

                Rectangle {
                    id: searchCard
                    width: parent.width - 4
                    height: 40
                    radius: Rock.comic ? 12 : Rock.marisa ? 4 : 10
                    color: Rock.comic ? Rock.paper : Rock.uiSurface2
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 10
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: Rock.comic ? 8 : Rock.marisa ? 3 : 7
                            rotation: Rock.comic ? -4 : 0
                            color: Rock.pink
                            border.width: Rock.uiBorder
                            border.color: Rock.uiEdge
                            Lbl {
                                anchors.centerIn: parent
                                text: launchBox.glyph
                                color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                                font.pixelSize: 12
                                rotation: Rock.comic ? 4 : 0
                            }
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Rock.uiText
                            font.family: Rock.mono
                            font.pixelSize: 14
                            selectionColor: Rock.uiAccent
                            selectedTextColor: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                            selectByMouse: true
                            clip: true
                            onTextChanged: resultList.currentIndex = 0

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier
                                const n = launchBox.results.length
                                if (event.key === Qt.Key_Escape) {
                                    UI.launcher = false; event.accepted = true
                                } else if (ctrl && event.key === Qt.Key_Tab) {
                                    launchBox.cycleMode(false); event.accepted = true
                                } else if (ctrl && event.key === Qt.Key_Backtab) {
                                    launchBox.cycleMode(true); event.accepted = true
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
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: launchBox.mode === "clip"
                                    ? (Rock.marisa ? I18n.t("Раскрыть свиток…") : Rock.sao ? I18n.t("Открыть архив данных…") : I18n.t("Буфер обмена…"))
                                    : (launchBox.mode === "windows"
                                        ? (Rock.marisa ? I18n.t("Позвать окно…") : Rock.sao ? I18n.t("Выбрать окно…") : I18n.t("Переключить окно…"))
                                        : (Rock.marisa ? I18n.t("Назови заклинание, 2+2, ? поиск, > команда")
                                                       : Rock.sao ? I18n.t("Имя приложения, 2+2, ? поиск, > команда")
                                                                  : I18n.t("Приложение, 2+2, ? поиск, > команда")))
                                color: Rock.a(Rock.uiText, 0.45)
                                font.pixelSize: 13
                            }
                        }

                        Lbl {
                            visible: launchBox.results.length > 0
                            text: "\u21b5"
                            color: Rock.uiSub
                            font.pixelSize: 12
                            font.weight: Font.Black
                        }
                    }
                }
            }

            // результаты
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(count, 7) * 44
                interactive: count > 7
                clip: true
                model: launchBox.results
                currentIndex: 0
                highlightMoveDuration: 80
                boundsBehavior: Flickable.StopAtBounds
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    readonly property color tileColor: [Rock.pink, Rock.cyan, Rock.yellow, Rock.purple][row.index % 4]

                    width: resultList.width
                    height: 44

                    // сколько раз запускали это приложение (для звёздочки)
                    readonly property int freq: launchBox.mode === "apps" && row.modelData.id !== undefined
                        ? (Apps.counts[row.modelData.id] || 0) : 0

                    Rectangle {
                        visible: Rock.comic
                        x: 4
                        y: 5
                        width: card.width
                        height: card.height
                        radius: 10
                        color: row.current ? Rock.pink : Rock.a(Rock.ink, 0.10)
                        border.width: row.current ? 2 : 0
                        border.color: Rock.ink
                    }

                    Rectangle {
                        id: card
                        width: parent.width - 4
                        height: 39
                        radius: Rock.comic ? 10 : Rock.marisa ? 4 : 9
                        color: row.current ? (Rock.comic ? Rock.yellow : Rock.uiActive)
                                           : (rowArea.containsMouse ? Rock.uiHover : (Rock.comic ? Rock.cream : Rock.uiSurface2))
                        border.width: Rock.uiBorder
                        border.color: row.current ? Rock.uiEdge : Rock.a(Rock.uiText, 0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Rectangle {
                            visible: row.current
                            width: 6
                            height: parent.height - 10
                            radius: 3
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: Rock.uiAccent
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: row.current ? 16 : 10
                            anchors.rightMargin: 10
                            spacing: 9

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: Rock.comic ? 8 : Rock.marisa ? 3 : 7
                                rotation: Rock.comic ? (row.index % 2 === 0 ? -3 : 3) : 0
                                color: row.tileColor
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon) : ""
                                    sourceSize: Qt.size(44, 44)
                                    smooth: true
                                    visible: status === Image.Ready
                                }
                                Lbl {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.glyph && !row.modelData.icon
                                    text: row.modelData.glyph || ""
                                    color: Rock.comic ? (row.index % 4 === 2 ? Rock.ink : Rock.cream) : (Rock.marisa ? (row.index % 4 === 2 ? Rock.ink : Rock.cream) : Rock.ink)
                                    font.pixelSize: 13
                                    rotation: Rock.comic ? (row.index % 2 === 0 ? 3 : -3) : 0
                                }
                            }

                            Lbl {
                                Layout.fillWidth: true
                                text: row.modelData.name
                                color: Rock.uiText
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Lbl {
                                Layout.maximumWidth: 190
                                text: row.modelData.comment || row.modelData.genericName || ""
                                color: Rock.a(Rock.uiText, 0.55)
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                            Lbl {
                                // частые приложения помечены звездой
                                visible: row.freq >= 3
                                text: "\uf005"
                                color: Rock.yellow
                                font.pixelSize: 9
                            }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: card
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: resultList.currentIndex = row.index
                        onClicked: launchBox.launch(row.modelData)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 1
                spacing: 5

                Lbl { text: "↑↓"; color: Rock.pinkDeep; font.pixelSize: 9; font.weight: Font.Black }
                Lbl { text: I18n.t("выбор"); color: Rock.a(Rock.uiText, 0.5); font.pixelSize: 9 }
                Lbl { text: "·"; color: Rock.a(Rock.uiText, 0.3); font.pixelSize: 9 }
                Lbl { text: "ctrl tab"; color: Rock.pinkDeep; font.pixelSize: 8; font.weight: Font.Black }
                Lbl { text: I18n.t("режим"); color: Rock.a(Rock.uiText, 0.5); font.pixelSize: 9 }
                Item { Layout.fillWidth: true }
                Lbl { text: "↵"; color: Rock.pinkDeep; font.pixelSize: 9; font.weight: Font.Black }
                Lbl { text: I18n.t("запуск"); color: Rock.a(Rock.uiText, 0.5); font.pixelSize: 9 }
                Lbl { text: "·"; color: Rock.a(Rock.uiText, 0.3); font.pixelSize: 9 }
                Lbl { text: "esc"; color: Rock.pinkDeep; font.pixelSize: 9; font.weight: Font.Black }
            }
        }

        // скотч на постере лаунчера
        Rectangle {
            visible: centerIsland.launchMode && Rock.comic
            x: 20
            y: -6
            width: 68
            height: 16
            radius: 2
            color: Rock.a(Rock.yellow, 0.9)
            border.width: 1
            border.color: Rock.a(Rock.ink, 0.28)
            rotation: -7
            z: 20
        }
        Rectangle {
            visible: centerIsland.launchMode && Rock.comic
            x: centerIsland.width - 84
            y: -6
            width: 64
            height: 16
            radius: 2
            color: Rock.a(Rock.cyan, 0.8)
            border.width: 1
            border.color: Rock.a(Rock.ink, 0.28)
            rotation: 6
            z: 20
        }

        NumberAnimation {
            id: ttlAnim
            target: centerIsland
            property: "ttlFrac"
            from: 1; to: 0
            duration: UI.eventTotal
            paused: UI.eventHold
        }
    }

    // ───────── Уведомление-«фотография» на грифе ─────────
    NotifToast {
        id: notifToast
        notif: Notifs.current
        x: bar.toastX(notifToast)
        y: bar.toastY(notifToast)
        z: 60
        opacity: Notifs.current !== null ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 170 } }
    }

    // ───────── Правый остров ─────────
    BarIsland {
        id: rightIsland
        anchors.left: (bar.v && bar.atLeft) ? parent.left : undefined
        anchors.right: (!bar.v || bar.atRight) ? parent.right : undefined
        anchors.top: (!bar.v && !bar.atBottom) ? parent.top : undefined
        anchors.bottom: (bar.v || bar.atBottom) ? parent.bottom : undefined
        anchors.topMargin: (!bar.v && !bar.atBottom) ? Theme.islandInset : 0
        anchors.bottomMargin: (bar.v || bar.atBottom) ? Theme.islandInset : 0
        fill: Rock.islandFill
        shadowColor: Rock.cyan
        tilt: 0

        // Трей
        Pill {
            visible: PanelConfig.showTray && SystemTray.items.values.length > 0
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
                visible: !bar.v
                Layout.maximumWidth: 90
                text: Net.vpnName
                color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // Обои
        Pill {
            visible: PanelConfig.showWallpaper
            interactive: true
            onClicked: { UI.launcher = false; UI.session = false; UI.settings = false; UI.wallpaper = !UI.wallpaper }
            Lbl { text: "\uf1fc"; color: Rock.a(Rock.barText, 0.55); font.pixelSize: Theme.iconSize }
        }

        // Настройки панели
        Pill {
            visible: PanelConfig.showSettings
            interactive: true
            onClicked: {
                UI.launcher = false
                UI.session = false
                UI.wallpaper = false
                UI.settingsTab = "presets"
                UI.settings = true
            }
            Lbl { text: "\uf013"; color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55); font.pixelSize: Theme.iconSize }
        }

        // Раскладка клавиатуры
        Pill {
            visible: PanelConfig.showKeyboard
            interactive: true
            onClicked: Kb.next()
            Lbl {
                text: Kb.layout
                color: Rock.marisa ? Rock.barText : Rock.cream
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
                } else controlPanel.toggle()
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
                visible: PanelConfig.modules.net || PanelConfig.modules.wifi
                text: Net.icon
                color: Net.connected ? Rock.marisa ? Rock.barText : Rock.cream : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.4)
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: bar.btAdapter !== null && PanelConfig.modules.bt
                text: "\uf293"
                color: Bt.connected.length > 0 ? Rock.cyan
                     : (bar.btAdapter && bar.btAdapter.enabled ? Rock.marisa ? Rock.barText : Rock.cream : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.4))
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: PanelConfig.showVolume
                text: bar.volIcon()
                color: (bar.sink && bar.sink.audio && bar.sink.audio.muted) ? Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.4) : Rock.marisa ? Rock.barText : Rock.cream
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                visible: PanelConfig.showBattery && bar.bat.isLaptopBattery && bar.v
                text: bar.batIcon()
                color: bar.bat.percentage < 0.2 ? Rock.pink : Rock.marisa ? Rock.barText : Rock.cream
                font.pixelSize: Theme.iconSize
            }
            RowLayout {
                visible: PanelConfig.showBattery && bar.bat.isLaptopBattery && !bar.v
                spacing: 5
                Lbl {
                    text: bar.batIcon()
                    color: bar.bat.percentage < 0.2 ? Rock.pink : Rock.marisa ? Rock.barText : Rock.cream
                    font.pixelSize: Theme.iconSize
                }
                Lbl {
                    text: Math.round(bar.bat.percentage * 100)
                    color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
                }
                Lbl {
                    visible: text !== ""
                    text: bar.watts()
                    color: bar.bat.state === UPowerDeviceState.Charging ? Rock.cyan : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
                    font.pixelSize: 10
                }
            }
        }

        // Уведомления → центр уведомлений
        Pill {
            id: bellPill
            interactive: true
            visible: PanelConfig.modules.notif
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd
                else if (mouse.button === Qt.MiddleButton) Notifs.clearAll()
                else notifPanel.toggle()
            }
            Lbl {
                text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                color: Notifs.dnd ? Rock.pink : (Notifs.count > 0 ? Rock.yellow : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.45))
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

    // попап «Горячие клавиши»
    HelpPopup { id: helpPopup; barWindow: bar; anchorItem: rightIsland }
}
