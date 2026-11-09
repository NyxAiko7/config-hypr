import QtQuick

// Луна и звёздная пыль гримуара для экрана блокировки.
Item {
    id: root

    property bool shown: Rock.marisa
    property bool onPaper: false
    property real moonSize: 280
    property color moonColor: onPaper ? Rock.ink : Rock.cream

    width: moonSize
    height: moonSize
    visible: shown
    opacity: 0.85

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2
            const r = Math.min(width, height) * 0.32
            const g = ctx.createRadialGradient(cx, cy, r * 0.2, cx, cy, r * 2.1)
            g.addColorStop(0, Rock.a(Rock.gold, 0.30))
            g.addColorStop(0.55, Rock.a(Rock.gold, 0.10))
            g.addColorStop(1, Rock.a(Rock.gold, 0))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(cx, cy, r * 2.1, 0, Math.PI * 2)
            ctx.fill()
        }
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
            const r = Math.min(width, height) * 0.32

            ctx.fillStyle = Rock.a(root.moonColor, 0.9)
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fill()

            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(cx + r * 0.46, cy - r * 0.28, r * 0.94, 0, Math.PI * 2)
            ctx.fill()

            ctx.globalCompositeOperation = "source-over"
            ctx.fillStyle = Rock.a(root.onPaper ? Rock.gold : Rock.cream, 0.55)
            for (let i = 0; i < 5; i++) {
                const a = i * Math.PI * 2 / 5 - Math.PI / 2
                ctx.beginPath()
                ctx.arc(cx - r * 0.18 + Math.cos(a) * r * 0.5,
                        cy + r * 0.2 + Math.sin(a) * r * 0.5,
                        Math.max(1, r * 0.03), 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    Repeater {
        model: 7
        delegate: Text {
            required property int index
            readonly property real ang: index * Math.PI * 2 / 7 + 0.35
            readonly property real rad: root.moonSize * (0.4 + (index % 3) * 0.07)
            text: index % 2 === 0 ? "✦" : "✧"
            color: root.onPaper
                ? (index % 2 === 0 ? Rock.pinkDeep : Rock.a(Rock.ink, 0.65))
                : (index % 2 === 0 ? Rock.gold : Rock.a(Rock.cream, 0.7))
            font.pixelSize: index % 2 === 0 ? 10 : 7
            x: root.width / 2 + Math.cos(ang) * rad - width / 2
            y: root.height / 2 + Math.sin(ang) * rad - height / 2
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation { to: 0.25; duration: 900 + index * 130 }
                NumberAnimation { to: 1.0;  duration: 1100 + index * 160 }
            }
        }
    }
}
