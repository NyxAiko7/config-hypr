import QtQuick

Rectangle {
    id: btn
    property string icon
    property color iconColor: Theme.muted
    property int size: 32
    property bool spin: false
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: area.containsMouse ? Theme.surface : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Lbl {
        id: ic
        anchors.centerIn: parent
        text: btn.icon
        color: btn.iconColor
        font.pixelSize: 13
        NumberAnimation on rotation {
            running: btn.spin
            from: 0; to: 360
            loops: Animation.Infinite
            duration: 900
            onRunningChanged: if (!running) ic.rotation = 0
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
