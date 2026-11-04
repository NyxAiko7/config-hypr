import QtQuick

Rectangle {
    id: sw
    property bool checked: false
    signal toggled()

    implicitWidth: 44
    implicitHeight: 26
    radius: 13
    color: checked ? Theme.accent : Theme.surface
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        y: 3
        x: sw.checked ? sw.width - width - 3 : 3
        width: 20; height: 20; radius: 10
        color: sw.checked ? Theme.textOnAccent : Theme.muted
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }
}
