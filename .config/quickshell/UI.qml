pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool launcher: false
    property bool session: false
    property bool wallpaper: false
    signal toggleCenter()                 // открыть/закрыть центр уведомлений
    property bool caffeine: false         // запрет блокировки/засыпания
    property string wifiSsid: ""          // непустое = показать запрос пароля

    property string osdKind: ""           // "volume" | "brightness"
    property bool osdVisible: false

    function showOsd(kind) {
        osdKind = kind
        osdVisible = true
        osdTimer.restart()
    }
    Timer { id: osdTimer; interval: 1500; onTriggered: root.osdVisible = false }

    // ───────── Динамический остров ─────────
    property bool eventActive: false
    property string eventKind: ""         // media | theme | bt | battery | notif | net | layout | weather | info
    property string eventIcon: ""
    property string eventText: ""
    property string eventSub: ""
    property string eventArt: ""
    property string eventAction: ""       // что открыть по клику: media | bt | wifi | cc | notifs | wallpaper | weather
    property bool eventHold: false        // курсор над островом — не закрывать
    property int eventKey: 0              // растёт с каждым показом (для полоски таймера)
    readonly property int eventDuration: 3800
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
        eventKey++
        eventActive = true
        if (eventHold) { eventRemaining = eventDuration; eventTimer.stop() }
        else startTimer(eventDuration)
    }

    // Новое событие того же типа заменяет текущее, остальные становятся в очередь (до 3)
    function flash(icon, text, sub, art, kind, action) {
        const ev = { icon: icon, text: text, sub: sub || "", art: art || "",
                     kind: kind || "info", action: action || "" }
        if (!eventActive || ev.kind === eventKind) { show(ev); return }
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
