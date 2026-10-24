import QtQuick

// Кладётся поверх картинки: закрашивает углы цветом фона и получается скругление
Canvas {
    id: c
    property real radius: 14
    property color maskColor: "black"

    onMaskColorChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const r = Math.min(radius, w / 2, h / 2)
        ctx.fillStyle = maskColor
        ctx.fillRect(0, 0, w, h)
        ctx.globalCompositeOperation = "destination-out"
        ctx.beginPath()
        ctx.moveTo(r, 0)
        ctx.lineTo(w - r, 0);  ctx.arcTo(w, 0, w, r, r)
        ctx.lineTo(w, h - r);  ctx.arcTo(w, h, w - r, h, r)
        ctx.lineTo(r, h);      ctx.arcTo(0, h, 0, h - r, r)
        ctx.lineTo(0, r);      ctx.arcTo(0, 0, r, 0, r)
        ctx.closePath()
        ctx.fill()
    }
}
