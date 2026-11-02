import QtQuick
import QtQuick.Layouts

// Маленький «стикер» с жёсткой тенью — для HUD и подсказок локскрина.
Item {
    id: root

    property color fill: Rock.cream
    property color edge: Rock.ink
    property color shadowColor: Rock.pink
    property real offset: 2.5
    property real radius: 8
    property int borderWidth: 2
    property real padH: 10
    property real padV: 4
    property real spacing: 6

    default property alias content: row.data

    implicitWidth: card.width
    implicitHeight: card.height

    Rectangle {
        x: root.offset
        y: root.offset
        width: card.width
        height: card.height
        radius: root.radius
        color: root.shadowColor
        border.width: root.borderWidth
        border.color: root.edge
    }

    Rectangle {
        id: card
        width: row.implicitWidth + root.padH * 2
        height: row.implicitHeight + root.padV * 2
        radius: root.radius
        color: root.fill
        border.width: root.borderWidth
        border.color: root.edge

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: root.spacing
        }
    }
}
