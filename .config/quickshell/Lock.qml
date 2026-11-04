import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Экран блокировки на ext-session-lock + PAM (замена hyprlock).
// Запуск: quickshell ipc call lock lock   |  или UI.locked = true
Scope {
    id: root

    property string buffer: ""      // введённый пароль
    property string pending: ""     // пароль, ушедший в PAM
    property bool busy: false
    property string status: ""
    property int shakeKey: 0
    property bool reveal: false         // показать вводимый пароль
    property bool fpAvailable: false    // есть сканер и записанные пальцы
    property int fpFails: 0

    // обои берём у pywal, иначе из переключателя обоев
    property string walPath: ""
    readonly property string wallpaper: walPath !== "" ? walPath : Wallpapers.current

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/wal/wal"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.walPath = text().trim()
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function submit() {
        if (busy || buffer === "") return
        pending = buffer
        buffer = ""
        status = ""
        busy = true
        watchdog.restart()
        // основной путь: setuid-хелпер PAM (unix_chkpwd) — без dbus/logind, работает и на dinit
        chk.environment = { "QS_PW": pending }
        chk.running = true
    }

    Process {
        id: chk
        command: ["sh", "-c",
            'h=$(command -v unix_chkpwd); ' +
            '[ -n "$h" ] || for p in /usr/bin /usr/sbin /sbin /usr/lib; do [ -x "$p/unix_chkpwd" ] && h="$p/unix_chkpwd" && break; done; ' +
            '[ -n "$h" ] || exit 127; ' +
            'printf "%s\\000" "$QS_PW" | "$h" "$(id -un)" nullok']
        onExited: (code, status) => {
            chk.environment = ({})
            console.log("Lock: unix_chkpwd код", code)
            if (code === 0) {
                watchdog.stop()
                root.pending = ""
                root.busy = false
                UI.locked = false
            } else if (code === 127) {
                // хелпера нет — пробуем обычный PAM
                console.warn("Lock: unix_chkpwd не найден, пробую PAM")
                watchdog.restart()
                pam.start()
            } else {
                watchdog.stop()
                root.pending = ""
                root.busy = false
                root.status = "Неверный пароль"
                root.shakeKey++
            }
        }
    }

    function reset() {
        buffer = ""; pending = ""; status = ""; busy = false
    }

    Connections {
        target: UI
        function onLockedChanged() { root.reset(); if (UI.locked) pam.abort() }
    }

    // если PAM молчит дольше 10 с — сбрасываем, чтобы экран не «висел»
    Timer {
        id: watchdog
        interval: 10000
        onTriggered: {
            console.warn("Lock: проверка не ответила, сброс")
            chk.running = false
            pam.abort()
            root.busy = false
            root.pending = ""
            root.status = "Проверка не отвечает"
            root.shakeKey++
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: {
            console.log("Lock: pamMessage:", message, "| responseRequired:", responseRequired, "| isError:", messageIsError)
            if (responseRequired) {
                if (root.pending !== "") {
                    respond(root.pending)
                    root.pending = ""
                } else {
                    // PAM спрашивает ещё раз, а ответа у нас нет — не висим
                    abort()
                }
            }
        }
        onCompleted: result => {
            console.log("Lock: completed:", result)
            watchdog.stop()
            root.busy = false
            root.pending = ""
            if (result === PamResult.Success) {
                UI.locked = false
            } else {
                root.status = "Неверный пароль (" + result + ")"
                root.shakeKey++
            }
        }
        onError: err => {
            console.warn("Lock: PAM error:", err)
            watchdog.stop()
            root.busy = false
            root.pending = ""
            root.status = "Ошибка PAM (см. лог)"
            root.shakeKey++
        }
    }

    // ───────── отпечаток пальца (fprintd) ─────────
    Process {
        id: fpCheck
        command: ["sh", "-c", "command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$USER\" 2>/dev/null | grep -q '^ - #'"]
        running: true
        onExited: code => { root.fpAvailable = (code === 0); console.log("Lock: отпечаток доступен:", root.fpAvailable) }
    }

    function fpStart() {
        if (!fpAvailable || !UI.locked || fpPam.active) return
        fpPam.start()
    }

    Timer {
        id: fpRetry
        interval: 1200
        onTriggered: root.fpStart()
    }

    PamContext {
        id: fpPam
        configDirectory: Quickshell.shellPath("pam")
        config: "fprint.conf"

        onPamMessage: console.log("Lock: fprint:", message)
        onCompleted: result => {
            console.log("Lock: fprint completed:", result)
            if (result === PamResult.Success) {
                UI.locked = false
            } else if (UI.locked) {
                root.fpFails++
                root.shakeKey++
                if (root.fpFails < 8) fpRetry.restart()
            }
        }
        onError: err => {
            console.warn("Lock: fprint error:", err)
            if (UI.locked && root.fpFails < 8) { root.fpFails++; fpRetry.restart() }
        }
    }

    Connections {
        target: UI
        function onLockedChanged() {
            root.fpFails = 0
            if (UI.locked) { fpCheck.running = true; fpDelay.restart() }
            else { fpPam.abort(); fpRetry.stop() }
        }
    }
    Timer { id: fpDelay; interval: 500; onTriggered: root.fpStart() }

    WlSessionLock {
        id: sessionLock
        locked: UI.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.bg

            Item {
                id: view
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    if (root.busy) { event.accepted = true; return }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.submit()
                    } else if (event.key === Qt.Key_Tab) {
                        root.reveal = !root.reveal
                    } else if (event.key === Qt.Key_Backspace) {
                        root.buffer = root.buffer.slice(0, -1)
                        root.status = ""
                    } else if (event.key === Qt.Key_Escape
                               || (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier))) {
                        root.buffer = ""
                        root.status = ""
                    } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32
                               && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                        root.buffer += event.text
                        root.status = ""
                    }
                    event.accepted = true
                }

                // ── фон: размытые обои ──
                Rectangle { anchors.fill: parent; color: Theme.bg }
                Image {
                    id: wall
                    anchors.fill: parent
                    visible: false
                    source: root.wallpaper !== "" ? "file://" + root.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 1920
                }
                MultiEffect {
                    anchors.fill: parent
                    source: wall
                    visible: wall.status === Image.Ready
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                    brightness: -0.12
                    saturation: -0.1
                }
                Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.38) }

                // ── часы ──
                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.12
                    spacing: 0
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatTime(clock.date, "HH:mm")
                        font.pixelSize: 120
                        font.bold: true
                    }
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const s = Qt.locale("ru_RU").toString(clock.date, "dddd, d MMMM")
                            return s.charAt(0).toUpperCase() + s.slice(1)
                        }
                        color: Theme.muted
                        font.pixelSize: 20
                    }
                }

                // ── карточка с вводом ──
                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: parent.height * 0.12
                    width: 360
                    height: cardCol.implicitHeight + 56
                    radius: 28
                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.62)
                    border.width: 1
                    border.color: Theme.hairline

                    transform: Translate { id: shake }
                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 14;  duration: 80 }
                        NumberAnimation { target: shake; property: "x"; to: -9;  duration: 70 }
                        NumberAnimation { target: shake; property: "x"; to: 9;   duration: 70 }
                        NumberAnimation { target: shake; property: "x"; to: 0;   duration: 50 }
                    }
                    Connections {
                        target: root
                        function onShakeKeyChanged() { shakeAnim.restart() }
                    }

                    ColumnLayout {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 14

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 72; Layout.preferredHeight: 72; radius: 36
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                            border.width: 2
                            border.color: Theme.accent
                            Lbl { anchors.centerIn: parent; text: "\uf007"; color: Theme.accent; font.pixelSize: 28 }
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: Quickshell.env("USER")
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: 24
                            color: Theme.surface
                            border.width: 1
                            border.color: root.status !== "" ? Theme.warn : (root.busy ? Theme.accent2 : Theme.accent)
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            clip: true

                            Lbl {
                                anchors.centerIn: parent
                                visible: root.buffer === ""
                                text: root.busy ? "Проверка…" : (root.fpAvailable ? "Пароль или палец" : "Введите пароль")
                                color: Theme.muted
                            }
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                visible: !root.reveal
                                Repeater {
                                    model: Math.min(root.buffer.length, 18)
                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        color: Theme.accent
                                    }
                                }
                            }
                            Lbl {
                                anchors.centerIn: parent
                                width: parent.width - 120
                                visible: root.reveal && root.buffer !== ""
                                text: root.buffer
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideLeft
                            }

                            // раскладка (клик — переключить)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34; height: 28; radius: 14
                                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                Lbl { anchors.centerIn: parent; text: Kb.layout; color: Theme.accent; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Kb.next() }
                            }
                            // показать/скрыть пароль (Tab)
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28; height: 28; radius: 14
                                color: "transparent"
                                Lbl { anchors.centerIn: parent; text: root.reveal ? "\uf070" : "\uf06e"; color: Theme.muted; font.pixelSize: 13 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.reveal = !root.reveal }
                            }
                        }

                        // подсказка про палец
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            visible: root.fpAvailable && root.fpFails < 8
                            spacing: 6
                            Lbl { text: "\uf577"; color: Theme.accent2; font.pixelSize: 14 }
                            Lbl { text: "Приложите палец к сканеру"; color: Theme.muted; font.pixelSize: 11 }
                        }

                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.status
                            visible: root.status !== ""
                            color: Theme.warn
                            font.pixelSize: 12
                        }
                    }
                }

                // ── музыка ──
                Rectangle {
                    id: music
                    readonly property var p: Media.player
                    readonly property bool has: p !== null && p !== undefined && !!p.trackTitle
                    visible: has
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: weatherRow.visible ? 76 : 36
                    width: 380
                    height: 72
                    radius: 22
                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.62)
                    border.width: 1
                    border.color: Theme.hairline

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 52; Layout.preferredHeight: 52
                            radius: 14
                            color: Theme.surface
                            clip: true
                            Lbl { anchors.centerIn: parent; text: "\uf001"; color: Theme.accent2; font.pixelSize: 20; visible: art.status !== Image.Ready }
                            Image {
                                id: art
                                anchors.fill: parent
                                source: music.p ? (music.p.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Lbl {
                                Layout.fillWidth: true
                                text: music.p ? (music.p.trackTitle || "") : ""
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Lbl {
                                Layout.fillWidth: true
                                text: music.p ? (music.p.trackArtist || "") : ""
                                color: Theme.muted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Repeater {
                            model: [
                                { icon: "\uf048", act: "prev" },
                                { icon: "toggle",  act: "toggle" },
                                { icon: "\uf051", act: "next" }
                            ]
                            delegate: Rectangle {
                                id: mb
                                required property var modelData
                                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                                radius: 17
                                color: mArea.containsMouse ? Theme.accent : (modelData.act === "toggle" ? Theme.surface : "transparent")
                                Lbl {
                                    anchors.centerIn: parent
                                    text: mb.modelData.act === "toggle"
                                        ? ((music.p && music.p.isPlaying) ? "\uf04c" : "\uf04b")
                                        : mb.modelData.icon
                                    color: mArea.containsMouse ? Theme.textOnAccent : Theme.text
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    id: mArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const p = music.p
                                        if (!p) return
                                        if (mb.modelData.act === "toggle") { if (p.canTogglePlaying) p.togglePlaying() }
                                        else if (mb.modelData.act === "next") { if (p.canGoNext) p.next() }
                                        else { if (p.canGoPrevious) p.previous() }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── погода ──
                RowLayout {
                    id: weatherRow
                    visible: Weather.ready
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 36
                    spacing: 8
                    Lbl { text: Weather.icon; color: Theme.accent; font.pixelSize: 20 }
                    Lbl { text: Weather.temp + (Weather.desc !== "" ? "  ·  " + Weather.desc : ""); color: Theme.muted }
                }

                // плавное появление
                opacity: 0
                NumberAnimation on opacity { from: 0; to: 1; duration: 220; running: true }
            }
        }
    }

    // quickshell ipc call lock lock
    IpcHandler {
        target: "lock"
        function lock(): void { UI.session = false; UI.launcher = false; UI.locked = true }
        function status(): bool { return UI.locked }
    }
}
