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
    implicitWidth: row.implicitWidth + 18
    radius: 9

    color: root.hovered && root.interactive ? Theme.islandHover : "transparent"
    border.width: 1
    border.color: root.hovered && root.interactive
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30)
        : "transparent"

    scale: root.interactive && hover.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

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
        spacing: 10
    }
}
