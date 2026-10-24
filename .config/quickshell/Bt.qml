pragma Singleton
import Quickshell
import Quickshell.Bluetooth

// Подключённые устройства, иконки и заряд — в одном месте
Singleton {
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    function iconFor(d) {
        const i = String(d.icon || "")
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "\uf025"
        if (i.indexOf("keyboard") >= 0) return "\uf11c"
        if (i.indexOf("mouse") >= 0) return "\uf245"
        if (i.indexOf("phone") >= 0) return "\uf10b"
        if (i.indexOf("gaming") >= 0) return "\uf11b"
        if (i.indexOf("speaker") >= 0 || i.indexOf("audio") >= 0) return "\uf028"
        return "\uf293"
    }
    function nameOf(d) { return d.name || d.deviceName || d.address || "Устройство" }
    // заряд в процентах, -1 если устройство его не сообщает
    function percent(d) {
        if (!d.batteryAvailable) return -1
        const b = d.battery
        return Math.round(b > 1 ? b : b * 100)
    }
}
