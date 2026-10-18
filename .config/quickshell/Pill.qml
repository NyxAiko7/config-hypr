import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    default property alias content: row.data
    property bool interactive: false
    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitHeight: Theme.barHeight - 8
    implicitWidth: row.implicitWidth + 20
    radius: 10
    color: (interactive && hover.containsMouse)
        ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09)
        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0)
    Behavior on color { ColorAnimation { duration: 140 } }

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
