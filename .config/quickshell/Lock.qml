import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower

// Экран блокировки на ext-session-lock + PAM.
// Оформление — кислотный «Bocchi the Rock» HUD: розовый, жёлтый, бирюза,
// жирные контуры, полутон и наклейки.
// Запуск: quickshell ipc call lock lock   |  или UI.locked = true
Scope {
    id: root

    readonly property bool debug: false

    property string buffer: ""      // введённый пароль
    property string pending: ""     // пароль, ушедший в PAM
    property bool busy: false
    property string status: ""
    property int shakeKey: 0
    property bool reveal: false         // показать вводимый пароль
    property bool fpAvailable: false    // есть сканер и записанные пальцы
    property int fpFails: 0
    property bool denyFlash: false
    property int batPct: UPower.displayDevice.percentage >= 0
        ? Math.round(UPower.displayDevice.percentage * 100) : -1
    readonly property bool charging: UI.locked && (root.batPct < 100 || Power.watts > 0.5)

    onShakeKeyChanged: { denyFlash = true; denyTimer.restart() }
    Timer { id: denyTimer; interval: 420; onTriggered: root.denyFlash = false }

    // ───────── авто-блокировка по idle ─────────
    IdleMonitor {
        id: idleMon
        timeout: PanelConfig.lockAfterMin * 60
        respectInhibitors: true
    }
    IdleMonitor {
        id: idleSleepMon
        timeout: PanelConfig.sleepAfterMin * 60
        respectInhibitors: true
    }
    Connections {
        target: idleMon
        function onIsIdleChanged() { if (idleMon.isIdle && !UI.locked) UI.locked = true }
    }
    Connections {
        target: idleSleepMon
        function onIsIdleChanged() { if (idleSleepMon.isIdle && !UI.locked) UI.locked = true }
    }

    // обои берём у pywal, иначе из переключателя обоев
    property string walPath: ""
    readonly property string wallpaper: walPath !== "" ? walPath : Wallpapers.current

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/wal/wal"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.walPath = text().trim()
    }

    // ───────── уведомления, пока экран заблокирован ─────────
    property int lockSeen: 0
    property bool lockDirty: false
    Connections {
        target: Notifs
        enabled: UI.locked
        function onCountChanged() { if (Notifs.count > lockSeen) lockDirty = true }
    }
    Connections {
        target: UI
        function onLockedChanged() { if (UI.locked) { lockSeen = Notifs.count; lockDirty = false } }
    }

    // системные показатели обновляем только пока экран заблокирован
    Connections {
        target: UI
        function onLockedChanged() { SysStats.active = UI.locked }
    }

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
            if (root.debug) console.log("Lock: unix_chkpwd код", code)
            if (code === 0) {
                watchdog.stop()
                root.pending = ""
                root.busy = false
                UI.locked = false
            } else if (code === 127) {
                if (root.debug) console.log("Lock: unix_chkpwd не найден, пробую PAM")
                watchdog.restart()
                pam.start()
            } else {
                watchdog.stop()
                root.pending = ""
                root.busy = false
                root.status = I18n.t("Неверный пароль")
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
            root.status = I18n.t("Проверка не отвечает")
            root.shakeKey++
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onPamMessage: {
            if (root.debug) console.log("Lock: pamMessage:", message, "| responseRequired:", responseRequired, "| isError:", messageIsError)
            if (responseRequired) {
                if (root.pending !== "") {
                    respond(root.pending)
                    root.pending = ""
                } else {
                    abort()
                }
            }
        }
        onCompleted: result => {
            if (root.debug) console.log("Lock: completed:", result)
            watchdog.stop()
            root.busy = false
            root.pending = ""
            if (result === PamResult.Success) {
                UI.locked = false
            } else {
                root.status = I18n.t("Неверный пароль (") + result + ")"
                root.shakeKey++
            }
        }
        onError: err => {
            console.warn("Lock: PAM error:", err)
            watchdog.stop()
            root.busy = false
            root.pending = ""
            root.status = I18n.t("Ошибка PAM (см. лог)")
            root.shakeKey++
        }
    }

    // ───────── отпечаток пальца (fprintd) ─────────
    Process {
        id: fpCheck
        command: ["sh", "-c", "command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$USER\" 2>/dev/null | grep -q '^ - #'"]
        running: true
        onExited: code => {
            root.fpAvailable = (code === 0)
            if (root.debug) console.log("Lock: отпечаток доступен:", root.fpAvailable)
        }
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

        onPamMessage: if (root.debug) console.log("Lock: fprint:", message)
        onCompleted: result => {
            if (root.debug) console.log("Lock: fprint completed:", result)
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
            color: Rock.ink

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

                property real enterP: 0
                NumberAnimation on enterP {
                    id: enterAnim
                    from: 0; to: 1
                    duration: 1000
                    easing.type: Easing.OutCubic
                    running: UI.locked
                    loops: 1
                }
                Connections {
                    target: UI
                    function onLockedChanged() {
                        if (UI.locked) { view.enterP = 0; enterAnim.restart() }
                    }
                }

                LockBackground {
                    anchors.fill: parent
                    wallpaper: root.wallpaper
                    enterProgress: view.enterP
                    flash: root.denyFlash
                }

                LockHud {
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right
                        topMargin: 22; leftMargin: 42; rightMargin: 42
                    }
                    enterProgress: view.enterP
                    batPct: root.batPct
                    charging: root.charging
                    lockDirty: root.lockDirty
                }

                LockClock {
                    anchors {
                        left: parent.left; top: parent.top
                        leftMargin: Math.max(46, parent.width * 0.06)
                        topMargin: Math.max(110, parent.height * 0.15)
                    }
                    enterProgress: view.enterP
                }

                LockAuthPanel {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                        horizontalCenterOffset: parent.width * 0.16
                        verticalCenterOffset: -10
                    }
                    enterProgress: view.enterP
                    buffer: root.buffer
                    busy: root.busy
                    reveal: root.reveal
                    status: root.status
                    shakeKey: root.shakeKey
                    fpAvailable: root.fpAvailable
                    fpFails: root.fpFails
                    batPct: root.batPct
                    charging: root.charging
                    onSubmitted: root.submit()
                    onRevealRequested: root.reveal = !root.reveal
                }

                LockWeather {
                    anchors {
                        left: parent.left; bottom: parent.bottom
                        leftMargin: Math.max(42, parent.width * 0.05)
                        bottomMargin: 34
                    }
                    enterProgress: view.enterP
                }

                LockMedia {
                    anchors {
                        right: parent.right; bottom: parent.bottom
                        rightMargin: Math.max(42, parent.width * 0.05)
                        bottomMargin: 34
                    }
                    enterProgress: view.enterP
                }

                opacity: view.enterP
            }
        }
    }

    // quickshell ipc call lock lock
    IpcHandler {
        target: "lock"
        function lock() { UI.session = false; UI.launcher = false; UI.locked = true }
        function status() { return UI.locked }
    }
}
