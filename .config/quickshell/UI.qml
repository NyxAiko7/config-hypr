pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool launcher: false
    property string launcherMode: "apps"   // apps | clip | windows
    property bool session: false
    property bool locked: false            // экран блокировки
    property bool wallpaper: false
    property bool caffeine: false          // запрет блокировки/засыпания
    property string wifiSsid: ""           // непустое = показать запрос пароля
    signal toggleCenter()                  // открыть/закрыть центр уведомлений

    // Открыть лаунчер в нужном режиме; повторный вызов того же режима закрывает
    function openLauncher(mode) {
        session = false
        wallpaper = false
        if (launcher && launcherMode === mode) launcher = false
        else { launcherMode = mode; launcher = true }
    }

    // ───────── Динамический остров: события ─────────
    property bool eventActive: false
    property string eventKind: ""          // media | theme | bt | battery | notif | net | layout | weather | level | rec | info
    property string eventIcon: ""
    property string eventText: ""
    property string eventSub: ""
    property string eventArt: ""
    property string eventAction: ""        // что открыть по клику
    property bool eventHold: false         // курсор над островом — не закрывать
    property int eventKey: 0               // растёт с каждым показом
    readonly property int eventDuration: 3800
    property int eventTotal: 3800          // длительность текущего события
    property var eventQueue: []
    property double eventDeadline: 0
    property int eventRemaining: 0

    function startTimer(ms) {
        eventTimer.interval = ms
        eventDeadline = Date.now() + ms
        eventTimer.restart()
    }

    function show(ev) {
        eventIcon = ev.icon
        eventText = ev.text
        eventSub = ev.sub
        eventArt = ev.art
        eventKind = ev.kind
        eventAction = ev.action
        eventTotal = ev.ms > 0 ? ev.ms : eventDuration
        eventKey++
        eventActive = true
        if (eventHold) { eventRemaining = eventTotal; eventTimer.stop() }
        else startTimer(eventTotal)
    }

    // Событие того же типа заменяет текущее, «level» (громкость/яркость) перебивает всё,
    // остальные становятся в очередь (до 3)
    function flash(icon, text, sub, art, kind, action, ms) {
        const ev = { icon: icon, text: text, sub: sub || "", art: art || "",
                     kind: kind || "info", action: action || "", ms: ms || 0 }
        if (!eventActive || ev.kind === eventKind || ev.kind === "level") { show(ev); return }
        const q = eventQueue.filter(e => e.kind !== ev.kind)
        q.push(ev)
        eventQueue = q.slice(-3)
    }

    function dismissEvent() {
        eventQueue = []
        eventActive = false
        eventTimer.stop()
        eventHold = false
    }

    onEventHoldChanged: {
        if (!eventActive) return
        if (eventHold) {
            eventRemaining = Math.max(400, eventDeadline - Date.now())
            eventTimer.stop()
        } else startTimer(eventRemaining)
    }

    Timer {
        id: eventTimer
        onTriggered: {
            if (root.eventQueue.length > 0) {
                const q = root.eventQueue.slice()
                const next = q.shift()
                root.eventQueue = q
                root.show(next)
            } else root.eventActive = false
        }
    }
}
