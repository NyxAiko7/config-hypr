import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: UI.wifiSsid !== ""
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-prompt"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    property bool reveal: false

    function submit() {
        const ssid = UI.wifiSsid
        const pw = input.text
        UI.wifiSsid = ""
        if (pw.length > 0) Net.connectTo(ssid, pw)
    }
    function cancel() { UI.wifiSsid = "" }

    onVisibleChanged: if (visible) {
        input.text = ""
        reveal = false
        input.forceActiveFocus()
        fade.restart()
    }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea { anchors.fill: parent; onClicked: win.cancel() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 390
        height: col.implicitHeight + 48
        radius: 22
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.hairline
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 20
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                    Lbl { anchors.centerIn: parent; text: "\uf023"; color: Theme.accent; font.pixelSize: 16 }
                }
                ColumnLayout {
                    spacing: 0
                    Lbl { text: "Подключение к сети"; color: Theme.muted; font.pixelSize: 11 }
                    Lbl { Layout.maximumWidth: 280; text: UI.wifiSsid; font.bold: true; font.pixelSize: 15; elide: Text.ElideRight }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 14
                color: Theme.surface
                border.width: input.activeFocus ? 1 : 0
                border.color: Theme.accent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 8
                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14
                        echoMode: win.reveal ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.textOnAccent
                        clip: true
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.submit(); event.accepted = true }
                            else if (event.key === Qt.Key_Escape) { win.cancel(); event.accepted = true }
                        }
                        Lbl {
                            visible: input.text === ""
                            text: "Пароль"
                            color: Theme.muted
                            font.pixelSize: 14
                        }
                    }
                    IconBtn {
                        size: 30
                        icon: win.reveal ? "\uf070" : "\uf06e"
                        onClicked: win.reveal = !win.reveal
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: 96; implicitHeight: 38; radius: 19
                    color: cancelArea.containsMouse ? Theme.surface : "transparent"
                    Lbl { anchors.centerIn: parent; text: "Отмена"; color: Theme.muted }
                    MouseArea { id: cancelArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.cancel() }
                }
                Rectangle {
                    implicitWidth: 120; implicitHeight: 38; radius: 19
                    color: okArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                    Lbl { anchors.centerIn: parent; text: "Подключить"; color: Theme.textOnAccent; font.bold: true }
                    MouseArea { id: okArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.submit() }
                }
            }
        }
    }

    ParallelAnimation {
        id: fade
        NumberAnimation { target: dim;  property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "scale";   from: 0.96; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
