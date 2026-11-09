import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    default property alias content: row.data
    property bool interactive: false
    signal clicked(var mouse)
    signal scrolled(var wheel)
    readonly property bool hovered: hover.containsMouse
    readonly property bool vertical: PanelConfig.vertical

    implicitHeight: vertical ? row.implicitHeight + 10 : Theme.islandHeight - 8
    implicitWidth: vertical ? row.implicitWidth + 12 : row.implicitWidth + 16
    radius: Rock.pillRadius

    color: root.hovered && root.interactive ? Rock.a(Rock.pink, Rock.comic ? 0.18 : 0.14) : "transparent"
    border.width: root.hovered && root.interactive ? 1 : 0
    border.color: root.hovered && root.interactive
        ? Rock.a(Rock.pink, Rock.comic ? 0.55 : 0.65)
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

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.vertical ? 1 : 1000
        rowSpacing: root.vertical ? 5 : 8
        columnSpacing: root.vertical ? 5 : 8
    }
}
