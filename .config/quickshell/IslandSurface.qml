import QtQuick

// Поверхность острова: матовое стекло, мягкий градиент и тонкий блик.
Item {
    id: surface

    property real radius: Theme.islandRadius
    property bool active: false
    property bool pulse: false

    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Theme.islandTop }
            GradientStop { position: 0.45; color: Theme.islandBg }
            GradientStop { position: 1.0;  color: Theme.islandBottom }
        }
        border.width: 1
        border.color: surface.active
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.38)
            : Theme.islandEdge
        Behavior on border.color { ColorAnimation { duration: 240 } }
    }

    // светлая линия по верхней кромке — стеклянный блик
    Rectangle {
        anchors {
            top: parent.top; left: parent.left; right: parent.right
            topMargin: 1
            leftMargin: surface.radius * 0.9
            rightMargin: surface.radius * 0.9
        }
        height: 1
        radius: 0.5
        color: Theme.islandShine
    }

    // акцентная «пульсация» в режиме события
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.accent
        visible: surface.pulse
        opacity: 0
        SequentialAnimation on opacity {
            running: surface.pulse
            loops: Animation.Infinite
            NumberAnimation { to: 0.40; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.08; duration: 1000; easing.type: Easing.InOutSine }
        }
    }
}
