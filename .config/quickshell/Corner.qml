import QtQuick
import Quickshell
import Quickshell.Wayland

// Один «внутренний» угол экрана. corner: 0=лев-верх, 1=пр-верх, 2=лев-низ, 3=пр-низ
PanelWindow {
    id: win

    property int corner: 0
    property int size: 20

    anchors {
        top: corner < 2
        bottom: corner >= 2
        left: corner % 2 === 0
        right: corner % 2 === 1
    }
    implicitWidth: size
    implicitHeight: size
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-corner"
    color: "transparent"
    mask: Region {}                       // клики проходят сквозь

    Canvas {
        anchors.fill: parent
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const s = win.size
            ctx.fillStyle = "#000000"
            ctx.fillRect(0, 0, s, s)
            // вырезаем четверть круга
            const cx = (win.corner % 2 === 0) ? s : 0
            const cy = (win.corner < 2) ? s : 0
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(cx, cy, s, 0, Math.PI * 2)
            ctx.fill()
        }
    }
}
