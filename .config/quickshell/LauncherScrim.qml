import QtQuick
import Quickshell
import Quickshell.Wayland

// Лёгкая подложка на весь экран, пока открыт лаунчер: клик мимо острова закрывает его.
// Лежит ниже панели (слой Top), а панель на время лаунчера поднимается в Overlay.
PanelWindow {
    id: win

    visible: UI.launcher
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-scrim"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.16)
        opacity: UI.launcher ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: UI.launcher = false
    }
}
