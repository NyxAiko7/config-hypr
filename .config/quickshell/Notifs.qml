pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Демон уведомлений: показывает их в динамическом острове и хранит историю.
// Важно: должен быть единственным демоном (swaync, mako, dunst — выключить).
Singleton {
    id: root

    property bool dnd: false
    readonly property var list: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    // ── показ в острове ──
    property var current: null            // что сейчас в острове
    property var queue: []                // ждут своей очереди
    property bool hold: false             // курсор над островом
    property int key: 0                   // растёт с каждым показом
    property int duration: 6500           // 0 = не закрывать само (критичные)
    property int remaining: 0
    property double deadline: 0
    readonly property int pending: queue.length

    // ── время для подписей «5 мин» ──
    property double now: Date.now()
    property var arrived: ({})
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

    // ── сгруппировано по приложениям, новые сверху ──
    readonly property var groups: {
        const vals = server.trackedNotifications.values
        const map = {}
        const order = []
        for (let i = vals.length - 1; i >= 0; i--) {
            const n = vals[i]
            const k = n.appName || "Прочее"
            if (!map[k]) { map[k] = { app: k, items: [] }; order.push(k) }
            map[k].items.push(n)
        }
        return order.map(k => map[k])
    }

    // ───────── помощники для интерфейса ─────────
    function timeAgo(n) {
        if (!n) return ""
        const t = arrived[n.id]
        if (!t) return ""
        const s = Math.floor((now - t) / 1000)
        if (s < 60) return "сейчас"
        const m = Math.floor(s / 60)
        if (m < 60) return m + " мин"
        const h = Math.floor(m / 60)
        if (h < 24) return h + " ч"
        return Math.floor(h / 24) + " д"
    }

    function appIconSource(n) {
        if (!n) return ""
        let name = n.appIcon || ""
        if (name === "" && n.desktopEntry) {
            try {
                const e = DesktopEntries.byId(n.desktopEntry)
                if (e) name = e.icon
            } catch (err) {}
        }
        return name !== "" ? Quickshell.iconPath(name) : ""
    }

    function contentImage(n) { return (n && n.image) ? n.image : "" }

    function defaultAction(n) {
        if (!n) return null
        const a = n.actions
        for (let i = 0; i < a.length; i++) if (a[i].identifier === "default") return a[i]
        return null
    }

    function actionList(n) {
        const out = []
        if (!n) return out
        const a = n.actions
        for (let i = 0; i < a.length && out.length < 3; i++)
            if (a[i].identifier !== "default" && a[i].text !== "") out.push(a[i])
        return out
    }

    // ───────── очередь показа ─────────
    function isTracked(n) { return server.trackedNotifications.values.indexOf(n) >= 0 }

    function startTimer(ms) {
        showTimer.interval = ms
        deadline = Date.now() + ms
        showTimer.restart()
    }

    function display(n) {
        current = n
        key++
        const critical = n.urgency === NotificationUrgency.Critical
        duration = critical ? 0 : (n.expireTimeout > 0 ? Math.max(4000, n.expireTimeout * 1000) : 6500)
        if (duration === 0) showTimer.stop()
        else if (hold) { remaining = duration; showTimer.stop() }
        else startTimer(duration)
    }

    function incoming(n) {
        arrived[n.id] = Date.now()
        const critical = n.urgency === NotificationUrgency.Critical
        if (dnd && !critical) return              // тихо кладём в историю
        if (current === null) display(n)
        else queue = queue.concat([n])
    }

    // убрать из острова (в истории остаётся) и показать следующее
    function next() {
        const old = current
        current = null
        hold = false
        showTimer.stop()
        if (old && old.transient && isTracked(old)) old.dismiss()
        while (queue.length > 0) {
            const q = queue.slice()
            const n = q.shift()
            queue = q
            if (isTracked(n)) { display(n); return }
        }
    }
    function hide() { next() }
    function dismissCurrent() {
        const n = current
        next()
        if (n && isTracked(n)) n.dismiss()
    }
    function clearAll() {
        current = null
        queue = []
        showTimer.stop()
        const all = server.trackedNotifications.values.slice()
        for (let i = 0; i < all.length; i++) all[i].dismiss()
    }

    onHoldChanged: {
        if (current === null || duration === 0) return
        if (hold) {
            remaining = Math.max(600, deadline - Date.now())
            showTimer.stop()
        } else startTimer(remaining)
    }

    Timer { id: showTimer; onTriggered: root.next() }

    // приложение само закрыло уведомление, пока оно в острове
    Connections {
        target: root.current
        function onClosed() { root.next() }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true
            root.incoming(n)
        }
    }
}
