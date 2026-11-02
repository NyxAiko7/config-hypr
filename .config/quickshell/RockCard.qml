import QtQuick
import QtQuick.Layouts

// Крупная «наклейка» с толстым контуром и офсетной тенью.
// Содержимое укладывается в ColumnLayout.
Item {
    id: root

    property color fill: Rock.cream
    property color edge: Rock.ink
    property color shadowColor: Rock.pink
    property real shadowOffset: 6
    property real radius: 20
    property int borderWidth: 3
    property real padding: 18
    property real spacing: 10
    property real preferredWidth: 0
    property real preferredHeight: 0

    default property alias content: body.data

    implicitWidth: card.width + shadowOffset
    implicitHeight: card.height + shadowOffset

    Rectangle {
        x: root.shadowOffset
        y: root.shadowOffset
        width: card.width
        height: card.height
        radius: root.radius
        color: root.shadowColor
        border.width: root.borderWidth
        border.color: root.edge
    }

    Rectangle {
        id: card
        width: root.preferredWidth > 0
            ? root.preferredWidth
            : body.implicitWidth + root.padding * 2
        height: root.preferredHeight > 0
            ? root.preferredHeight
            : body.implicitHeight + root.padding * 2
        radius: root.radius
        color: root.fill
        border.width: root.borderWidth
        border.color: root.edge

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.spacing
        }
    }
}
