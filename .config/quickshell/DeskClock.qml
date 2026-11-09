import QtQuick
import Quickshell

Item {
    id: clock

    implicitWidth: 330
    implicitHeight: 330

    readonly property color accent3: Qt.hsla((Theme.accent2.hslHue + 0.13) % 1,
        Math.max(0.5, Theme.accent2.hslSaturation),
        Theme.light ? 0.42 : 0.68, 1)

    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    Timer {
        interval: 50
        running: clock.visible
        repeat: true
        onTriggered: sec.smoothSec = sysClock.date.getSeconds() + (Date.now() % 1000) / 1000
    }

    Canvas {
        id: hud
        anchors.fill: parent

        property real cpu: SysStats.cpu
        property real mem: SysStats.mem
        property real disk: SysStats.disk
        property color accent: Rock.pink
        property color accent2: Rock.cyan
        property color accent3: clock.accent3
        property color fg: Rock.cream
        property color bgc: Theme.islandBg

        onCpuChanged: requestPaint()
        onMemChanged: requestPaint()
        onDiskChanged: requestPaint()
        onAccentChanged: requestPaint()
        onAccent2Changed: requestPaint()
        onAccent3Changed: requestPaint()
        onFgChanged: requestPaint()
        onBgcChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            const cx = w / 2, cy = h / 2
            const R = Math.min(w, h) / 2 - 4

            const g = ctx.createRadialGradient(cx, cy, R * 0.15, cx, cy, R)
            g.addColorStop(0, Qt.rgba(bgc.r, bgc.g, bgc.b, 0.78))
            g.addColorStop(0.70, Qt.rgba(bgc.r, bgc.g, bgc.b, 0.58))
            g.addColorStop(1, Qt.rgba(bgc.r, bgc.g, bgc.b, 0.0))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(cx, cy, R, 0, Math.PI * 2)
            ctx.fill()

            ctx.save()
            ctx.translate(cx, cy)
            for (let i = 0; i < 60; i++) {
                const a = i * Math.PI / 30 - Math.PI / 2
                const major = i % 5 === 0
                const r1 = R - (major ? 11 : 6)
                const r2 = R - 1
                ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, major ? 0.42 : 0.16)
                ctx.lineWidth = major ? 1.6 : 1
                ctx.beginPath()
                ctx.moveTo(Math.cos(a) * r1, Math.sin(a) * r1)
                ctx.lineTo(Math.cos(a) * r2, Math.sin(a) * r2)
                ctx.stroke()
            }
            ctx.restore()

            const gauges = [
                { v: cpu, r: R - 34, c: accent, w: 6 },
                { v: mem, r: R - 47, c: accent2, w: 6 },
                { v: disk, r: R - 60, c: accent3, w: 6 }
            ]
            for (let k = 0; k < gauges.length; k++) {
                const G = gauges[k]
                ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.10)
                ctx.lineWidth = G.w
                ctx.beginPath()
                ctx.arc(cx, cy, G.r, 0, Math.PI * 2)
                ctx.stroke()
                const ratio = Math.max(0, Math.min(1, G.v / 100))
                ctx.strokeStyle = G.c
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.arc(cx, cy, G.r, -Math.PI / 2, -Math.PI / 2 + ratio * Math.PI * 2)
                ctx.stroke()
                const ea = -Math.PI / 2 + ratio * Math.PI * 2
                ctx.fillStyle = G.c
                ctx.beginPath()
                ctx.arc(cx + Math.cos(ea) * G.r, cy + Math.sin(ea) * G.r, G.w * 0.7, 0, Math.PI * 2)
                ctx.fill()
            }

            ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.10)
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.arc(cx, cy, R - 72, 0, Math.PI * 2)
            ctx.stroke()
        }
    }

    Canvas {
        id: sec
        anchors.fill: parent

        property real smoothSec: 0
        property color accent: Rock.pink
        property color fg: Rock.cream

        onSmoothSecChanged: requestPaint()
        onAccentChanged: requestPaint()
        onFgChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            const cx = w / 2, cy = h / 2
            const R = Math.min(w, h) / 2 - 4
            const r = R - 16
            const ratio = (smoothSec % 60) / 60
            const a0 = -Math.PI / 2
            const a1 = a0 + ratio * Math.PI * 2

            ctx.strokeStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.10)
            ctx.lineWidth = 2.5
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            ctx.strokeStyle = accent
            ctx.lineWidth = 2.5
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(cx, cy, r, a0, a1)
            ctx.stroke()

            for (let i = 0; i < 16; i++) {
                const t = ratio - i * 0.006
                if (t < 0) continue
                const aa = a0 + t * Math.PI * 2
                ctx.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.5 * (1 - i / 16))
                ctx.beginPath()
                ctx.arc(cx + Math.cos(aa) * r, cy + Math.sin(aa) * r, 2.2 - i * 0.08, 0, Math.PI * 2)
                ctx.fill()
            }

            ctx.fillStyle = accent
            ctx.beginPath()
            ctx.arc(cx + Math.cos(a1) * r, cy + Math.sin(a1) * r, 3.4, 0, Math.PI * 2)
            ctx.fill()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 1

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Rectangle { width: 16; height: 1; color: Rock.a(Rock.cream, 0.22); y: 5 }

            Lbl {
                text: Qt.locale(PanelConfig.english ? "en_US" : "ru_RU")
                          .toString(sysClock.date, "ddd · d MMM").toUpperCase()
                color: Rock.a(Rock.cream, 0.55)
                font.family: Rock.display
                font.pixelSize: 8
                font.weight: Font.Black
                font.letterSpacing: 1.3
            }

            Rectangle { width: 16; height: 1; color: Rock.a(Rock.cream, 0.22); y: 5 }
        }

        Lbl {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(sysClock.date, "HH:mm")
            color: Rock.cream
            font.family: Rock.mono
            font.weight: Font.Black
            font.pixelSize: 52
            font.letterSpacing: -3
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Rectangle { width: 5; height: 5; radius: 2.5; color: Rock.pink; y: 5 }

            Lbl {
                text: Qt.formatDateTime(sysClock.date, "ss") + " SEC"
                color: Rock.a(Rock.cream, 0.45)
                font.family: Rock.mono
                font.pixelSize: 8
                font.letterSpacing: 1.2
            }
        }

        Item { width: 1; height: 6 }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 9

            Repeater {
                model: [
                    { label: "CPU", value: SysStats.cpu, color: Rock.pink },
                    { label: "RAM", value: SysStats.mem, color: Rock.cyan },
                    { label: "DISK", value: SysStats.disk, color: clock.accent3 }
                ]
                delegate: Row {
                    required property var modelData
                    spacing: 3

                    Rectangle {
                        width: 4; height: 4; radius: 2
                        color: modelData.color
                        y: 4
                    }

                    Lbl {
                        text: modelData.label + " " + modelData.value + "%"
                        color: Rock.a(Rock.cream, 0.5)
                        font.family: Rock.mono
                        font.pixelSize: 8
                    }
                }
            }
        }

        Item { width: 1; height: 4 }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Lbl {
                text: "\uf017 " + SysStats.uptimeText
                color: Rock.a(Rock.cream, 0.35)
                font.pixelSize: 8
            }

            Lbl {
                visible: SysStats.temp > 0
                text: (SysStats.temp >= 78 ? "\uf76b " : "\uf768 ") + SysStats.temp + "°C"
                color: SysStats.temp >= 78 ? Rock.yellow : Rock.a(Rock.cream, 0.35)
                font.pixelSize: 8
            }
        }
    }
}
