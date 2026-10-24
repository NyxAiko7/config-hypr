import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower

// Следит за событиями системы и отправляет их в «динамический остров»
Scope {
    id: root

    property bool ready: false
    property int prevCount: 0

    Timer { interval: 4000; running: true; onTriggered: root.ready = true }

    // Смена трека
    Timer {
        id: trackDebounce
        interval: 400
        onTriggered: {
            const p = Media.player
            if (p && p.trackTitle)
                UI.flash("\uf001", p.trackTitle, p.trackArtist, p.trackArtUrl, "media")
        }
    }
    Connections {
        target: Media.player
        function onTrackTitleChanged() { if (root.ready) trackDebounce.restart() }
    }

    // Раскладка клавиатуры
    Connections {
        target: Kb
        function onLayoutChanged() {
            if (root.ready) UI.flash("\uf11c", Kb.layout, "Раскладка")
        }
    }

    // Зарядка
    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            const d = UPower.displayDevice
            if (!root.ready || !d.isLaptopBattery) return
            const pct = Math.round(d.percentage * 100) + "%"
            if (d.state === UPowerDeviceState.Charging) UI.flash("\uf0e7", "Зарядка", pct)
            else if (d.state === UPowerDeviceState.Discharging) UI.flash("\uf240", "От батареи", pct)
        }
    }

    // Уведомления SwayNC
    Connections {
        target: SwayNC
        function onCountChanged() {
            if (root.ready && SwayNC.count > root.prevCount && !SwayNC.dnd)
                UI.flash("\uf0f3", "Новое уведомление", SwayNC.count + " в центре")
            root.prevCount = SwayNC.count
        }
        function onDndChanged() {
            if (root.ready)
                UI.flash(SwayNC.dnd ? "\uf1f6" : "\uf0f3",
                         SwayNC.dnd ? "Не беспокоить" : "Уведомления включены")
        }
    }

    // Подключение к сети
    Connections {
        target: Net
        function onConnectionChanged() {
            if (!root.ready) return
            if (Net.connection !== "") UI.flash(Net.icon, Net.connection, "Подключено")
            else UI.flash(Net.icon, "Сеть отключена", "")
        }
    }

    // Bluetooth-устройства
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    property int prevBt: -1
    onBtConnectedChanged: {
        const n = btConnected.length
        if (root.ready && prevBt >= 0) {
            if (n > prevBt) {
                const d = btConnected[n - 1]
                UI.flash("\uf293", d.name || d.deviceName || "Устройство", "Подключено")
            } else if (n < prevBt) {
                UI.flash("\uf293", "Устройство отключено", "")
            }
        }
        prevBt = n
    }
    Component.onCompleted: prevBt = btConnected.length
}
