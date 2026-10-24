pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool launcher: false
    property bool session: false
    property bool wallpaper: false
    property string wifiSsid: ""      // непустое = показать запрос пароля

    property string osdKind: ""          // "volume" | "brightness"
    property bool osdVisible: false

    function showOsd(kind) {
        osdKind = kind
        osdVisible = true
        osdTimer.restart()
    }
    Timer { id: osdTimer; interval: 1500; onTriggered: root.osdVisible = false }

    // ── Динамический остров: короткие события в центре бара ──
    property bool eventActive: false
    property string eventKind: ""        // "media" | "info"
    property string eventIcon: ""
    property string eventText: ""
    property string eventSub: ""
    property string eventArt: ""

    function flash(icon, text, sub, art, kind) {
        eventIcon = icon
        eventText = text
        eventSub = sub || ""
        eventArt = art || ""
        eventKind = kind || "info"
        eventActive = true
        eventTimer.restart()
    }
    Timer { id: eventTimer; interval: 3800; onTriggered: root.eventActive = false }
}
