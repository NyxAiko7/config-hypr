import QtQuick
import QtQuick.Layouts

// Кнопка-стикер в духе Bocchi the Rock: жирный контур и офсетная тень.
Item {
    id: sb
    property string icon: ""
    property string label: ""
    property color fill: Rock.uiSurface
    property color shadowColor: Rock.pink
    property color fg: Rock.ink
    signal clicked()

    implicitWidth: Math.max(44, content.implicitWidth + 26)
    implicitHeight: 41

    Rectangle {
        visible: Rock.comic
        x: 3; y: 3
        width: sb.width; height: 38
        radius: 10
        color: sb.shadowColor
        border.width: 2
        border.color: Rock.ink
    }
    Rectangle {
        id: body
        width: sb.width; height: 38
        radius: Rock.comic ? 10 : Rock.marisa ? 4 : 8
        color: area.containsMouse ? Qt.lighter(sb.fill, 1.1) : sb.fill
        border.width: Rock.uiBorder
        border.color: Rock.comic ? Rock.ink : Rock.a(Rock.gold, 0.55)
        Behavior on color { ColorAnimation { duration: 110 } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 7
            Lbl {
                visible: sb.icon !== ""
                text: sb.icon
                color: sb.fg
                font.pixelSize: 12
                font.weight: Font.Black
            }
            Lbl {
                visible: sb.label !== ""
                text: sb.label
                color: sb.fg
                font.family: Rock.display
                font.pixelSize: 10
                font.weight: Font.Black
                font.letterSpacing: 1
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.clicked()
        }
    }
}
