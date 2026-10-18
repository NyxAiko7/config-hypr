import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: UI.session
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-session"
    WlrLayershell.keyboardFocus: UI.session ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // Artix: без systemd, поэтому loginctl (elogind) с запасными вариантами
    readonly property var actions: [
        { icon: "\uf023", label: "Блокировка",    key: "L", cmd: ["sh", "-c", "command -v hyprlock >/dev/null && exec hyprlock || loginctl lock-session"], danger: false },
        { icon: "\uf2f5", label: "Выход",         key: "E", cmd: ["hyprctl", "dispatch", "exit"], danger: false },
        { icon: "\uf186", label: "Сон",           key: "S", cmd: ["sh", "-c", "loginctl suspend || systemctl suspend"], danger: false },
        { icon: "\uf021", label: "Перезагрузка",  key: "R", cmd: ["sh", "-c", "loginctl reboot || reboot"], danger: true },
        { icon: "\uf011", label: "Выключение",    key: "P", cmd: ["sh", "-c", "loginctl poweroff || poweroff"], danger: true }
    ]

    function run(a) {
        UI.session = false
        Quickshell.execDetached(a.cmd)
    }

    onVisibleChanged: if (visible) { keys.forceActiveFocus(); fadeIn.restart() }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea { anchors.fill: parent; onClicked: UI.session = false }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) { UI.session = false; event.accepted = true; return }
            const k = event.text.toUpperCase()
            for (let i = 0; i < win.actions.length; i++)
                if (win.actions[i].key === k) { win.run(win.actions[i]); event.accepted = true; return }
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: row.implicitWidth + 48
        height: row.implicitHeight + 48
        radius: 24
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.hairline

        MouseArea { anchors.fill: parent }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: win.actions
                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    implicitWidth: 104
                    implicitHeight: 112
                    radius: 18
                    color: area.containsMouse
                        ? (modelData.danger ? Theme.warn : Theme.accent)
                        : Theme.surface
                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.icon
                            color: area.containsMouse ? Theme.textOnAccent : Theme.text
                            font.pixelSize: 26
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.label
                            color: area.containsMouse ? Theme.textOnAccent : Theme.text
                            font.pixelSize: 12
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.key
                            color: area.containsMouse ? Theme.textOnAccent : Theme.muted
                            opacity: 0.7
                            font.pixelSize: 10
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.run(btn.modelData)
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: fadeIn
        NumberAnimation { target: dim;  property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "scale";   from: 0.96; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
