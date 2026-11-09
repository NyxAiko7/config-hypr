import QtQuick

// Угловатая HUD-рамка Aincrad: срезанные углы, двойной контур,
// угловые скобки и сегментная шкала по верхней кромке.
// Рисуется поверх поверхности и не перехватывает клики.
Canvas {
    id: root

    property bool shown: Rock.sao
    property real inset: 4
    property real cut: 9
    property real corner: 16
    property bool brackets: true
    property bool ticks: true
    property int segments: 22
    property color lineColor: Rock.a(Rock.gold, 0.34)
    property color accentColor: Rock.gold

    visible: shown
    opacity: shown ? 1 : 0
    antialiasing: true

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onInsetChanged: requestPaint()
    onCutChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onAccentColorChanged: requestPaint()
    Component.onCompleted: requestPaint()

    function chamferPath(ctx, x, y, w, h, c) {
        ctx.beginPath()
        ctx.moveTo(x + c, y)
        ctx.lineTo(x + w - c, y)
        ctx.lineTo(x + w, y + c)
        ctx.lineTo(x + w, y + h - c)
        ctx.lineTo(x + w - c, y + h)
        ctx.lineTo(x + c, y + h)
        ctx.lineTo(x, y + h - c)
        ctx.lineTo(x, y + c)
        ctx.closePath()
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const i = Math.max(0, inset)
        const w = width - i * 2
        const h = height - i * 2
        if (w <= 8 || h <= 8) return
        const c = Math.max(2, Math.min(cut, Math.min(w, h) * 0.24))

        ctx.lineWidth = 1
        ctx.strokeStyle = lineColor
        chamferPath(ctx, i, i, w, h, c)
        ctx.stroke()

        ctx.strokeStyle = Rock.a(accentColor, 0.20)
        chamferPath(ctx, i + 4, i + 4, w - 8, h - 8, Math.max(2, c - 2))
        ctx.stroke()

        if (brackets) {
            const k = Math.max(6, Math.min(corner, Math.min(w, h) * 0.35))
            ctx.strokeStyle = accentColor
            ctx.lineWidth = 1.6
            const p = i + 1
            const pts = [
                [p, p, p + k, p], [p, p, p, p + k],
                [width - p, p, width - p - k, p], [width - p, p, width - p, p + k],
                [p, height - p, p + k, height - p], [p, height - p, p, height - p - k],
                [width - p, height - p, width - p - k, height - p],
                [width - p, height - p, width - p, height - p - k]
            ]
            for (const s of pts) {
                ctx.beginPath()
                ctx.moveTo(s[0], s[1])
                ctx.lineTo(s[2], s[3])
                ctx.stroke()
            }
        }

        if (ticks && w > 80) {
            const n = Math.max(6, segments)
            const span = w * 0.5
            const x0 = i + (w - span) / 2
            const step = span / n
            ctx.lineWidth = 1
            for (let s = 0; s < n; s++) {
                const isLong = s % 4 === 0
                ctx.strokeStyle = Rock.a(accentColor, isLong ? 0.6 : 0.24)
                const x = x0 + s * step
                ctx.beginPath()
                ctx.moveTo(x, i + 2)
                ctx.lineTo(x, i + (isLong ? 9 : 6))
                ctx.stroke()
            }

            // ромб по центру верхней кромки
            const cx = i + w / 2
            ctx.fillStyle = accentColor
            ctx.beginPath()
            ctx.moveTo(cx, i + 4)
            ctx.lineTo(cx + 3, i + 8)
            ctx.lineTo(cx, i + 12)
            ctx.lineTo(cx - 3, i + 8)
            ctx.closePath()
            ctx.fill()
        }
    }
}
