import QtQuick
import Quickshell

BarPopup {
    id: popup
    alignment: "center"
    property var player: null            // оставлено для совместимости с Bar.qml

    implicitWidth: 380
    implicitHeight: card.implicitHeight + 24

    MediaCard {
        id: card
        x: 12
        y: 12
        width: parent.width - 24
        active: popup.visible
    }
}
