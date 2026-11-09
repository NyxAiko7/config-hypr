import QtQuick
import QtQuick.Layouts

// Крупная «наклейка» с толстым контуром и офсетной тенью.
// Содержимое укладывается в ColumnLayout.
Item {
    id: root

    property color fill: Rock.uiSurface
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
        visible: Rock.comic
        x: root.shadowOffset
        y: root.shadowOffset
        width: card.width
        height: card.height
        radius: root.radius
        color: root.shadowColor
        border.width: root.borderWidth
        border.color: root.edge
    }

    // пергаментная страница на пергаменте: чернильная офсетная тень
    Rectangle {
        visible: Rock.marisa
        x: 6
        y: 6
        width: card.width
        height: card.height
        radius: card.radius
        color: Rock.a(Rock.ink, 0.16)
        border.width: 1
        border.color: Rock.a(Rock.ink, 0.18)
    }

    Rectangle {
        id: card
        width: root.preferredWidth > 0
            ? root.preferredWidth
            : body.implicitWidth + root.padding * 2
        height: root.preferredHeight > 0
            ? root.preferredHeight
            : body.implicitHeight + root.padding * 2
        radius: Rock.comic ? root.radius : Rock.uiRadius
        color: root.fill
        border.width: Rock.comic ? root.borderWidth : Rock.uiBorder
        border.color: Rock.comic ? root.edge : Rock.uiEdge
        clip: true

        SaoGrid {
            anchors.fill: parent
            step: 22
        }

        MarisaPattern {
            anchors.fill: parent
            opacity: 0.5
        }

        MarisaTrim {
            visible: Rock.marisa
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 5
            height: 3
            cell: 3
        }

        MarisaFrame {
            anchors.fill: parent
            inset: 6
            frameRadius: Math.max(2, Rock.uiRadius - 4)
            runes: false
        }

        SaoFrame {
            anchors.fill: parent
            inset: 4
            cut: 9
            segments: 20
        }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.spacing
        }
    }
}
