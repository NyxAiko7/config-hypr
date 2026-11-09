import QtQuick
import QtQuick.Effects

// Фон локскрина: обои + «manga»-полутон, сцена световых лучей,
// потёк слёз и летящие ноты.
Item {
    id: bg

    property string wallpaper: ""
    property real enterProgress: 0
    property bool flash: false

    Rectangle {
        anchors.fill: parent
        visible: !Rock.marisa
        gradient: Gradient {
            GradientStop { position: 0.0; color: Rock.comic ? Rock.a(Rock.pink, 0.85) : Rock.sao ? "#030610" : "#060a14" }
            GradientStop { position: 0.55; color: Rock.comic ? Rock.a(Rock.purple, 0.8) : Rock.sao ? "#071a2b" : "#0d1730" }
            GradientStop { position: 1.0; color: Rock.comic ? Rock.a(Rock.cyan, 0.85) : Rock.sao ? "#0e3350" : "#1a2a4d" }
        }
    }

    // Aincrad: голографическая сетка поверх ночного неба
    SaoGrid {
        anchors.fill: parent
        step: 34
        animated: true
        opacity: 0.9
    }

    // Гримуар: локскрин — раскрытая пергаментная страница, а не звёздная ночь.
    Rectangle {
        anchors.fill: parent
        visible: Rock.marisa
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#fbf5e6" }
            GradientStop { position: 0.45; color: "#f6eed9" }
            GradientStop { position: 1.0; color: "#e7d5ad" }
        }
    }

    // старение бумаги и чернильные разводы
    Canvas {
        anchors.fill: parent
        visible: Rock.marisa
        opacity: 0.55
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            const stains = [
                [w * 0.08, h * 0.14, Math.min(w, h) * 0.22, 0.10],
                [w * 0.88, h * 0.78, Math.min(w, h) * 0.34, 0.12],
                [w * 0.72, h * 0.18, Math.min(w, h) * 0.16, 0.08]
            ]
            for (const s of stains) {
                const g = ctx.createRadialGradient(s[0], s[1], 0, s[0], s[1], s[2])
                g.addColorStop(0, Rock.a(Rock.ink, s[3]))
                g.addColorStop(0.55, Rock.a(Rock.ink, s[3] * 0.45))
                g.addColorStop(1, Rock.a(Rock.ink, 0))
                ctx.fillStyle = g
                ctx.fillRect(0, 0, w, h)
            }
            const v = ctx.createRadialGradient(w * 0.5, h * 0.46, Math.min(w, h) * 0.18,
                                               w * 0.5, h * 0.46, Math.max(w, h) * 0.72)
            v.addColorStop(0, "transparent")
            v.addColorStop(0.75, Rock.a(Rock.ink, 0.03))
            v.addColorStop(1, Rock.a(Rock.ink, 0.12))
            ctx.fillStyle = v
            ctx.fillRect(0, 0, w, h)
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
        visible: !Rock.marisa && wall.status === Image.Ready
        blurEnabled: true
        blur: 0.7
        blurMax: 80
        brightness: Rock.comic ? -0.42 : Rock.marisa ? -0.52 : -0.62
        saturation: Rock.comic ? -0.55 : Rock.marisa ? -0.38 : -0.78
    }

    // сцена световых лучей сверху — концертная подсветка
    Rectangle {
        visible: !Rock.marisa
        width: parent.width * 0.62; height: parent.height * 1.8
        x: -parent.width * 0.2; y: -parent.height * 0.8
        color: Rock.a(Rock.comic ? Rock.pink : Rock.gold, Rock.comic ? 0.10 : 0.07)
        rotation: -14
    }
    Rectangle {
        visible: !Rock.marisa
        width: parent.width * 0.46; height: parent.height * 1.8
        x: parent.width * 0.32; y: -parent.height * 0.8
        color: Rock.a(Rock.comic ? Rock.cyan : Rock.starlight, Rock.comic ? 0.08 : 0.06)
        rotation: 13
    }

    // «manga»-полутон: сетка точек
    Canvas {
        anchors.fill: parent
        visible: !Rock.marisa
        opacity: 0.5 * (0.35 + bg.enterProgress * 0.65)
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const step = Math.max(16, Math.min(width, height) / 42)
            ctx.fillStyle = Rock.comic ? Rock.a(Rock.ink2, 0.6) : Rock.a(Rock.starlight, 0.22)
            for (let y = 0; y < height; y += step) {
                for (let x = 0; x < width; x += step) {
                    ctx.beginPath()
                    ctx.arc(x, y, step * 0.16, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }
    }

    // гравюрная штриховка и звёздная пыль гримуара
    MarisaPattern {
        anchors.fill: parent
        opacity: 0.55
        onPaper: true
    }

    // луна и звёздный свет гримуара
    MarisaMoon {
        moonSize: Math.min(bg.width, bg.height) * 0.44
        moonColor: Rock.ink
        onPaper: true
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Math.max(56, parent.height * 0.07)
            rightMargin: Math.max(72, parent.width * 0.07)
        }
        opacity: 0.5
    }

    // падающие звёзды
    Repeater {
        model: Rock.marisa ? 6 : 0
        delegate: Text {
            required property int index
            text: index % 2 === 0 ? "✦" : "✧"
            color: index % 2 === 0 ? Rock.a(Rock.ink, 0.32) : Rock.a(Rock.pinkDeep, 0.55)
            font.pixelSize: 7 + (index % 3) * 3
            opacity: 0.18 + (index % 3) * 0.12
            x: bg.width * (0.35 + (index % 5) * 0.14)
            y: -40

            SequentialAnimation on y {
                loops: Animation.Infinite
                running: Rock.marisa
                PauseAnimation { duration: index * 1400 }
                NumberAnimation { from: -40; to: bg.height + 40; duration: 5200 + index * 700 }
            }
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: Rock.marisa
                PauseAnimation { duration: index * 1400 }
                NumberAnimation {
                    from: bg.width * (0.35 + (index % 5) * 0.14)
                    to: bg.width * (0.12 + (index % 5) * 0.14)
                    duration: 5200 + index * 700
                }
            }
            SequentialAnimation on rotation {
                loops: Animation.Infinite
                running: Rock.marisa
                NumberAnimation { from: 0; to: 360; duration: 7000 + index * 500 }
            }
        }
    }

    // большой магический круг Марисы
    Canvas {
        visible: Rock.marisa
        width: Math.min(parent.width, parent.height) * 0.82
        height: width
        anchors.centerIn: parent
        opacity: 0.26
        onWidthChanged: requestPaint()

        NumberAnimation on rotation {
            running: Rock.marisa
            from: 0
            to: 360
            duration: 90000
            loops: Animation.Infinite
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r = width * 0.46

            ctx.strokeStyle = Rock.a(Rock.ink, 0.55)
            ctx.lineWidth = Math.max(1, width * 0.0015)
            for (const k of [1.0, 0.82, 0.62]) {
                ctx.beginPath()
                ctx.arc(cx, cy, r * k, 0, Math.PI * 2)
                ctx.stroke()
            }

            ctx.beginPath()
            for (let i = 0; i < 6; i++) {
                const a = -Math.PI / 2 + i * Math.PI / 3
                const x = cx + Math.cos(a) * r * 0.62
                const y = cy + Math.sin(a) * r * 0.62
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.closePath()
            ctx.strokeStyle = Rock.a(Rock.pinkDeep, 0.7)
            ctx.stroke()

            ctx.strokeStyle = Rock.a(Rock.ink, 0.34)
            for (let i = 0; i < 48; i++) {
                const a = i * Math.PI * 2 / 48
                const r2 = r * (i % 4 === 0 ? 0.94 : 0.97)
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                ctx.lineTo(cx + Math.cos(a) * r * 1.0, cy + Math.sin(a) * r * 1.0)
                ctx.stroke()
            }

            ctx.fillStyle = Rock.a(Rock.gold, 0.9)
            for (let i = 0; i < 12; i++) {
                const a = i * Math.PI / 6
                const x = cx + Math.cos(a) * r * 1.03
                const y = cy + Math.sin(a) * r * 1.03
                ctx.beginPath()
                ctx.arc(x, y, Math.max(1.5, width * 0.004), 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    // потёк слёз — фирменный приём Bocchi перед гитарой
    Repeater {
        model: Rock.comic ? 6 : 0
        delegate: Rectangle {
            id: drop
            required property int index
            width: 2 * (2.5 + (index % 3) * 1.5)
            height: width
            radius: width / 2
            x: (index * 173 + 90) % Math.max(1, bg.width - 60)
            y: bg.height + 60
            color: [Rock.pink, Rock.cyan, Rock.yellow, Rock.cream, Rock.purple][index % 5]
            opacity: 0.25 + (index % 3) * 0.07
            NumberAnimation on y {
                from: bg.height + 60
                to: -40
                duration: 9000 + index * 1200
                loops: Animation.Infinite
                running: true
            }
            NumberAnimation on x {
                from: (index * 173 + 90) % Math.max(1, bg.width - 60)
                to: (index * 173 + 90) % Math.max(1, bg.width - 60) + 30 - (index % 2) * 60
                duration: 6000 + index * 700
                loops: Animation.Infinite
                running: true
                easing.type: Easing.InOutSine
            }
        }
    }

    // летящие ноты
    Repeater {
        model: Rock.comic ? 9 : 0
        delegate: Text {
            required property int index
            x: (index * 211 + 60) % Math.max(1, bg.width)
            y: bg.height + 50
            text: ["\uf001", "\uf005", "\uf004", "\uf008"][index % 4]
            color: [Rock.pink, Rock.cyan, Rock.yellow, Rock.cream][index % 4]
            opacity: 0.10 + (index % 3) * 0.05
            font.family: Theme.font
            font.pixelSize: 14 + (index % 4) * 7
            NumberAnimation on y {
                from: bg.height + 50
                to: -60
                duration: 8000 + index * 850
                loops: Animation.Infinite
                running: true
            }
            NumberAnimation on rotation {
                from: -18; to: 18
                duration: 3600 + index * 320
                loops: Animation.Infinite
                running: true
                easing.type: Easing.InOutSine
            }
        }
    }

    // экслибрис и вертикальный корешок страницы
    Text {
        visible: Rock.marisa
        text: "GRIMOIRE"
        rotation: -90
        x: 16
        y: bg.height * 0.72
        font.family: Rock.display
        font.pixelSize: 62
        font.weight: Font.Black
        font.letterSpacing: 14
        color: Rock.a(Rock.ink, 0.055)
    }

    Text {
        visible: Rock.marisa
        text: "M"
        x: bg.width - 386
        y: bg.height - 430
        font.family: Rock.display
        font.pixelSize: 430
        font.weight: Font.Black
        color: Rock.a(Rock.ink, 0.045)
    }

    // шашечная кромка страницы
    MarisaTrim {
        visible: Rock.marisa
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 14
        height: 5
        cell: 5
        opacity: 0.55
    }
    MarisaTrim {
        visible: Rock.marisa
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 14
        height: 5
        cell: 5
        opacity: 0.55
    }

    // гексагональное кольцо Aincrad
    Canvas {
        visible: Rock.sao
        width: Math.min(parent.width, parent.height) * 0.72
        height: width
        anchors.centerIn: parent
        opacity: 0.22
        onWidthChanged: requestPaint()

        NumberAnimation on rotation {
            running: Rock.sao
            from: 0
            to: 360
            duration: 120000
            loops: Animation.Infinite
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r = width * 0.46

            ctx.strokeStyle = Rock.a(Rock.gold, 0.7)
            ctx.lineWidth = Math.max(1, width * 0.0016)
            for (const k of [1.0, 0.72, 0.46]) {
                ctx.beginPath()
                for (let i = 0; i < 6; i++) {
                    const a = -Math.PI / 2 + i * Math.PI / 3
                    const x = cx + Math.cos(a) * r * k
                    const y = cy + Math.sin(a) * r * k
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.closePath()
                ctx.stroke()
            }

            ctx.strokeStyle = Rock.a(Rock.starlight, 0.5)
            for (let i = 0; i < 48; i++) {
                const a = i * Math.PI * 2 / 48
                const r2 = r * (i % 4 === 0 ? 0.94 : 0.98)
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
                ctx.stroke()
            }
        }
    }

    Text {
        visible: Rock.sao
        text: "LINK START"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(28, parent.height * 0.06)
        color: Rock.a(Rock.gold, 0.10)
        font.family: Rock.display
        font.pixelSize: Math.min(52, parent.width * 0.034)
        font.weight: Font.Black
        font.letterSpacing: 16
    }

    Text {
        visible: Rock.sao
        text: "SWORD ART ONLINE"
        rotation: -90
        x: 18
        y: bg.height * 0.7
        font.family: Rock.display
        font.pixelSize: 54
        font.weight: Font.Black
        font.letterSpacing: 12
        color: Rock.a(Rock.gold, 0.055)
    }

    // вспышка при неверном пароля
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: bg.flash
        border.width: 5
        border.color: Rock.sao ? Rock.danger : Rock.pink
        opacity: bg.flash ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
