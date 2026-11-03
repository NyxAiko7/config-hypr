import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    default property alias content: row.data
    property bool interactive: false
    signal clicked(var mouse)
    signal scrolled(var wheel)
    readonly property bool hovered: hover.containsMouse

    implicitHeight: Theme.islandHeight - 8
    implicitWidth: row.implicitWidth + 16
    radius: 7

    color: root.hovered && root.interactive ? Rock.a(Rock.pink, 0.18) : "transparent"
    border.width: 1
    border.color: root.hovered && root.interactive
        ? Rock.a(Rock.pink, 0.55)
        : "transparent"

    scale: root.interactive && hover.pressed ? 0.94 : 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
