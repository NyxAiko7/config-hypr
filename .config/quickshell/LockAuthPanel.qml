import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// Карточка разблокировки в виде гитарного стикера.
RockCard {
    id: panel

    property real enterProgress: 0
    property string buffer: ""
    property bool busy: false
    property bool reveal: false
    property string status: ""
    property int shakeKey: 0
    property bool fpAvailable: false
    property int fpFails: 0
    property int batPct: -1
    property bool charging: false

    signal submitted()
    signal revealRequested()

    preferredWidth: Math.min(398, (parent ? parent.width : 1920) * 0.31)
    fill: Rock.cream
    edge: Rock.ink
    shadowColor: Rock.pink
    radius: 20
    borderWidth: 3
    padding: 20
    spacing: 12
    rotation: -1.4
    opacity: enterProgress

    transform: [
        Translate { id: shake },
        Translate { x: (1 - panel.enterProgress) * 48 }
    ]

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shake; property: "x"; to: -16; duration: 50 }
        NumberAnimation { target: shake; property: "x"; to: 16;  duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: -10; duration: 70 }
        NumberAnimation { target: shake; property: "x"; to: 10;   duration: 70 }
        NumberAnimation { target: shake; property: "x"; to: 0;    duration: 50 }
    }
    onShakeKeyChanged: shakeAnim.restart()

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Item {
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58

            Canvas {
                anchors.fill: parent
                visible: UPower.displayDevice.isLaptopBattery
                antialiasing: true
                readonly property real frac: Math.max(0, Math.min(1, UPower.displayDevice.percentage))
                onFracChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2, cy = height / 2, r = width / 2 - 3
                    ctx.lineWidth = 4
                    ctx.lineCap = "round"
                    ctx.strokeStyle = Rock.a(Rock.ink, 0.14)
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
                    if (frac > 0.001) {
                        ctx.strokeStyle = panel.batPct <= 20 && !panel.charging
                            ? Rock.pinkDeep
                            : (panel.charging ? Rock.cyan : Rock.pink)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac)
                        ctx.stroke()
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 46; height: 46; radius: 23
                color: Rock.pink
                border.width: 3
                border.color: Rock.ink
                Lbl {
                    anchors.centerIn: parent
                    text: "\uf023"
                    color: Rock.cream
                    font.pixelSize: 18
                }
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Lbl {
                text: "BOCCHI LOCK"
                color: Rock.pinkDeep
                font.family: Rock.display
                font.pixelSize: 10
                font.weight: Font.Black
                font.letterSpacing: 2.4
            }
            Lbl {
                Layout.fillWidth: true
                text: Quickshell.env("USER") + "@" + (Quickshell.env("HOSTNAME") || "artix")
                color: Rock.ink
                font.family: Rock.display
                font.pixelSize: 15
                font.weight: Font.Black
                elide: Text.ElideRight
            }
            Lbl {
                Layout.fillWidth: true
                text: panel.busy ? "Проверка…"
                    : (panel.fpAvailable ? "Пароль или отпечаток" : "Введите пароль")
                color: Rock.a(Rock.ink, 0.55)
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Lbl {
            Layout.alignment: Qt.AlignVCenter
            text: panel.fpAvailable ? "\uf577" : "\uf084"
            color: panel.fpAvailable ? Rock.pinkDeep : Rock.a(Rock.ink, 0.35)
            font.pixelSize: 17
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 3
        radius: 1.5
        color: Rock.ink
    }

    Rectangle {
        id: field
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        radius: 12
        color: Rock.paper
        border.width: 3
        border.color: panel.status !== ""
            ? Rock.pinkDeep
            : (panel.busy ? Rock.cyan : Rock.ink)
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 36; height: 30; radius: 8
            color: Rock.cyan
            border.width: 2
            border.color: Rock.ink
            Lbl {
                anchors.centerIn: parent
                text: Kb.layout
                color: Rock.ink
                font.pixelSize: 10
                font.weight: Font.Black
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Kb.next()
            }
        }

        Lbl {
            anchors.left: parent.left
            anchors.leftMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            text: "›"
            color: Rock.pinkDeep
            font.pixelSize: 22
            font.weight: Font.Black
        }

        Lbl {
            anchors.centerIn: parent
            visible: panel.buffer === ""
            text: panel.busy ? "Проверка…" : "Введите пароль"
            color: Rock.a(Rock.ink, 0.45)
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Row {
            anchors.centerIn: parent
            spacing: 7
            visible: !panel.reveal && panel.buffer !== ""
            Repeater {
                model: Math.min(panel.buffer.length, 16)
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Rock.pink
                    border.width: 1
                    border.color: Rock.ink
                }
            }
        }

        Lbl {
            anchors.centerIn: parent
            width: parent.width - 140
            visible: panel.reveal && panel.buffer !== ""
            text: panel.buffer
            color: Rock.ink
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideLeft
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 30; height: 30; radius: 8
            color: eyeArea.containsMouse ? Rock.a(Rock.cyan, 0.35) : "transparent"
            Lbl {
                anchors.centerIn: parent
                text: panel.reveal ? "\uf070" : "\uf06e"
                color: Rock.ink
                font.pixelSize: 12
            }
            MouseArea {
                id: eyeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.revealRequested()
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 3
            width: 46; height: 3; radius: 1.5
            color: panel.status !== "" ? Rock.pinkDeep : Rock.pink
            opacity: panel.buffer !== "" ? 0.95 : 0.3
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 50

        Rectangle {
            x: 4; y: 4
            width: parent.width; height: 42
            radius: 12
            color: Rock.pink
            border.width: 3
            border.color: Rock.ink
        }
        Rectangle {
            width: parent.width
            height: 42
            radius: 12
            color: enterArea.containsMouse ? Rock.a(Rock.yellow, 0.9) : Rock.yellow
            border.width: 3
            border.color: Rock.ink
            Behavior on color { ColorAnimation { duration: 120 } }
            Lbl {
                anchors.centerIn: parent
                text: panel.busy ? "ПРОВЕРКА…" : "РАЗБЛОКИРОВАТЬ  ↵"
                color: Rock.ink
                font.family: Rock.display
                font.pixelSize: 12
                font.weight: Font.Black
                font.letterSpacing: 1.6
            }
            MouseArea {
                id: enterArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!panel.busy) panel.submitted()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        RockChip { offset: 1.5; padH: 8; padV: 2; radius: 6; fill: Rock.cream; shadowColor: Rock.cyan
            Lbl { text: "↵"; color: Rock.pinkDeep; font.pixelSize: 10; font.weight: Font.Black }
            Lbl { text: "войти"; color: Rock.a(Rock.ink, 0.65); font.pixelSize: 9 }
        }
        RockChip { offset: 1.5; padH: 8; padV: 2; radius: 6; fill: Rock.cream; shadowColor: Rock.yellow
            Lbl { text: "Tab"; color: Rock.pinkDeep; font.pixelSize: 10; font.weight: Font.Black }
            Lbl { text: "показать"; color: Rock.a(Rock.ink, 0.65); font.pixelSize: 9 }
        }
        RockChip { offset: 1.5; padH: 8; padV: 2; radius: 6; fill: Rock.cream; shadowColor: Rock.pink
            Lbl { text: "Esc"; color: Rock.pinkDeep; font.pixelSize: 10; font.weight: Font.Black }
            Lbl { text: "сброс"; color: Rock.a(Rock.ink, 0.65); font.pixelSize: 9 }
        }
        Item { Layout.fillWidth: true }
        RowLayout {
            visible: panel.fpAvailable && panel.fpFails < 8
            spacing: 4
            Lbl { text: "\uf577"; color: Rock.pinkDeep; font.pixelSize: 12 }
            Lbl { text: "палец"; color: Rock.a(Rock.ink, 0.55); font.pixelSize: 9; font.weight: Font.Bold }
        }
    }

    Lbl {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        text: panel.status
        visible: panel.status !== ""
        color: Rock.pinkDeep
        font.pixelSize: 11
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
