import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "qs-widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
        Region {
            item: clockWidget.visible ? clockWidget : null
            radius: clockWidget.width / 2
        }
        Region {
            item: playerWidget.visible ? playerWidget : null
            topLeftRadius: playerWidget.cut
            bottomRightRadius: playerWidget.cut
        }
    }

    DeskClock {
        id: clockWidget
        visible: PanelConfig.widgetsEnabled && PanelConfig.widgetClock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.rightMargin: 48
    }

    DeskPlayer {
        id: playerWidget
        visible: PanelConfig.widgetsEnabled && PanelConfig.widgetPlayer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 48
        anchors.leftMargin: 48
    }
}
