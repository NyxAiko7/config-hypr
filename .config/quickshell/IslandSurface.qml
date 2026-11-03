import QtQuick

// Поверхность острова в духе локскрина: плотная «наклейка»
// с жирным контуром и жёсткой офсетной тенью.
Item {
    id: surface

    property real radius: 11
    property bool active: false
    property bool pulse: false
    property color fill: Rock.ink2
    property color edge: Rock.ink
    property color shadowColor: Rock.pink
    property real shadowOffset: 3
    property int borderWidth: 2

    // жёсткая тень-подложка
    Rectangle {
        x: surface.shadowOffset
        y: surface.shadowOffset
        width: parent.width
        height: parent.height
        radius: surface.radius
        color: surface.shadowColor
        border.width: surface.borderWidth
        border.color: surface.edge
    }

    // сама карточка
    Rectangle {
        width: parent.width
        height: parent.height
        radius: surface.radius
        color: surface.fill
        border.width: surface.borderWidth
        border.color: surface.active ? Rock.yellow : surface.edge
        Behavior on color { ColorAnimation { duration: 220 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    // акцентная «пульсация» в режиме события
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: "transparent"
        border.width: surface.borderWidth + 1
        border.color: Rock.yellow
        visible: surface.pulse
        opacity: 0
        SequentialAnimation on opacity {
            running: surface.pulse
            loops: Animation.Infinite
            NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.10; duration: 900; easing.type: Easing.InOutSine }
        }
    }
}
