import QtQuick

// Гравюрная рамка гримуара: двойной контур, звёзды в углах и руны по центру.
// Рисуется поверх поверхности и не перехватывает клики.
Item {
    id: root

    property bool shown: Rock.marisa
    property real inset: 5
    property real frameRadius: Math.max(2, Rock.uiRadiusSm - 2)
    property bool onPaper: true
    property color lineColor: Rock.a(onPaper ? Rock.ink : Rock.cream, onPaper ? 0.26 : 0.34)
    property color accentColor: onPaper ? Rock.uiAccent : Rock.gold
    property bool cornerStars: true
    property bool runes: true

    visible: shown

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.inset
        radius: root.frameRadius
        color: "transparent"
        border.width: 1
        border.color: root.lineColor
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.inset + 3
        radius: Math.max(1, root.frameRadius - 2)
        color: "transparent"
        border.width: 1
        border.color: Rock.a(root.accentColor, 0.22)
    }

    Repeater {
        model: root.cornerStars ? 4 : 0
        delegate: Text {
            required property int index
            readonly property bool atLeft: index === 0 || index === 3
            readonly property bool atTop: index < 2
            text: index % 2 === 0 ? "✦" : "✧"
            color: index % 2 === 0 ? root.accentColor : Rock.a(root.accentColor, 0.72)
            font.pixelSize: index % 2 === 0 ? 11 : 8
            x: atLeft ? root.inset - 1 : parent.width - width - root.inset + 1
            y: atTop ? root.inset - height * 0.55
                 : parent.height - height - root.inset + height * 0.35
        }
    }

    Text {
        visible: root.runes
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.inset - 6
        text: "◆"
        color: root.accentColor
        font.pixelSize: 7
        opacity: 0.9
    }

    Text {
        visible: root.runes
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.inset - 6
        text: "✦"
        color: Rock.a(root.accentColor, 0.8)
        font.pixelSize: 8
        opacity: 0.9
    }
}
