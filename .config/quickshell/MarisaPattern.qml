import QtQuick

// Гравюрный фон Kirisame Marisa: диагональная штриховка и звёздная пыль.
Canvas {
    id: root

    property bool onPaper: true
    property color hatchColor: Rock.a(onPaper ? Rock.ink : Rock.cream, onPaper ? 0.055 : 0.07)
    property color dustColor: Rock.a(onPaper ? Rock.uiAccent : Rock.gold, onPaper ? 0.16 : 0.32)
    property real hatchStep: 26
    property real dustSize: 1.7

    opacity: Rock.marisa ? 1 : 0
    visible: Rock.marisa

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    function star(ctx, x, y, r) {
        ctx.beginPath()
        ctx.moveTo(x, y - r)
        ctx.lineTo(x + r * 0.22, y - r * 0.22)
        ctx.lineTo(x + r, y)
        ctx.lineTo(x + r * 0.22, y + r * 0.22)
        ctx.lineTo(x, y + r)
        ctx.lineTo(x - r * 0.22, y + r * 0.22)
        ctx.lineTo(x - r, y)
        ctx.lineTo(x - r * 0.22, y - r * 0.22)
        ctx.closePath()
        ctx.fill()
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        ctx.strokeStyle = hatchColor
        ctx.lineWidth = 1
        const step = Math.max(14, hatchStep)
        for (let x = -height; x < width; x += step) {
            ctx.beginPath()
            ctx.moveTo(x, 0)
            ctx.lineTo(x + height, height)
            ctx.stroke()
        }

        const cols = Math.max(4, Math.floor(width / 54))
        const rows = Math.max(2, Math.floor(height / 34))
        ctx.fillStyle = dustColor
        for (let j = 0; j < rows; j++) {
            for (let i = 0; i < cols; i++) {
                if ((i + j * 3) % 4 === 1) continue
                const x = (i + 0.5) * width / cols + ((i * 37 + j * 17) % 15 - 7)
                const y = (j + 0.5) * height / rows + ((i * 13 + j * 29) % 11 - 5)
                root.star(ctx, x, y, dustSize * ((i + j) % 3 === 0 ? 1.6 : 1))
            }
        }
    }
}
