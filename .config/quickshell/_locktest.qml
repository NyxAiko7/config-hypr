import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-locktest"
        color: "black"

        Item {
            anchors.fill: parent

            LockBackground {
                anchors.fill: parent
                wallpaper: ""
                enterProgress: 1
            }
            LockHud {
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 22; leftMargin: 42; rightMargin: 42 }
                enterProgress: 1
                batPct: 80
                charging: false
                lockDirty: true
            }
            LockClock {
                anchors { left: parent.left; top: parent.top; leftMargin: 100; topMargin: 150 }
                enterProgress: 1
            }
            LockAuthPanel {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 260
                enterProgress: 1
                buffer: "secret"
                fpAvailable: true
                batPct: 80
            }
            LockWeather {
                anchors { left: parent.left; bottom: parent.bottom; leftMargin: 60; bottomMargin: 34 }
                enterProgress: 1
            }
            LockMedia {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 60; bottomMargin: 34 }
                enterProgress: 1
            }
        }
    }
}
