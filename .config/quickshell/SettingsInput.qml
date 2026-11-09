import QtQuick

// Небольшое текстовое поле для строки настроек.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property int fieldWidth: 110
    signal edited(string value)

    implicitWidth: fieldWidth
    implicitHeight: 30
    radius: Math.max(6, PanelConfig.islandRadius - 6)
    color: hover.hovered ? Rock.a(Rock.uiAccent, 0.12) : Rock.a(Rock.uiText, 0.05)
    border.width: 1
    border.color: input.activeFocus ? Rock.uiAccent : Rock.a(Rock.uiText, 0.18)
    Behavior on color { ColorAnimation { duration: 120 } }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        color: Rock.uiText
        font.family: Rock.mono
        font.pixelSize: 11
        selectByMouse: true
        clip: true
        onEditingFinished: root.edited(text)
        Keys.onReturnPressed: root.edited(text)
        Keys.onEscapePressed: focus = false

        Lbl {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Rock.a(Rock.uiText, 0.38)
            font.pixelSize: 10
        }
    }

    HoverHandler {
        id: hover
    }
}
