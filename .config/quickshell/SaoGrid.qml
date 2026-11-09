import QtQuick

// Фон панелей Aincrad: тонкая голографическая сетка, гексагональные узлы
// и медленно ползущая сканирующая полоса.
Item {
    id: root

    property bool shown: Rock.sao
    property bool animated: true
    property color lineColor: Rock.a(Rock.gold, 0.06)
    property color majorColor: Rock.a(Rock.gold, 0.11)
    property color nodeColor: Rock.a(Rock.gold, 0.16)
    property real step: 26

    visible: shown
    opacity: shown ? 1 : 0

    Canvas {
        anchors.fill: parent
        opacity: 0.9
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const s = Math.max(14, root.step)

            ctx.lineWidth = 1
            ctx.strokeStyle = root.lineColor
            for (let x = 0; x <= width; x += s) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }
            for (let y = 0; y <= height; y += s) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }

            ctx.strokeStyle = root.majorColor
            const big = s * 4
            for (let x = 0; x <= width; x += big) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }
            for (let y = 0; y <= height; y += big) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }

            ctx.strokeStyle = root.nodeColor
            const hex = s * 0.9
            for (let y = big; y < height; y += big) {
                for (let x = big; x < width; x += big) {
                    ctx.beginPath()
                    for (let k = 0; k < 6; k++) {
                        const a = Math.PI / 3 * k - Math.PI / 6
                        const px = x + Math.cos(a) * hex
                        const py = y + Math.sin(a) * hex
                        if (k === 0) ctx.moveTo(px, py)
                        else ctx.lineTo(px, py)
                    }
                    ctx.closePath()
                    ctx.stroke()
                }
            }
        }
    }

    Rectangle {
        visible: root.shown && root.animated
        width: parent.width
        height: Math.max(28, parent.height * 0.18)
        y: -height
        opacity: 0.75
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.75; color: Rock.a(Rock.gold, 0.11) }
            GradientStop { position: 1.0; color: Rock.a(Rock.starlight, 0.20) }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            running: root.shown && root.animated
            NumberAnimation {
                from: -root.height
                to: root.height
                duration: 5200
                easing.type: Easing.InOutSine
            }
        }
    }
}
