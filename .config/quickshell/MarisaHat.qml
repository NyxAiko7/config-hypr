import QtQuick

// Ведьминская шляпа — силуэт-метка гримуара Марисы.
Canvas {
    id: root

    property real hatWidth: 22
    property real hatHeight: 20
    property color inkColor: "#241a24"
    property color bandColor: Rock.pink
    property color starColor: Rock.gold

    implicitWidth: hatWidth
    implicitHeight: hatHeight

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const cx = w / 2

        ctx.fillStyle = root.inkColor
        ctx.beginPath()
        ctx.moveTo(cx - w * 0.34, h * 0.74)
        ctx.lineTo(cx + w * 0.34, h * 0.74)
        ctx.lineTo(cx + w * 0.10, h * 0.10)
        ctx.quadraticCurveTo(cx + w * 0.02, h * 0.02, cx - w * 0.08, h * 0.14)
        ctx.closePath()
        ctx.fill()

        ctx.fillStyle = root.bandColor
        ctx.fillRect(cx - w * 0.27, h * 0.60, w * 0.54, h * 0.11)

        ctx.fillStyle = root.inkColor
        ctx.save()
        ctx.translate(cx, h * 0.78)
        ctx.scale(1, 0.22)
        ctx.beginPath()
        ctx.arc(0, 0, w * 0.5, 0, Math.PI * 2)
        ctx.fill()
        ctx.restore()

        ctx.fillStyle = root.starColor
        ctx.beginPath()
        const sx = cx + w * 0.02, sy = h * 0.46, r = h * 0.11
        for (let i = 0; i < 8; i++) {
            const a = i * Math.PI / 4 - Math.PI / 2
            const rr = i % 2 === 0 ? r : r * 0.32
            const px = sx + Math.cos(a) * rr
            const py = sy + Math.sin(a) * rr
            if (i === 0) ctx.moveTo(px, py)
            else ctx.lineTo(px, py)
        }
        ctx.closePath()
        ctx.fill()
    }
}
