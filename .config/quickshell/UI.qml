pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool launcher: false
    property bool session: false

    property string osdKind: ""          // "volume" | "brightness"
    property bool osdVisible: false

    function showOsd(kind) {
        osdKind = kind
        osdVisible = true
        osdTimer.restart()
    }
    Timer { id: osdTimer; interval: 1500; onTriggered: root.osdVisible = false }
}
