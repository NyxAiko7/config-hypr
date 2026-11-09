import QtQuick
import QtQuick.Layouts

// Маленький «стикер» с жёсткой тенью — для HUD и подсказок.
// В стиле HSR тень убирается, остаются тонкая кромка и золотой акцент.
Item {
    id: root

    property color fill: Rock.uiSurface
    property color edge: Rock.ink
    property color shadowColor: Rock.pink
    property real offset: Rock.chipOffset
    property real radius: Rock.chipRadius
    property int borderWidth: Rock.chipBorder
    property real padH: 10
    property real padV: 4
    property real spacing: 6

    default property alias content: row.data

    implicitWidth: card.width
    implicitHeight: card.height

    Rectangle {
        visible: Rock.comic
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
        border.color: Rock.comic ? root.edge : Rock.a(Rock.gold, 0.55)
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: Rock.comic ? root.fill : Qt.lighter(root.fill, 1.08)
            }
            GradientStop {
                position: 1.0
                color: Rock.comic ? root.fill : Qt.darker(root.fill, 1.04)
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: root.spacing
        }
    }
}
