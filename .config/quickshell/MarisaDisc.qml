import QtQuick

// Вращающийся магический диск для плеера в стиле Марисы:
// гравированные кольца, руны-звёзды и круглая обложка в центре.
Item {
    id: root

    property bool shown: Rock.marisa
    property bool playing: false
    property string artSource: ""
    property real discSize: 92
    property color ringColor: Rock.gold
    property color detailColor: Rock.a(Rock.ink, 0.42)

    implicitWidth: discSize
    implicitHeight: discSize
    visible: shown

    Item {
        id: spinner
        anchors.fill: parent

        NumberAnimation on rotation {
            running: root.visible && root.playing
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
        }

        Canvas {
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const cx = width / 2, cy = height / 2
                const r1 = Math.min(width, height) / 2 - 1

                ctx.strokeStyle = Rock.a(root.ringColor, 0.72)
                ctx.lineWidth = 1
                for (const f of [1.0, 0.86, 0.7]) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, r1 * f, 0, Math.PI * 2)
                    ctx.stroke()
                }

                ctx.strokeStyle = root.detailColor
                for (let i = 0; i < 24; i++) {
                    const a = i * Math.PI * 2 / 24
                    const r2 = r1 * (i % 3 === 0 ? 0.78 : 0.83)
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                    ctx.lineTo(cx + Math.cos(a) * r1 * 0.94, cy + Math.sin(a) * r1 * 0.94)
                    ctx.stroke()
                }
            }
        }

        Repeater {
            model: 8
            delegate: Text {
                required property int index
                readonly property real ang: index * Math.PI * 2 / 8 - Math.PI / 2
                text: index % 2 === 0 ? "✦" : "✧"
                color: index % 2 === 0 ? root.ringColor : root.detailColor
                font.pixelSize: index % 2 === 0 ? 8 : 6
                x: root.width / 2 + Math.cos(ang) * (root.width * 0.42) - width / 2
                y: root.height / 2 + Math.sin(ang) * (root.height * 0.42) - height / 2
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.width * 0.66
        height: root.height * 0.66

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Rock.uiSurface2
            border.width: 2
            border.color: Rock.a(Rock.gold, 0.7)
        }

        Image {
            id: art
            anchors.fill: parent
            anchors.margins: 2
            source: root.artSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        Lbl {
            anchors.centerIn: parent
            visible: !art.visible
            text: "\uf001"
            color: root.detailColor
            font.pixelSize: root.width * 0.2
        }

        RoundMask {
            anchors.fill: parent
            radius: width / 2
            maskColor: Rock.uiSurface
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Rock.a(Rock.gold, 0.7)
        }

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: Rock.gold
            border.width: 1
            border.color: root.detailColor
        }
    }
}
