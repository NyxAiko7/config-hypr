import QtQuick

// Живой «погодный шар»: состояние неба рисуется и анимируется прямо на Canvas.
// Ноль внешних ресурсов — только палитра оболочки.
Item {
    id: root

    property int code: 0
    property bool isDay: true
    property bool active: true
    property real speed: 1.0

    property color accent: Rock.pink
    property color accent2: Rock.cyan
    property color ink: Rock.ink
    property color cloudColor: Rock.cream

    property real phase: 0

    readonly property int kind: {
        const c = Number(code)
        if (c === 0) return 0
        if (c === 1 || c === 2) return 1
        if (c === 3) return 2
        if (c === 45 || c === 48) return 5
        if (c === 56 || c === 57 || c === 66 || c === 67) return 3
        if (c >= 51 && c <= 55) return 3
        if (c >= 61 && c <= 65) return 3
        if (c >= 71 && c <= 77) return 4
        if (c >= 80 && c <= 82) return 3
        if (c === 85 || c === 86) return 4
        if (c >= 95) return 6
        return 2
    }

    readonly property bool night: !isDay

    Timer {
        interval: 33
        repeat: true
        running: root.active && root.visible
        onTriggered: {
            root.phase += 0.045 * root.speed
            canvas.requestPaint()
        }
    }

    function css(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
                + Math.round(c.b * 255) + "," + a + ")"
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            if (w <= 0 || h <= 0) return

            const cx = w / 2, cy = h / 2
            const R = Math.min(w, h) / 2 - 2
            const t = root.phase
            const A = root.accent, B = root.accent2, C = root.cloudColor, INK = root.ink
            const kind = root.kind
            const night = root.night
            const TAU = Math.PI * 2

            function css(c, a) {
                return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
                        + Math.round(c.b * 255) + "," + a + ")"
            }

            // атмосферное свечение
            const bg = ctx.createRadialGradient(cx, cy, R * 0.10, cx, cy, R)
            bg.addColorStop(0, css(A, 0.26))
            bg.addColorStop(0.55, css(B, 0.08))
            bg.addColorStop(1, css(A, 0.0))
            ctx.fillStyle = bg
            ctx.beginPath()
            ctx.arc(cx, cy, R, 0, TAU)
            ctx.fill()

            // тонкое внутреннее кольцо
            ctx.strokeStyle = css(INK, 0.10)
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.arc(cx, cy, R * 0.94, 0, TAU)
            ctx.stroke()

            function puffs(x, y, s, col, alpha) {
                ctx.fillStyle = css(col, alpha)
                ctx.beginPath()
                ctx.arc(x - s * 0.62, y + s * 0.18, s * 0.40, 0, TAU)
                ctx.arc(x - s * 0.18, y - s * 0.16, s * 0.55, 0, TAU)
                ctx.arc(x + s * 0.40, y + s * 0.06, s * 0.42, 0, TAU)
                ctx.arc(x + s * 0.02, y + s * 0.28, s * 0.40, 0, TAU)
                ctx.fill()
            }

            function sun(x, y, r) {
                ctx.strokeStyle = css(B, 0.9)
                ctx.lineWidth = Math.max(1.5, r * 0.11)
                ctx.lineCap = "round"
                for (let i = 0; i < 12; i++) {
                    const a = t * 0.5 + i * Math.PI / 6
                    const r0 = r * 1.45, r1 = r * 1.82
                    ctx.beginPath()
                    ctx.moveTo(x + Math.cos(a) * r0, y + Math.sin(a) * r0)
                    ctx.lineTo(x + Math.cos(a) * r1, y + Math.sin(a) * r1)
                    ctx.stroke()
                }
                const g = ctx.createRadialGradient(x - r * 0.35, y - r * 0.35, r * 0.08, x, y, r)
                g.addColorStop(0, css(B, 1))
                g.addColorStop(0.55, css(A, 0.98))
                g.addColorStop(1, css(A, 0.9))
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(x, y, r, 0, TAU)
                ctx.fill()
            }

            function moon(x, y, r) {
                for (let i = 0; i < 9; i++) {
                    const sx = cx + Math.cos(i * 2.31 + 0.5) * R * (0.45 + (i % 3) * 0.12)
                    const sy = cy + Math.sin(i * 1.73 + 0.9) * R * (0.42 + (i % 2) * 0.13)
                    const tw = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(t * 2.2 + i * 1.3))
                    ctx.fillStyle = css(B, 0.85 * tw)
                    ctx.beginPath()
                    ctx.arc(sx, sy, Math.max(0.9, R * 0.016 * (0.5 + tw)), 0, TAU)
                    ctx.fill()
                }
                ctx.save()
                ctx.fillStyle = css(B, 0.97)
                ctx.beginPath()
                ctx.arc(x, y, r, 0, TAU)
                ctx.fill()
                ctx.globalCompositeOperation = "destination-out"
                ctx.beginPath()
                ctx.arc(x + r * 0.52, y - r * 0.28, r * 0.94, 0, TAU)
                ctx.fill()
                ctx.restore()
            }

            function rain(x, y, spread, count, col) {
                ctx.strokeStyle = css(col, 0.9)
                ctx.lineWidth = Math.max(1.1, R * 0.022)
                ctx.lineCap = "round"
                for (let i = 0; i < count; i++) {
                    const off = (t * 2.4 + i * 0.37) % 1
                    const bx = x - spread / 2 + (count > 1 ? (i / (count - 1)) * spread : 0)
                    const y0 = y + off * R * 0.5
                    ctx.globalAlpha = 0.9 - off * 0.7
                    ctx.beginPath()
                    ctx.moveTo(bx, y0)
                    ctx.lineTo(bx - R * 0.035, y0 + R * 0.12)
                    ctx.stroke()
                }
                ctx.globalAlpha = 1
            }

            function snow(x, y, spread, count) {
                for (let i = 0; i < count; i++) {
                    const off = (t * 0.55 + i * 0.21) % 1
                    const bx = x - spread / 2 + (i % 5) * (spread / 5) + Math.sin(t * 1.4 + i) * R * 0.03
                    const y0 = y + off * R * 0.55
                    ctx.fillStyle = css(C, 0.9 - off * 0.6)
                    ctx.beginPath()
                    ctx.arc(bx, y0, R * 0.026, 0, TAU)
                    ctx.fill()
                }
            }

            if (kind === 0) {
                if (night) moon(cx, cy, R * 0.30)
                else sun(cx, cy, R * 0.30)
            } else if (kind === 1) {
                if (night) {
                    moon(cx + R * 0.18, cy - R * 0.16, R * 0.22)
                    puffs(cx - R * 0.10, cy + R * 0.18, R * 0.46, C, 0.58)
                } else {
                    sun(cx + R * 0.20, cy - R * 0.18, R * 0.24)
                    puffs(cx - R * 0.10, cy + R * 0.18, R * 0.46, C, 0.62)
                }
            } else if (kind === 2) {
                const d = Math.sin(t * 0.8) * R * 0.05
                puffs(cx - R * 0.16 - d, cy - R * 0.12, R * 0.38, C, 0.45)
                puffs(cx + d, cy + R * 0.06, R * 0.52, C, 0.92)
            } else if (kind === 3) {
                puffs(cx, cy - R * 0.18, R * 0.50, C, 0.95)
                rain(cx, cy - R * 0.02, R * 0.85, 7, B)
            } else if (kind === 4) {
                puffs(cx, cy - R * 0.18, R * 0.50, C, 0.95)
                snow(cx, cy - R * 0.02, R * 0.85, 10)
            } else if (kind === 5) {
                ctx.strokeStyle = css(C, 0.5)
                ctx.lineWidth = Math.max(2, R * 0.06)
                ctx.lineCap = "round"
                for (let i = 0; i < 4; i++) {
                    const y = cy - R * 0.24 + i * R * 0.16
                    const off = Math.sin(t * 0.7 + i) * R * 0.10
                    ctx.beginPath()
                    ctx.moveTo(cx - R * 0.46 + off, y)
                    ctx.lineTo(cx + R * 0.46 + off, y)
                    ctx.stroke()
                }
            } else if (kind === 6) {
                puffs(cx, cy - R * 0.22, R * 0.50, C, 0.88)
                const flick = 0.45 + 0.55 * Math.abs(Math.sin(t * 1.9))
                ctx.strokeStyle = css(A, flick)
                ctx.lineWidth = Math.max(2, R * 0.045)
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.moveTo(cx + R * 0.06, cy + R * 0.06)
                ctx.lineTo(cx - R * 0.10, cy + R * 0.34)
                ctx.lineTo(cx + R * 0.05, cy + R * 0.32)
                ctx.lineTo(cx - R * 0.12, cy + R * 0.64)
                ctx.stroke()
                rain(cx, cy + R * 0.05, R * 0.80, 5, B)
            }
        }
    }
}
