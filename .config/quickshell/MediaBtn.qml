import QtQuick

// Кнопка управления плеером (MediaCard). Вынесена из inline-компонента,
// т.к. в QuickShare/QML inline-компоненты нестабильно разрешаются при загрузке.
Rectangle {
    id: cb
    property string icon: ""
    property bool big: false
    property bool on: false
    property string badge: ""
    property color accentColor: Rock.pink
    property string tip: ""
    signal activated()
    implicitWidth: big ? 42 : 30
    implicitHeight: implicitWidth
    radius: width / 2
    color: big ? (cArea.containsMouse ? Qt.lighter(accentColor, 1.08) : accentColor)
               : (cArea.containsMouse ? Rock.a(Rock.pink, 0.16) : "transparent")
    border.width: big ? 2 : 0
    border.color: Rock.ink
    Behavior on color { ColorAnimation { duration: 120 } }
    Lbl {
        anchors.centerIn: parent
        text: cb.icon
        color: cb.big ? Rock.ink : (cb.on ? cb.accentColor : Rock.ink)
        font.pixelSize: cb.big ? 15 : 12
        opacity: (!cb.big && !cb.on) ? 0.85 : 1
        scale: cArea.pressed ? 0.85 : 1
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }
    }
    Lbl {
        visible: cb.badge !== ""
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 4
        anchors.topMargin: 1
        text: cb.badge
        color: cb.accentColor
        font.pixelSize: 8
        font.bold: true
    }
    MouseArea {
        id: cArea
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cb.activated()
    }
}
