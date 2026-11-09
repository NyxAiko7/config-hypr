import QtQuick

// Чёрно-белая шашечка с фартука Марисы — тонкая кромка поверхностей.
Canvas {
    id: root

    property int cell: 4
    property color light: Rock.marisa ? Rock.uiSurface : Rock.cream
    property color dark: Rock.ink
    property bool vertical: false

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const size = Math.max(2, cell)
        if (vertical) {
            for (let y = 0; y < height; y += size) {
                ctx.fillStyle = (Math.floor(y / size) % 2 === 0) ? dark : light
                ctx.fillRect(0, y, width, Math.min(size, height - y))
            }
        } else {
            for (let x = 0; x < width; x += size) {
                ctx.fillStyle = (Math.floor(x / size) % 2 === 0) ? dark : light
                ctx.fillRect(x, 0, Math.min(size, width - x), height)
            }
        }
    }
}
