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
        { icon: "\uf023", label: I18n.t("Блокировка"),    key: "L", lock: true, cmd: [], danger: false },
        { icon: "\uf2f5", label: I18n.t("Выход"),         key: "E", cmd: ["hyprctl", "dispatch", "exit"], danger: false },
        { icon: "\uf186", label: I18n.t("Сон"),           key: "S", cmd: ["sh", "-c", "loginctl suspend || systemctl suspend"], danger: false },
        { icon: "\uf021", label: I18n.t("Перезагрузка"),  key: "R", cmd: ["sh", "-c", "loginctl reboot || reboot"], danger: true },
        { icon: "\uf011", label: I18n.t("Выключение"),    key: "P", cmd: ["sh", "-c", "loginctl poweroff || poweroff"], danger: true }
    ]

    function run(a) {
        UI.session = false
        if (a.lock) { UI.locked = true; return }
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
        radius: Rock.sao ? 6 : Rock.marisa ? 8 : 24
        color: Rock.marisa || Rock.sao ? Rock.uiSurface : Theme.popupBg
        border.width: Rock.sao ? 1 : 1
        border.color: Rock.sao ? Rock.uiEdge : Rock.marisa ? Rock.uiEdge : Theme.hairline

        MouseArea { anchors.fill: parent }

        SaoGrid {
            anchors.fill: parent
            step: 26
        }

        MarisaPattern {
            anchors.fill: parent
            opacity: 0.42
        }

        MarisaTrim {
            visible: Rock.marisa
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 3
            height: 3
            cell: 3
        }

        MarisaFrame {
            anchors.fill: parent
            inset: 6
            frameRadius: Math.max(2, Rock.uiRadiusSm)
            runes: false
        }

        SaoFrame {
            anchors.fill: parent
            inset: 5
            cut: 11
            segments: 28
        }

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
                    radius: Rock.sao ? 4 : Rock.marisa ? 3 : 18
                    color: Rock.marisa || Rock.sao
                        ? (area.containsMouse
                            ? (modelData.danger ? (Rock.sao ? Rock.danger : Theme.warn) : Rock.uiActive)
                            : Rock.uiSurface2)
                        : (area.containsMouse
                            ? (modelData.danger ? Theme.warn : Theme.accent)
                            : Theme.surface)
                    border.width: Rock.marisa || Rock.sao ? 1 : 0
                    border.color: Rock.uiEdge
                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.icon
                            color: Rock.marisa || Rock.sao
                                ? (area.containsMouse ? Rock.uiOnActive : Rock.uiText)
                                : (area.containsMouse ? Theme.textOnAccent : Theme.text)
                            font.pixelSize: 26
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.label
                            color: Rock.marisa || Rock.sao
                                ? (area.containsMouse ? Rock.uiOnActive : Rock.uiText)
                                : (area.containsMouse ? Theme.textOnAccent : Theme.text)
                            font.pixelSize: 12
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.key
                            color: Rock.marisa || Rock.sao
                                ? Rock.a(Rock.uiText, 0.55)
                                : (area.containsMouse ? Theme.textOnAccent : Theme.muted)
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
