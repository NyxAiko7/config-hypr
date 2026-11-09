import QtQuick

Item {
    id: btn

    property string icon: ""
    property bool big: false
    property bool available: true
    property bool active: false
    property color accent: Rock.pink
    signal activated()

    implicitWidth: big ? 48 : 34
    implicitHeight: implicitWidth

    Rectangle {
        id: halo
        anchors.centerIn: parent
        width: parent.width + (btn.big ? 12 : 8)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Rock.a(btn.accent, btn.big && btn.active ? 0.5 : 0.32)
        opacity: ((btn.big && btn.active) || area.containsMouse) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: width / 2
        opacity: btn.available ? 1 : 0.35
        color: btn.big
            ? (area.containsMouse ? Qt.lighter(btn.accent, 1.08) : btn.accent)
            : (area.containsMouse ? Rock.a(Rock.cream, 0.16) : Rock.a(Rock.cream, 0.06))
        border.width: 1
        border.color: btn.big ? Rock.a(Rock.cream, 0.18) : Rock.a(Rock.cream, 0.10)
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: btn.big ? 4 : 3
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Rock.a(btn.big ? Rock.ink : Rock.cream, btn.big ? 0.10 : 0.05)
        }
    }

    Lbl {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.big ? Rock.ink : Rock.cream
        font.pixelSize: btn.big ? 18 : 13
        scale: area.pressed ? 0.85 : 1
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: btn.available
        hoverEnabled: true
        cursorShape: btn.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: btn.activated()
    }
}
