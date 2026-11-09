import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Настройки оболочки: готовые пресеты панели, положение, модули,
// внешний вид и личные параметры.
PanelWindow {
    id: win

    visible: UI.settings
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-settings"
    WlrLayershell.keyboardFocus: UI.settings ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    readonly property color cardFill: Rock.uiSurface
    readonly property color fg: Rock.uiText
    readonly property color sub: Rock.uiSub
    readonly property color accent: Rock.uiAccent
    readonly property color frameEdge: Rock.uiEdge

    readonly property var tabOptions: [
        { key: "presets", label: I18n.t("ПРЕСЕТЫ"), icon: "\uf009" },
        { key: "bar",     label: I18n.t("ПАНЕЛЬ"),  icon: "\uf2d0" },
        { key: "modules", label: I18n.t("МОДУЛИ"),  icon: "\uf12e" },
        { key: "look",    label: I18n.t("ВИД"),     icon: "\uf120" },
        { key: "more",    label: I18n.t("ЕЩЁ"),     icon: "\uf013" }
    ]

    readonly property var positionOptions: [
        { key: "top",    label: I18n.t("СВЕРХУ") },
        { key: "bottom", label: I18n.t("СНИЗУ") },
        { key: "left",   label: I18n.t("СЛЕВА") },
        { key: "right",  label: I18n.t("СПРАВА") }
    ]

    readonly property var densityOptions: [
        { key: "compact", label: I18n.t("КОМПАКТНО") },
        { key: "normal",  label: I18n.t("ОБЫЧНО") },
        { key: "roomy",   label: I18n.t("ПРОСТОРНО") }
    ]

    readonly property var languageOptions: [
        { key: "ru", label: "RU" },
        { key: "en", label: "EN" }
    ]

    readonly property var presetList: [
        { key: "minimal",  icon: "\uf068", label: I18n.t("МИНИМАЛ"),
          hint: I18n.t("Только часы, сеть и уведомления") },
        { key: "balanced", icon: "\uf0c9", label: I18n.t("БАЛАНС"),
          hint: I18n.t("Все основные модули и кнопки") },
        { key: "media",    icon: "\uf001", label: I18n.t("МЕДИА"),
          hint: I18n.t("Музыка, погода и запись под рукой") },
        { key: "focus",    icon: "\uf017", label: I18n.t("ФОКУС"),
          hint: I18n.t("Помодоро и минимум отвлечений") }
    ]

    property string tab: "presets"

    onVisibleChanged: {
        if (visible) {
            tab = tabOptions.some(o => o.key === UI.settingsTab) ? UI.settingsTab : "presets"
            keys.forceActiveFocus()
            fade.restart()
        } else picking = false
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: {
            if (win.picking) win.picking = false
            else UI.settings = false
        }
    }

    // ───────── выбор файла аватара ─────────
    property bool picking: false
    property string browsePath: ""
    property var browseDirs: []
    property var browseFiles: []

    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
    }

    function startPick() {
        picking = true
        browse(browsePath !== "" ? browsePath : (Quickshell.env("HOME") + "/Pictures"))
    }

    function browse(p) {
        dirProc.command = ["sh", "-c",
            'p="$1"; [ -d "$p" ] || p="$HOME"; cd "$p" || exit 0; printf "%s\\n" "$PWD"; ' +
            'find . -mindepth 1 -maxdepth 1 -type d -printf "%f\\n" 2>/dev/null | sort',
            "sh", p]
        dirProc.running = true
    }

    function pickUp() {
        const p = browsePath.replace(/\/[^\/]*\/?$/, "")
        browse(p === "" ? "/" : p)
    }

    function chooseFile(p) {
        PanelConfig.setAvatar(p)
        picking = false
        keys.forceActiveFocus()
    }

    Process {
        id: dirProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                if (lines.length === 0) return
                win.browsePath = lines[0]
                win.browseDirs = lines.slice(1)
                listProc.command = ["sh", "-c",
                    'find "$1" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | ' +
                    'grep -iE "[.](jpe?g|png|webp|bmp|gif)$" | sort',
                    "sh", lines[0]]
                listProc.running = true
            }
        }
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: win.browseFiles = text.split("\n").filter(l => l.length > 0)
        }
    }

    // затемнение и клик мимо
    Rectangle {
        id: dim
        anchors.fill: parent
        color: Rock.a(Rock.ink, 0.84)
        MouseArea { anchors.fill: parent; onClicked: UI.settings = false }
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.45
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const step = Math.max(28, Math.min(width, height) / 46)
            ctx.fillStyle = Rock.a(Rock.uiAccent, 0.20)
            for (let y = 0; y < height; y += step)
                for (let x = 0; x < width; x += step) {
                    ctx.beginPath()
                    ctx.arc(x, y, step * 0.09, 0, Math.PI * 2)
                    ctx.fill()
                }
        }
    }

    // ───────── карточка ─────────
    Item {
        id: frame
        anchors.centerIn: parent
        width: Math.min(parent.width - 56, 860)
        height: Math.min(parent.height - 80, 660)
        opacity: 0
        scale: 0.96

        Rectangle {
            id: card
            width: frame.width
            height: frame.height
            radius: Math.max(10, Rock.uiRadius)
            color: win.cardFill
            border.width: Rock.uiBorder
            border.color: win.frameEdge

            MouseArea { anchors.fill: parent }

            SaoGrid { anchors.fill: parent; step: 28 }
            MarisaPattern { anchors.fill: parent; opacity: 0.5 }
            MarisaFrame {
                anchors.fill: parent
                inset: 7
                frameRadius: Math.max(2, card.radius - 5)
            }
            SaoFrame {
                anchors.fill: parent
                inset: 6
                cut: 12
                segments: 34
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                // ── шапка ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 8
                        height: 34
                        radius: 4
                        color: win.accent
                    }

                    ColumnLayout {
                        spacing: 1
                        Lbl {
                            text: I18n.t("НАСТРОЙКИ ПАНЕЛИ")
                            color: win.fg
                            font.family: Rock.display
                            font.pixelSize: 26
                            font.weight: Font.Black
                            font.letterSpacing: 1.2
                        }
                        Lbl {
                            text: "ASTRAL PANEL · PRESETS"
                            color: win.accent
                            font.pixelSize: 9
                            font.weight: Font.Black
                            font.letterSpacing: 1.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 34; height: 34
                        radius: 17
                        color: closeArea.containsMouse ? Rock.a(win.accent, 0.22) : "transparent"
                        border.width: closeArea.containsMouse ? 1 : 0
                        border.color: win.accent
                        Lbl {
                            anchors.centerIn: parent
                            text: "\uf00d"
                            color: win.fg
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: UI.settings = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    radius: 1
                    color: Rock.a(win.fg, 0.14)
                }

                // ── вкладки ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: win.tabOptions
                        delegate: Rectangle {
                            id: tabBtn
                            required property var modelData
                            readonly property bool sel: win.tab === modelData.key

                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Rock.uiRadiusSm
                            color: sel ? win.accent
                                       : (tabArea.containsMouse ? Rock.a(win.accent, 0.14) : Rock.a(win.fg, 0.05))
                            border.width: sel ? 0 : 1
                            border.color: Rock.a(win.fg, 0.18)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 7
                                Lbl {
                                    text: tabBtn.modelData.icon
                                    color: tabBtn.sel ? Rock.uiOnActive : win.sub
                                    font.pixelSize: 11
                                }
                                Lbl {
                                    text: tabBtn.modelData.label
                                    color: tabBtn.sel ? Rock.uiOnActive : win.sub
                                    font.family: Rock.display
                                    font.pixelSize: 11
                                    font.weight: Font.Black
                                    font.letterSpacing: 0.6
                                }
                            }

                            MouseArea {
                                id: tabArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.tab = tabBtn.modelData.key
                            }
                        }
                    }
                }

                // ── страницы ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // ═════════ ПРЕСЕТЫ ═════════
                    Flickable {
                        id: presetsPage
                        anchors.fill: parent
                        visible: win.tab === "presets"
                        clip: true
                        contentWidth: width
                        contentHeight: presetsCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: presetsCol
                            width: presetsPage.width
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                Lbl {
                                    text: I18n.t("ПРЕСЕТ ПАНЕЛИ")
                                    color: win.fg
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 13
                                    font.letterSpacing: 0.8
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    visible: PanelConfig.preset === "custom"
                                    implicitWidth: customLbl.implicitWidth + 18
                                    implicitHeight: 24
                                    radius: 12
                                    color: Rock.a(win.accent, 0.16)
                                    border.width: 1
                                    border.color: Rock.a(win.accent, 0.5)
                                    Lbl {
                                        id: customLbl
                                        anchors.centerIn: parent
                                        text: I18n.t("СВОЙ")
                                        color: win.accent
                                        font.pixelSize: 9
                                        font.weight: Font.Black
                                        font.letterSpacing: 0.6
                                    }
                                }
                            }

                            Lbl {
                                Layout.fillWidth: true
                                text: I18n.t("Готовые наборы панели — выбери подходящий и настрой детали во вкладках")
                                color: win.sub
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 10
                                rowSpacing: 10

                                Repeater {
                                    model: win.presetList
                                    delegate: Rectangle {
                                        id: presetCard
                                        required property var modelData
                                        readonly property bool sel: PanelConfig.preset === modelData.key

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 106
                                        radius: Rock.uiRadius
                                        color: sel ? Rock.a(win.accent, 0.16)
                                                   : (presetArea.containsMouse ? Rock.a(win.accent, 0.08) : Rock.a(win.fg, 0.04))
                                        border.width: sel ? 2 : 1
                                        border.color: sel ? win.accent : Rock.a(win.fg, 0.16)
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 5

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 9

                                                Rectangle {
                                                    width: 30; height: 30
                                                    radius: Math.max(6, Rock.uiRadiusSm - 2)
                                                    color: presetCard.sel ? win.accent : Rock.a(win.fg, 0.08)
                                                    Lbl {
                                                        anchors.centerIn: parent
                                                        text: presetCard.modelData.icon
                                                        color: presetCard.sel ? Rock.uiOnActive : win.sub
                                                        font.pixelSize: 13
                                                    }
                                                }

                                                Lbl {
                                                    Layout.fillWidth: true
                                                    text: presetCard.modelData.label
                                                    color: presetCard.sel ? win.accent : win.fg
                                                    font.family: Rock.display
                                                    font.pixelSize: 14
                                                    font.weight: Font.Black
                                                    font.letterSpacing: 0.6
                                                }

                                                Rectangle {
                                                    visible: presetCard.sel
                                                    width: 18; height: 18
                                                    radius: 9
                                                    color: win.accent
                                                    Lbl {
                                                        anchors.centerIn: parent
                                                        text: "\uf00c"
                                                        color: Rock.uiOnActive
                                                        font.pixelSize: 8
                                                        font.weight: Font.Black
                                                    }
                                                }
                                            }

                                            Lbl {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                text: presetCard.modelData.hint
                                                color: win.sub
                                                font.pixelSize: 10
                                                wrapMode: Text.WordWrap
                                                verticalAlignment: Text.AlignTop
                                            }
                                        }

                                        MouseArea {
                                            id: presetArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: PanelConfig.setPreset(presetCard.modelData.key)
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Lbl {
                                    Layout.fillWidth: true
                                    text: I18n.t("Любое изменение ниже переключает панель в режим «Свой»")
                                    color: win.sub
                                    font.pixelSize: 9
                                    wrapMode: Text.WordWrap
                                }
                                Rectangle {
                                    implicitWidth: resetLbl.implicitWidth + 26
                                    implicitHeight: 30
                                    radius: Rock.uiRadiusSm
                                    color: resetArea.containsMouse ? Rock.a(win.accent, 0.14) : "transparent"
                                    border.width: 1
                                    border.color: Rock.a(win.fg, 0.22)
                                    Lbl {
                                        id: resetLbl
                                        anchors.centerIn: parent
                                        text: I18n.t("СБРОСИТЬ")
                                        color: win.sub
                                        font.family: Rock.display
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        font.letterSpacing: 0.6
                                    }
                                    MouseArea {
                                        id: resetArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: PanelConfig.setPreset("balanced")
                                    }
                                }
                            }
                        }
                    }

                    // ═════════ ПАНЕЛЬ ═════════
                    Flickable {
                        id: barPage
                        anchors.fill: parent
                        visible: win.tab === "bar"
                        clip: true
                        contentWidth: width
                        contentHeight: barCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: barCol
                            width: barPage.width
                            spacing: 12

                            Lbl {
                                text: I18n.t("РАСПОЛОЖЕНИЕ ПАНЕЛИ")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Repeater {
                                    model: win.positionOptions
                                    delegate: Rectangle {
                                        id: opt
                                        required property var modelData
                                        readonly property bool sel: PanelConfig.position === modelData.key

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 92
                                        radius: Rock.uiRadiusSm
                                        color: sel ? Rock.a(win.accent, 0.14)
                                                   : (optArea.containsMouse ? Rock.a(win.accent, 0.08) : "transparent")
                                        border.width: sel ? 2 : 1
                                        border.color: sel ? win.accent : Rock.a(win.fg, 0.18)
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 5

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 7
                                                    color: Rock.a(win.fg, 0.05)
                                                    border.width: 1
                                                    border.color: Rock.a(win.fg, 0.12)
                                                }

                                                Rectangle {
                                                    readonly property string k: opt.modelData.key
                                                    x: k === "right" ? parent.width - width - 5 : 5
                                                    y: k === "bottom" ? parent.height - height - 5 : 5
                                                    width: (k === "left" || k === "right") ? 5 : parent.width - 10
                                                    height: (k === "top" || k === "bottom") ? 5 : parent.height - 10
                                                    radius: 2
                                                    color: opt.sel ? win.accent : Rock.a(win.fg, 0.45)
                                                }
                                            }

                                            Lbl {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: opt.modelData.label
                                                color: opt.sel ? win.accent : win.sub
                                                font.family: Rock.display
                                                font.pixelSize: 10
                                                font.weight: Font.Black
                                                font.letterSpacing: 0.5
                                            }
                                        }

                                        MouseArea {
                                            id: optArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: PanelConfig.setPosition(opt.modelData.key)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Rock.a(win.fg, 0.12)
                            }

                            SettingsRow {
                                title: I18n.t("Плотность")
                                hint: I18n.t("Высота панели и размер островов")
                                SettingsChoice {
                                    options: win.densityOptions
                                    value: PanelConfig.density
                                    onPicked: key => PanelConfig.setDensity(key)
                                }
                            }

                            Lbl {
                                Layout.topMargin: 4
                                text: I18n.t("ЭЛЕМЕНТЫ ПАНЕЛИ")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            SettingsRow {
                                title: I18n.t("Рабочие столы")
                                Toggle {
                                    checked: PanelConfig.showWorkspaces
                                    onToggled: PanelConfig.setShow("showWorkspaces", !PanelConfig.showWorkspaces)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Заголовок окна")
                                Toggle {
                                    checked: PanelConfig.showTitle
                                    onToggled: PanelConfig.setShow("showTitle", !PanelConfig.showTitle)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Системный трей")
                                Toggle {
                                    checked: PanelConfig.showTray
                                    onToggled: PanelConfig.setShow("showTray", !PanelConfig.showTray)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Кнопка обоев")
                                Toggle {
                                    checked: PanelConfig.showWallpaper
                                    onToggled: PanelConfig.setShow("showWallpaper", !PanelConfig.showWallpaper)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Кнопка настроек")
                                Toggle {
                                    checked: PanelConfig.showSettings
                                    onToggled: PanelConfig.setShow("showSettings", !PanelConfig.showSettings)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Раскладка клавиатуры")
                                Toggle {
                                    checked: PanelConfig.showKeyboard
                                    onToggled: PanelConfig.setShow("showKeyboard", !PanelConfig.showKeyboard)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Громкость")
                                Toggle {
                                    checked: PanelConfig.showVolume
                                    onToggled: PanelConfig.setShow("showVolume", !PanelConfig.showVolume)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Батарея")
                                Toggle {
                                    checked: PanelConfig.showBattery
                                    onToggled: PanelConfig.setShow("showBattery", !PanelConfig.showBattery)
                                }
                            }
                        }
                    }

                    // ═════════ МОДУЛИ ═════════
                    Flickable {
                        id: modulesPage
                        anchors.fill: parent
                        visible: win.tab === "modules"
                        clip: true
                        contentWidth: width
                        contentHeight: modulesCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: modulesCol
                            width: modulesPage.width
                            spacing: 8

                            Lbl {
                                text: I18n.t("МОДУЛИ")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            Lbl {
                                Layout.fillWidth: true
                                text: I18n.t("Какие модули показывать в панели и островах")
                                color: win.sub
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                height: 1
                                color: Rock.a(win.fg, 0.12)
                            }

                            Lbl {
                                Layout.topMargin: 4
                                text: I18n.t("ВИДЖЕТЫ РАБОЧЕГО СТОЛА")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            SettingsRow {
                                title: I18n.t("Включить виджеты")
                                hint: I18n.t("Часы и плеер на свободном месте рабочего стола")
                                Toggle {
                                    checked: PanelConfig.widgetsEnabled
                                    onToggled: PanelConfig.setWidgets(!PanelConfig.widgetsEnabled)
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Часы и нагрузка")
                                hint: I18n.t("Время, дата и загрузка системы")
                                Toggle {
                                    checked: PanelConfig.widgetClock
                                    enabled: PanelConfig.widgetsEnabled
                                    opacity: PanelConfig.widgetsEnabled ? 1 : 0.4
                                    onToggled: PanelConfig.setWidget("widgetClock", !PanelConfig.widgetClock)
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Плеер")
                                hint: I18n.t("Обложка, трек и управление")
                                Toggle {
                                    checked: PanelConfig.widgetPlayer
                                    enabled: PanelConfig.widgetsEnabled
                                    opacity: PanelConfig.widgetsEnabled ? 1 : 0.4
                                    onToggled: PanelConfig.setWidget("widgetPlayer", !PanelConfig.widgetPlayer)
                                }
                            }

                            SettingsRow {
                                title: "Bluetooth"
                                hint: I18n.t("Значок и подключённые устройства")
                                Toggle {
                                    checked: PanelConfig.modules.bt
                                    onToggled: PanelConfig.setModule("bt", !PanelConfig.modules.bt)
                                }
                            }
                            SettingsRow {
                                title: "Wi-Fi"
                                hint: I18n.t("Индикатор беспроводной сети")
                                Toggle {
                                    checked: PanelConfig.modules.wifi
                                    onToggled: PanelConfig.setModule("wifi", !PanelConfig.modules.wifi)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Сеть / скорость")
                                hint: I18n.t("Значок сети и скорость передачи")
                                Toggle {
                                    checked: PanelConfig.modules.net
                                    onToggled: PanelConfig.setModule("net", !PanelConfig.modules.net)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Уведомления")
                                hint: I18n.t("Колокольчик и счётчик")
                                Toggle {
                                    checked: PanelConfig.modules.notif
                                    onToggled: PanelConfig.setModule("notif", !PanelConfig.modules.notif)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Медиа")
                                hint: I18n.t("Текущий трек в центральном острове")
                                Toggle {
                                    checked: PanelConfig.modules.music
                                    onToggled: PanelConfig.setModule("music", !PanelConfig.modules.music)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Погода")
                                hint: I18n.t("Температура и осадки")
                                Toggle {
                                    checked: PanelConfig.modules.weather
                                    onToggled: PanelConfig.setModule("weather", !PanelConfig.modules.weather)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Помодоро")
                                hint: I18n.t("Таймер фокуса")
                                Toggle {
                                    checked: PanelConfig.modules.pomodoro
                                    onToggled: PanelConfig.setModule("pomodoro", !PanelConfig.modules.pomodoro)
                                }
                            }
                            SettingsRow {
                                title: I18n.t("Запись экрана")
                                hint: I18n.t("Индикатор записи")
                                Toggle {
                                    checked: PanelConfig.modules.record
                                    onToggled: PanelConfig.setModule("record", !PanelConfig.modules.record)
                                }
                            }
                        }
                    }

                    // ═════════ ВИД ═════════
                    Flickable {
                        id: lookPage
                        anchors.fill: parent
                        visible: win.tab === "look"
                        clip: true
                        contentWidth: width
                        contentHeight: lookCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: lookCol
                            width: lookPage.width
                            spacing: 10

                            Lbl {
                                text: I18n.t("ВИД")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            Lbl {
                                Layout.fillWidth: true
                                text: I18n.t("Цвета берутся из текущих обоев автоматически")
                                color: win.sub
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }

                            SettingsRow {
                                title: I18n.t("Размер шрифта")
                                SettingsSlider {
                                    from: 8
                                    to: 24
                                    value: PanelConfig.fontSize
                                    onMoved: v => PanelConfig.setFontSize(v)
                                }
                                Lbl {
                                    Layout.preferredWidth: 26
                                    horizontalAlignment: Text.AlignRight
                                    text: PanelConfig.fontSize
                                    color: win.accent
                                    font.family: Rock.mono
                                    font.pixelSize: 11
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Скругление островов")
                                SettingsSlider {
                                    from: 0
                                    to: 30
                                    value: PanelConfig.islandRadius
                                    onMoved: v => PanelConfig.setIslandRadius(v)
                                }
                                Lbl {
                                    Layout.preferredWidth: 26
                                    horizontalAlignment: Text.AlignRight
                                    text: PanelConfig.islandRadius
                                    color: win.accent
                                    font.family: Rock.mono
                                    font.pixelSize: 11
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Прозрачность стекла")
                                SettingsSlider {
                                    from: 30
                                    to: 100
                                    value: PanelConfig.surfaceOpacity
                                    onMoved: v => PanelConfig.setSurfaceOpacity(v)
                                }
                                Lbl {
                                    Layout.preferredWidth: 36
                                    horizontalAlignment: Text.AlignRight
                                    text: PanelConfig.surfaceOpacity + "%"
                                    color: win.accent
                                    font.family: Rock.mono
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                Layout.topMargin: 6
                                radius: PanelConfig.islandRadius
                                color: Theme.islandBg
                                border.width: 1
                                border.color: Rock.a(win.fg, 0.16)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Rectangle {
                                        width: 74; height: 22; radius: Math.max(4, PanelConfig.islandRadius - 8)
                                        color: Rock.a(win.accent, 0.18)
                                    }
                                    Rectangle {
                                        width: 130; height: 22; radius: Math.max(4, PanelConfig.islandRadius - 8)
                                        color: Rock.a(win.fg, 0.08)
                                    }
                                    Rectangle {
                                        width: 74; height: 22; radius: Math.max(4, PanelConfig.islandRadius - 8)
                                        color: Rock.a(win.accent, 0.18)
                                    }
                                }
                            }

                            Lbl {
                                Layout.fillWidth: true
                                text: I18n.t("Палитра, прозрачность и форма применяются сразу")
                                color: win.sub
                                font.pixelSize: 9
                            }

                        }
                    }

                    // ═════════ ЕЩЁ ═════════
                    Flickable {
                        id: morePage
                        anchors.fill: parent
                        visible: win.tab === "more"
                        clip: true
                        contentWidth: width
                        contentHeight: moreCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: moreCol
                            width: morePage.width
                            spacing: 12

                            Lbl {
                                text: I18n.t("ПОВЕДЕНИЕ")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            SettingsRow {
                                title: I18n.t("Язык")
                                SettingsChoice {
                                    options: win.languageOptions
                                    value: PanelConfig.language
                                    onPicked: key => PanelConfig.setLanguage(key)
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Не засыпать")
                                hint: I18n.t("Пока включено — экран не гаснет")
                                Toggle {
                                    checked: UI.caffeine
                                    checkedColor: Rock.uiAccent
                                    uncheckedColor: Rock.a(Rock.uiText, 0.12)
                                    onToggled: UI.caffeine = !UI.caffeine
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Авто-блокировка")
                                hint: I18n.t("Минут бездействия до блокировки")
                                SettingsInput {
                                    fieldWidth: 84
                                    text: PanelConfig.lockAfterMin
                                    onEdited: v => PanelConfig.setLockAfterMin(v)
                                }
                            }

                            SettingsRow {
                                title: I18n.t("Автозасыпание")
                                hint: I18n.t("Минут бездействия до сна")
                                SettingsInput {
                                    fieldWidth: 84
                                    text: PanelConfig.sleepAfterMin
                                    onEdited: v => PanelConfig.setSleepAfterMin(v)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Rock.a(win.fg, 0.12)
                            }

                            Lbl {
                                text: I18n.t("АВАТАР ПОЛЬЗОВАТЕЛЯ")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                Avatar {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.preferredWidth: 72
                                    Layout.preferredHeight: 72
                                    source: PanelConfig.avatarUrl
                                    letter: (Quickshell.env("USER") || "user").charAt(0).toUpperCase()
                                    bg: win.accent
                                    fg: Rock.uiOnActive
                                    borderWidth: 1
                                    borderColor: win.frameEdge
                                    fontFamily: Rock.display
                                    fontSize: 30
                                    fontWeight: Font.Black
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Lbl {
                                        Layout.fillWidth: true
                                        text: PanelConfig.hasAvatar
                                            ? I18n.t("Картинка выбрана. Она показывается вместо первой буквы имени в центре управления.")
                                            : I18n.t("Сейчас показывается первая буква имени. Выберите картинку — она заменит букву в центре управления.")
                                        color: win.sub
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }

                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            implicitWidth: pickLbl.implicitWidth + 26
                                            implicitHeight: 30
                                            radius: Rock.uiRadiusSm
                                            color: pickArea.containsMouse ? Rock.a(win.accent, 0.85) : win.accent
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Lbl {
                                                id: pickLbl
                                                anchors.centerIn: parent
                                                text: I18n.t("ВЫБРАТЬ ФАЙЛ")
                                                color: Rock.uiOnActive
                                                font.family: Rock.display
                                                font.pixelSize: 10
                                                font.weight: Font.Black
                                                font.letterSpacing: 0.6
                                            }
                                            MouseArea {
                                                id: pickArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.startPick()
                                            }
                                        }
                                        Rectangle {
                                            visible: PanelConfig.hasAvatar
                                            implicitWidth: resetAvatarLbl.implicitWidth + 24
                                            implicitHeight: 30
                                            radius: Rock.uiRadiusSm
                                            color: resetAvatarArea.containsMouse ? Rock.a(win.fg, 0.14) : "transparent"
                                            border.width: 1
                                            border.color: Rock.a(win.fg, 0.24)
                                            Lbl {
                                                id: resetAvatarLbl
                                                anchors.centerIn: parent
                                                text: I18n.t("СБРОСИТЬ")
                                                color: win.sub
                                                font.family: Rock.display
                                                font.pixelSize: 9
                                                font.weight: Font.Black
                                                font.letterSpacing: 0.6
                                            }
                                            MouseArea {
                                                id: resetAvatarArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: PanelConfig.clearAvatar()
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Rock.a(win.fg, 0.12)
                            }

                            Lbl {
                                text: I18n.t("ПОГОДА")
                                color: win.fg
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 13
                                font.letterSpacing: 0.8
                            }

                            SettingsRow {
                                title: I18n.t("Город")
                                hint: I18n.t("Пусто — определить по IP")
                                SettingsInput {
                                    fieldWidth: 200
                                    text: Config.weatherCity
                                    onEdited: v => Config.setWeatherCity(v)
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Lbl { text: I18n.t("Широта"); color: win.fg; font.pixelSize: 11 }
                                    SettingsInput {
                                        Layout.fillWidth: true
                                        text: Config.weatherLat
                                        onEdited: v => Config.setWeatherLat(v)
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Lbl { text: I18n.t("Долгота"); color: win.fg; font.pixelSize: 11 }
                                    SettingsInput {
                                        Layout.fillWidth: true
                                        text: Config.weatherLon
                                        onEdited: v => Config.setWeatherLon(v)
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Lbl { text: I18n.t("Обновление"); color: win.fg; font.pixelSize: 11 }
                                    SettingsInput {
                                        Layout.fillWidth: true
                                        text: Config.weatherRefreshMin
                                        onEdited: v => Config.setWeatherRefreshMin(v)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── подсказка ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Lbl {
                        text: "\uf0eb"
                        color: win.accent
                        font.pixelSize: 10
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: I18n.t("Изменения применяются сразу и сохраняются в panel.json")
                        color: win.sub
                        font.pixelSize: 10
                    }
                    Lbl {
                        text: "esc"
                        color: win.accent
                        font.pixelSize: 9
                        font.weight: Font.Black
                    }
                    Lbl {
                        text: I18n.t("закрыть")
                        color: win.sub
                        font.pixelSize: 9
                    }
                }
            }
        }
    }

    // ───────── выбор аватара ─────────
    Item {
        id: picker
        anchors.fill: parent
        visible: win.picking
        z: 50

        Rectangle {
            anchors.fill: parent
            color: Rock.a(Rock.ink, 0.62)
            MouseArea { anchors.fill: parent; onClicked: win.picking = false }
        }

        Rectangle {
            id: pickCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 90, 900)
            height: Math.min(parent.height - 90, 560)
            radius: Math.max(10, Rock.uiRadius)
            color: win.cardFill
            border.width: Rock.uiBorder
            border.color: win.frameEdge

            MouseArea { anchors.fill: parent }

            SaoGrid { anchors.fill: parent; step: 28 }
            MarisaPattern { anchors.fill: parent; opacity: 0.5 }
            MarisaFrame {
                anchors.fill: parent
                inset: 7
                frameRadius: Math.max(2, pickCard.radius - 5)
            }
            SaoFrame {
                anchors.fill: parent
                inset: 6
                cut: 12
                segments: 34
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 7; height: 26
                        radius: 4
                        color: win.accent
                    }

                    Lbl {
                        text: I18n.t("ВЫБОР АВАТАРА")
                        color: win.fg
                        font.family: Rock.display
                        font.pixelSize: 18
                        font.weight: Font.Black
                        font.letterSpacing: 1
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 30; height: 30
                        radius: 15
                        color: pickCloseArea.containsMouse ? Rock.a(win.accent, 0.22) : "transparent"
                        border.width: pickCloseArea.containsMouse ? 1 : 0
                        border.color: win.accent
                        Lbl {
                            anchors.centerIn: parent
                            text: "\uf00d"
                            color: win.fg
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: pickCloseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.picking = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Rock.a(win.fg, 0.14)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 36; height: 34
                        radius: Rock.uiRadiusSm
                        color: upArea.containsMouse ? Rock.a(win.accent, 0.8) : Rock.a(win.fg, 0.05)
                        border.width: 1
                        border.color: Rock.a(win.fg, 0.18)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Lbl {
                            anchors.centerIn: parent
                            text: "\uf060"
                            color: upArea.containsMouse ? Rock.uiOnActive : win.fg
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: upArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.pickUp()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: Rock.uiRadiusSm
                        color: Rock.a(win.fg, 0.05)
                        border.width: 1
                        border.color: Rock.a(win.fg, 0.18)
                        Lbl {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            text: win.browsePath
                            elide: Text.ElideMiddle
                            color: win.fg
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }

                    Repeater {
                        model: [
                            { t: I18n.t("ДОМ"),  p: Quickshell.env("HOME") },
                            { t: I18n.t("ФОТО"), p: Quickshell.env("HOME") + "/Pictures" }
                        ]
                        delegate: Rectangle {
                            id: navBtn
                            required property var modelData
                            width: 64; height: 34
                            radius: Rock.uiRadiusSm
                            color: navArea.containsMouse ? Rock.a(win.accent, 0.8) : Rock.a(win.fg, 0.05)
                            border.width: 1
                            border.color: Rock.a(win.fg, 0.18)
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Lbl {
                                anchors.centerIn: parent
                                text: navBtn.modelData.t
                                color: navArea.containsMouse ? Rock.uiOnActive : win.sub
                                font.family: Rock.display
                                font.pixelSize: 9
                                font.weight: Font.Black
                                font.letterSpacing: 0.6
                            }
                            MouseArea {
                                id: navArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.browse(navBtn.modelData.p)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    ListView {
                        id: pickDirs
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        clip: true
                        spacing: 5
                        boundsBehavior: Flickable.StopAtBounds
                        model: win.browseDirs

                        Lbl {
                            anchors.centerIn: parent
                            visible: pickDirs.count === 0
                            text: I18n.t("Папок нет")
                            color: Rock.a(win.fg, 0.45)
                            font.family: Rock.display
                            font.pixelSize: 12
                            font.weight: Font.Black
                        }

                        delegate: Rectangle {
                            id: pickDirRow
                            required property string modelData
                            width: pickDirs.width
                            height: 40
                            radius: Rock.uiRadiusSm
                            color: pickDirArea.containsMouse ? Rock.a(win.accent, 0.8) : Rock.a(win.fg, 0.05)
                            border.width: 1
                            border.color: Rock.a(win.fg, 0.15)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                Lbl {
                                    text: "\uf07b"
                                    color: pickDirArea.containsMouse ? Rock.uiOnActive : win.accent
                                    font.pixelSize: 12
                                }
                                Lbl {
                                    Layout.fillWidth: true
                                    text: pickDirRow.modelData
                                    elide: Text.ElideRight
                                    color: pickDirArea.containsMouse ? Rock.uiOnActive : win.fg
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                                Lbl { text: "\uf054"; color: Rock.a(win.fg, 0.4); font.pixelSize: 9 }
                            }

                            MouseArea {
                                id: pickDirArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.browse(win.browsePath === "/"
                                    ? "/" + pickDirRow.modelData
                                    : win.browsePath + "/" + pickDirRow.modelData)
                            }
                        }
                    }

                    GridView {
                        id: pickGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        readonly property int cols: Math.max(2, Math.floor(width / 130))
                        cellWidth: width / cols
                        cellHeight: cellWidth * 0.82
                        model: win.browseFiles

                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: pickGrid.count === 0
                            spacing: 4
                            Lbl {
                                Layout.alignment: Qt.AlignHCenter
                                text: "\uf03e"
                                color: win.accent
                                font.pixelSize: 26
                            }
                            Lbl {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.t("НЕТ ИЗОБРАЖЕНИЙ")
                                color: win.fg
                                font.family: Rock.display
                                font.pixelSize: 13
                                font.weight: Font.Black
                                font.letterSpacing: 0.8
                            }
                        }

                        delegate: Item {
                            id: pickCell
                            required property string modelData
                            width: pickGrid.cellWidth
                            height: pickGrid.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: Rock.uiRadiusSm
                                color: Rock.a(win.fg, 0.05)
                                border.width: pickFileArea.containsMouse ? 2 : 1
                                border.color: pickFileArea.containsMouse ? win.accent : Rock.a(win.fg, 0.16)
                                scale: pickFileArea.containsMouse ? 1.03 : 1
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 100 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 7
                                        color: Rock.a(Rock.ink, 0.22)
                                        clip: true
                                        Image {
                                            anchors.fill: parent
                                            source: win.fileUrl(pickCell.modelData)
                                            sourceSize: Qt.size(260, 200)
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            cache: true
                                        }
                                    }

                                    Lbl {
                                        Layout.fillWidth: true
                                        text: pickCell.modelData.split("/").pop()
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignHCenter
                                        color: win.fg
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    id: pickFileArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.chooseFile(pickCell.modelData)
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Lbl {
                        Layout.fillWidth: true
                        text: win.browseFiles.length + I18n.t(" изображений · нажми на картинку, чтобы выбрать")
                        color: win.sub
                        font.pixelSize: 10
                    }

                    Rectangle {
                        width: 100; height: 34
                        radius: Rock.uiRadiusSm
                        color: pickCancelArea.containsMouse ? Rock.a(win.fg, 0.14) : "transparent"
                        border.width: 1
                        border.color: Rock.a(win.fg, 0.28)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Lbl {
                            anchors.centerIn: parent
                            text: I18n.t("ОТМЕНА")
                            color: win.sub
                            font.family: Rock.display
                            font.pixelSize: 10
                            font.weight: Font.Black
                            font.letterSpacing: 0.7
                        }
                        MouseArea {
                            id: pickCancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.picking = false
                        }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: fade
        NumberAnimation { target: dim;   property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: frame; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: frame; property: "scale";   from: 0.96; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
