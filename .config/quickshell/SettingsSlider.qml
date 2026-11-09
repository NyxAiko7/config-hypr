import QtQuick

// Простой ползунок без QtQuick.Controls.
Item {
    id: root

    property int from: 0
    property int to: 100
    property int value: 50
    property int step: 1
    signal moved(int v)

    implicitWidth: 190
    implicitHeight: 30

    readonly property real frac: Math.max(0, Math.min(1,
        (value - from) / Math.max(1, to - from)))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Rock.a(Rock.uiText, 0.12)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * root.frac
        height: 6
        radius: 3
        color: Rock.uiAccent
    }

    Rectangle {
        x: (parent.width - width) * root.frac
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        radius: 9
        color: Rock.uiAccent
        border.width: 2
        border.color: Rock.uiSurface
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function apply(px) {
            const r = Math.max(0, Math.min(1, px / width))
            let v = root.from + Math.round((root.to - root.from) * r)
            if (root.step > 1) v = Math.round(v / root.step) * root.step
            root.moved(v)
        }

        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) apply(mouse.x) }
        onClicked: mouse => apply(mouse.x)
    }
}
