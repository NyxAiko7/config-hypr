import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Следит за событиями системы и отправляет их в «динамический остров»
Scope {
    id: root

    property bool ready: false
    property int batStage: 0
    property var warnedBt: ({})
    property int prevBt: -1

    Timer { interval: 4000; running: true; onTriggered: root.ready = true }
    Component.onCompleted: prevBt = Bt.connected.length

    // ── Смена трека ──
    Timer {
        id: trackDebounce
        interval: 400
        onTriggered: {
            const p = Media.player
            if (p && p.trackTitle)
                UI.flash("\uf001", p.trackTitle, p.trackArtist, p.trackArtUrl, "media", "media")
        }
    }
    Connections {
        target: Media.player
        function onTrackTitleChanged() { if (root.ready) trackDebounce.restart() }
    }

    // ── Раскладка ──
    Connections {
        target: Kb
        function onLayoutChanged() {
            if (root.ready) UI.flash("\uf11c", Kb.layout, "Раскладка", "", "layout", "")
        }
    }

    // ── Батарея ноутбука ──
    function checkBattery() {
        const d = UPower.displayDevice
        if (!root.ready || !d.isLaptopBattery) return
        const pct = Math.round(d.percentage * 100)
        if (d.state === UPowerDeviceState.Discharging) {
            if (pct <= 10 && batStage < 2) {
                batStage = 2
                UI.flash("\uf244", "Критический заряд", pct + "% — подключи питание", "", "battery", "cc")
            } else if (pct <= 20 && batStage < 1) {
                batStage = 1
                UI.flash("\uf243", "Низкий заряд", pct + "%", "", "battery", "cc")
            }
        } else if (pct > 25) batStage = 0
    }
    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            const d = UPower.displayDevice
            if (!root.ready || !d.isLaptopBattery) return
            const pct = Math.round(d.percentage * 100) + "%"
            if (d.state === UPowerDeviceState.Charging) { root.batStage = 0; UI.flash("\uf0e7", "Зарядка", pct, "", "battery", "cc") }
            else if (d.state === UPowerDeviceState.Discharging) UI.flash("\uf240", "От батареи", pct, "", "battery", "cc")
        }
        function onPercentageChanged() { root.checkBattery() }
    }

    // ── Режим «Тишина» ──
    Connections {
        target: Notifs
        function onDndChanged() {
            if (root.ready)
                UI.flash(Notifs.dnd ? "\uf1f6" : "\uf0f3",
                         Notifs.dnd ? "Тишина включена" : "Уведомления включены",
                         Notifs.dnd ? "Сообщения придут в историю" : "", "", "notif", "notifs")
        }
    }

    // ── Сеть ──
    Connections {
        target: Net
        function onConnectionChanged() {
            if (!root.ready) return
            if (Net.connection !== "") UI.flash(Net.icon, Net.connection, "Подключено", "", "net", "wifi")
            else UI.flash(Net.icon, "Сеть отключена", "", "", "net", "wifi")
        }
    }

    // ── VPN ──
    Connections {
        target: Net
        function onVpnChanged() {
            if (!root.ready || !Net.vpnInit) return
            if (Net.vpn) UI.flash("\uf132", "VPN включён", Net.vpnName, "", "net", "wifi")
            else UI.flash("\uf132", "VPN выключен", "", "", "net", "wifi")
        }
    }

    // ── Bluetooth: подключение / отключение ──
    readonly property var btConnected: Bt.connected
    onBtConnectedChanged: {
        const n = btConnected.length
        if (root.ready && prevBt >= 0) {
            if (n > prevBt) {
                const d = btConnected[n - 1]
                const p = Bt.percent(d)
                UI.flash(Bt.iconFor(d), Bt.nameOf(d),
                         "Подключено" + (p >= 0 ? "  ·  " + p + "%" : ""), "", "bt", "bt")
            } else if (n < prevBt) {
                UI.flash("\uf293", "Устройство отключено", "", "", "bt", "bt")
            }
        }
        prevBt = n
    }

    // ── Bluetooth: низкий заряд устройств ──
    function checkBt() {
        if (!root.ready) return
        const list = Bt.connected
        const alive = {}
        for (let i = 0; i < list.length; i++) {
            const d = list[i]
            const p = Bt.percent(d)
            const key = d.address || Bt.nameOf(d)
            alive[key] = true
            if (p >= 0 && p <= 20 && !warnedBt[key]) {
                warnedBt[key] = true
                UI.flash(Bt.iconFor(d), Bt.nameOf(d), "Низкий заряд  ·  " + p + "%", "", "battery", "bt")
            } else if (p > 30) delete warnedBt[key]
        }
        for (const k in warnedBt) if (!alive[k]) delete warnedBt[k]
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.checkBt() }
}
