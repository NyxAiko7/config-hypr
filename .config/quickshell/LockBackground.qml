import QtQuick
import QtQuick.Effects

// Фон локскрина: обои + «manga»-полутон, сцена световых лучей,
// гигантский контурный заголовок группы, потёк слёз и летящие ноты.
Item {
    id: bg

    property string wallpaper: ""
    property real enterProgress: 0
    property bool flash: false

    Rectangle { anchors.fill: parent; color: Rock.ink }

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
        blur: 0.7
        blurMax: 80
        brightness: -0.42
        saturation: -0.55
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Rock.a(Rock.ink, 0.62) }
            GradientStop { position: 0.5; color: Rock.a(Rock.ink2, 0.38) }
            GradientStop { position: 1.0; color: Rock.a(Rock.ink, 0.82) }
        }
    }

    // сцена световых лучей сверху — концертная подсветка
    Rectangle {
        width: parent.width * 0.62; height: parent.height * 1.8
        x: -parent.width * 0.2; y: -parent.height * 0.8
        color: Rock.a(Rock.pink, 0.10)
        rotation: -14
    }
    Rectangle {
        width: parent.width * 0.46; height: parent.height * 1.8
        x: parent.width * 0.32; y: -parent.height * 0.8
        color: Rock.a(Rock.cyan, 0.08)
        rotation: 13
    }

    // «manga»-полутон: сетка точек
    Canvas {
        anchors.fill: parent
        opacity: 0.5 * (0.35 + bg.enterProgress * 0.65)
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const step = Math.max(16, Math.min(width, height) / 42)
            ctx.fillStyle = Rock.a(Rock.ink2, 0.6)
            for (let y = 0; y < height; y += step) {
                for (let x = 0; x < width; x += step) {
                    ctx.beginPath()
                    ctx.arc(x, y, step * 0.16, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }
    }

    // гигантский контурный заголовок группы
    Item {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: parent.width * 0.02
        anchors.verticalCenterOffset: -parent.height * 0.04
        width: word.width
        height: word.height
        opacity: 0.13 * (0.4 + bg.enterProgress * 0.6)
        rotation: -7

        Item {
            id: word
            width: main.implicitWidth
            height: main.implicitHeight + theRock.implicitHeight - 18

            Text {
                x: 12; y: 12
                width: main.width; height: main.height
                text: main.text
                color: Rock.cyan
                font.family: Rock.display
                font.pixelSize: main.font.pixelSize
                font.weight: Font.Black
                font.letterSpacing: -3
            }
            Text {
                x: 6; y: 6
                width: main.width; height: main.height
                text: main.text
                color: Rock.pink
                font.family: Rock.display
                font.pixelSize: main.font.pixelSize
                font.weight: Font.Black
                font.letterSpacing: -3
            }
            Text {
                id: main
                text: "BOCCHI"
                color: Rock.cream
                font.family: Rock.display
                font.pixelSize: Math.min(300, bg.width * 0.30)
                font.weight: Font.Black
                font.letterSpacing: -3
            }
            Text {
                id: theRock
                anchors.top: main.bottom
                anchors.left: main.left
                anchors.topMargin: -18
                text: "THE ROCK"
                color: Rock.yellow
                font.family: Rock.display
                font.pixelSize: Math.min(84, bg.width * 0.055)
                font.weight: Font.Black
                font.letterSpacing: 8
            }
        }
    }

    // потёк слёз — фирменный приём Bocchi перед гитарой
    Repeater {
        model: 6
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
        model: 9
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

    // вспышка при неверном пароля
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: bg.flash
        border.width: 5
        border.color: Rock.pink
        opacity: bg.flash ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
