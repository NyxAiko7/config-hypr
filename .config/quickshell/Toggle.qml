import QtQuick

Rectangle {
    id: sw
    property bool checked: false
    property color checkedColor: Rock.pink
    property color uncheckedColor: Rock.ink
    property color checkedKnob: Rock.cream
    property color uncheckedKnob: Rock.cream
    property color borderColor: Rock.ink
    property int borderWidth: 2
    signal toggled()

    implicitWidth: 44
    implicitHeight: 26
    radius: 13
    color: checked ? checkedColor : uncheckedColor
    border.width: borderWidth
    border.color: borderColor
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        y: 3
        x: sw.checked ? sw.width - width - 3 : 3
        width: 20; height: 20; radius: 10
        color: sw.checked ? checkedKnob : uncheckedKnob
        border.width: 1.5
        border.color: Rock.ink
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }
}
