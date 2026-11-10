import QtQuick
import QtQuick.Effects

// «Обсерватория»: глубокий космос, размытые обои, пульсирующее затмение,
// орбитальные кольца и редкие метеоры.
Item {
    id: bg

    property string wallpaper: ""
    property real enterProgress: 0
    property bool flash: false

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.light ? "#dfe7f2" : "#05070d" }
            GradientStop { position: 0.45; color: Theme.light ? "#c9d8eb" : "#091223" }
            GradientStop { position: 1.0; color: Theme.light ? "#b7c8de" : "#03050a" }
        }
    }

    Image {
        id: wall
        anchors.fill: parent
        source: bg.wallpaper !== "" ? "file://" + bg.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 1920
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 0.85
        blurMax: 96
        brightness: Theme.light ? -0.18 : -0.58
        saturation: -0.35
        contrast: 0.08
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.light ? "#10ffffff" : "#5002060f"
    }

    // туманность вокруг центра
    Canvas {
        width: Math.min(parent.width, parent.height) * 1.1
        height: width
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -height * 0.05
        opacity: Theme.light ? 0.7 : 1.0
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2
            const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, width / 2)
            g.addColorStop(0, Rock.a(Theme.accent, Theme.light ? 0.16 : 0.22))
            g.addColorStop(0.45, Rock.a(Theme.accent2, Theme.light ? 0.08 : 0.12))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
        }
        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: true
            NumberAnimation { from: 0.96; to: 1.06; duration: 5200; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.06; to: 0.96; duration: 5200; easing.type: Easing.InOutSine }
        }
    }

    // затмение за панелью авторизации
    Item {
        id: eclipse
        width: Math.min(bg.width, bg.height) * 0.62
        height: width
        x: bg.width * 0.58 - width / 2
        y: bg.height * 0.46 - height / 2
        opacity: 0.35 + bg.enterProgress * 0.65

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.72
            height: width
            radius: width / 2
            color: Rock.a(Theme.accent, Theme.light ? 0.10 : 0.18)
            scale: 1.0
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: true
                NumberAnimation { from: 0.97; to: 1.05; duration: 3400; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.05; to: 0.97; duration: 3400; easing.type: Easing.InOutSine }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.54
            height: width
            radius: width / 2
            color: Rock.a(Theme.bg, Theme.light ? 0.55 : 0.82)
            border.width: 1
            border.color: Rock.a(Theme.accent2, 0.35)
        }

        Repeater {
            model: 3
            delegate: Canvas {
                required property int index
                anchors.centerIn: parent
                width: eclipse.width * (0.66 + index * 0.16)
                height: width
                opacity: 0.55 - index * 0.12
                antialiasing: true
                property real sweep: index === 1 ? 210 : 140
                property real startA: index * 70
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2, cy = height / 2, r = width / 2 - 2
                    ctx.lineCap = "round"
                    ctx.lineWidth = index === 1 ? 2 : 1.5
                    ctx.strokeStyle = Rock.a(index % 2 === 0 ? Theme.accent : Theme.accent2, 0.9)
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2 * (sweep / 360))
                    ctx.stroke()
                    if (index !== 1) {
                        ctx.fillStyle = Rock.a(Theme.text, 0.5)
                        const a = Math.PI * 2 * (sweep / 360)
                        ctx.beginPath()
                        ctx.arc(cx + Math.cos(a) * r, cy + Math.sin(a) * r, 2.5, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
                NumberAnimation on rotation {
                    loops: Animation.Infinite
                    running: true
                    from: startA
                    to: startA + (index % 2 === 0 ? 360 : -360)
                    duration: 24000 + index * 9000
                }
            }
        }
    }

    // звёздное поле
    Canvas {
        id: stars
        anchors.fill: parent
        opacity: Theme.light ? 0.22 : 0.55
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const n = 120
            for (let i = 0; i < n; i++) {
                const x = ((i * 928371) % 10000) / 10000 * width
                const y = ((i * 193877) % 10000) / 10000 * height
                const s = 0.6 + ((i * 77) % 17) / 10
                const a = 0.18 + ((i * 37) % 50) / 100
                ctx.fillStyle = Rock.a(i % 7 === 0 ? Theme.accent2 : Theme.text, a)
                ctx.beginPath()
                ctx.arc(x, y, s, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    // мерцающие звёзды
    Repeater {
        model: 22
        delegate: Rectangle {
            required property int index
            width: 1.5 + (index % 3)
            height: width
            radius: width / 2
            x: ((index * 733) % 1000) / 1000 * bg.width
            y: ((index * 419) % 1000) / 1000 * bg.height
            color: index % 3 === 0 ? Theme.accent2 : Theme.text
            opacity: 0.2
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true
                PauseAnimation { duration: (index * 311) % 3200 }
                NumberAnimation { from: 0.15; to: 0.9; duration: 900 + (index % 4) * 300; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.9; to: 0.15; duration: 900 + (index % 4) * 300; easing.type: Easing.InOutSine }
            }
        }
    }

    // метеоры
    Repeater {
        model: 4
        delegate: Rectangle {
            id: meteor
            required property int index
            width: 90 + index * 25
            height: 1.5
            rotation: -24
            radius: 1
            x: -width; y: -20
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Rock.a(Theme.accent2, 0.85) }
            }
            opacity: 0
            SequentialAnimation {
                loops: Animation.Infinite
                running: true
                PauseAnimation { duration: 1800 + index * 2600 }
                ParallelAnimation {
                    NumberAnimation { target: meteor; property: "x"; from: bg.width * (0.15 + index * 0.18); to: bg.width * (0.55 + index * 0.18); duration: 900 }
                    NumberAnimation { target: meteor; property: "y"; from: bg.height * (0.05 + index * 0.08); to: bg.height * (0.28 + index * 0.08); duration: 900 }
                    SequentialAnimation {
                        NumberAnimation { target: meteor; property: "opacity"; from: 0; to: 0.9; duration: 120 }
                        PauseAnimation { duration: 500 }
                        NumberAnimation { target: meteor; property: "opacity"; from: 0.9; to: 0; duration: 280 }
                    }
                }
                PauseAnimation { duration: 4000 }
            }
        }
    }

    // горизонтальная разметка-сканер
    Canvas {
        anchors.fill: parent
        opacity: 0.22
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Rock.a(Theme.text, 0.05)
            ctx.lineWidth = 1
            for (let y = 0; y < height; y += 48) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }
            ctx.strokeStyle = Rock.a(Theme.accent, 0.08)
            for (let x = 0; x < width; x += 160) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }
        }
    }

    // сканирующая линия
    Rectangle {
        width: parent.width
        height: 120
        y: -height
        opacity: Theme.light ? 0.08 : 0.16
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Rock.a(Theme.accent2, 0.55) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            running: true
            NumberAnimation { from: -120; to: bg.height + 120; duration: 9000; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 1500 }
        }
    }

    // виньетка
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Rock.a(Theme.bg, Theme.light ? 0.18 : 0.55) }
            GradientStop { position: 0.35; color: "transparent" }
            GradientStop { position: 0.7; color: "transparent" }
            GradientStop { position: 1.0; color: Rock.a(Theme.bg, Theme.light ? 0.22 : 0.6) }
        }
    }

    // вспышка при неверном пароле
    Rectangle {
        anchors.fill: parent
        color: Rock.a(Theme.warn, 0.12)
        visible: bg.flash
        opacity: bg.flash ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 2
            border.color: Rock.a(Theme.warn, 0.9)
        }
    }
}
