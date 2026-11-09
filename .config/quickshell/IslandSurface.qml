import QtQuick

// Поверхность острова панели: мягкое матовое стекло с тонкой
// акцентной кромкой, градиентом и бликом сверху.
Item {
    id: surface

    property real radius: Rock.panelRadius
    property bool active: false
    property bool pulse: false
    property color fill: Rock.islandFill
    property color edge: Rock.uiEdge
    property color shadowColor: Rock.uiAccent
    property real shadowOffset: 0
    property int borderWidth: Rock.panelBorder

    // мягкое свечение вокруг активного острова
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: surface.radius + 5
        color: "transparent"
        border.width: 2
        border.color: Rock.a(surface.shadowColor, surface.active ? 0.35 : 0.16)
        Behavior on border.color { ColorAnimation { duration: 220 } }
    }

    // сама карточка
    Rectangle {
        id: card
        anchors.fill: parent
        radius: surface.radius
        border.width: surface.borderWidth
        border.color: surface.active
            ? Rock.uiAccent
            : Rock.a(Rock.uiAccent, 0.30)
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.lighter(surface.fill, 1.14) }
            GradientStop { position: 1.0; color: Qt.darker(surface.fill, 1.10) }
        }
        clip: true
        Behavior on border.color { ColorAnimation { duration: 180 } }

        // тонкий блик сверху
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 2
            height: 1
            radius: 0.5
            color: Rock.a(Rock.starlight, 0.22)
        }
    }

    // акцентная «пульсация» в режиме события
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: "transparent"
        border.width: surface.borderWidth + 1
        border.color: Rock.uiAccent
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
