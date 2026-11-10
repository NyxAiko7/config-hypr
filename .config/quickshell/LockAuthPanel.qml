import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// «Шлюз»: панель разблокировки в виде астрономического терминала.
Item {
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

    width: Math.min(420, (parent ? parent.width : 1920) * 0.32)
    height: card.height
    opacity: enterProgress

    transform: [
        Translate { id: shake },
        Translate { x: (1 - panel.enterProgress) * 40; y: (1 - panel.enterProgress) * 12 }
    ]

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
        NumberAnimation { target: shake; property: "x"; to: 14;  duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: -9; duration: 70 }
        NumberAnimation { target: shake; property: "x"; to: 9;   duration: 70 }
        NumberAnimation { target: shake; property: "x"; to: 0;    duration: 50 }
    }
    onShakeKeyChanged: shakeAnim.restart()

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 40
        radius: 18
        color: Rock.a(Theme.surface, 0.72)
        border.width: 1
        border.color: Rock.a(Theme.accent, 0.28)
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Rock.a(Theme.text, 0.06) }
                GradientStop { position: 0.35; color: "transparent" }
                GradientStop { position: 1.0; color: Rock.a(Theme.bg, 0.22) }
            }
        }

        Column {
            id: col
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: 20
            }
            spacing: 14

            RowLayout {
                width: parent.width
                spacing: 12

                Item {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    Rectangle {
                        anchors.fill: parent
                        radius: 28
                        color: Rock.a(Theme.accent, 0.12)
                        border.width: 1
                        border.color: Rock.a(Theme.accent, 0.35)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 44; height: 44; radius: 22
                        color: Rock.a(Theme.bg, 0.45)
                        clip: true
                        Avatar {
                            anchors.fill: parent
                            visible: PanelConfig.hasAvatar
                            source: PanelConfig.avatarUrl
                            letter: (Quickshell.env("USER") || "user").charAt(0).toUpperCase()
                            bg: Rock.a(Theme.accent, 0.25)
                            fg: Theme.text
                            radius: 22
                            fontFamily: Theme.font
                            fontSize: 16
                            fontWeight: Font.DemiBold
                        }
                        Lbl {
                            anchors.centerIn: parent
                            visible: !PanelConfig.hasAvatar
                            text: "\uf007"
                            color: Theme.accent2
                            font.pixelSize: 18
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Lbl {
                        text: I18n.t("ДОСТУП К СИСТЕМЕ")
                        color: Rock.a(Theme.accent2, 0.95)
                        font.family: Theme.font
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2.6
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: Quickshell.env("USER") || "user"
                        color: Theme.text
                        font.family: Rock.display
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: Quickshell.env("HOSTNAME") || "host"
                        color: Rock.a(Theme.text, 0.5)
                        font.family: Theme.font
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                Column {
                    spacing: 4
                    Layout.alignment: Qt.AlignTop
                    Lbl {
                        anchors.right: parent.right
                        text: panel.fpAvailable ? "\uf577" : "\uf023"
                        color: panel.fpAvailable ? Theme.accent2 : Rock.a(Theme.text, 0.35)
                        font.pixelSize: 16
                    }
                    Lbl {
                        anchors.right: parent.right
                        visible: UPower.displayDevice.isLaptopBattery && panel.batPct >= 0
                        text: panel.batPct + "%"
                        color: panel.batPct <= 20 && !panel.charging ? Theme.warn : Rock.a(Theme.text, 0.5)
                        font.family: Theme.font
                        font.pixelSize: 9
                    }
                }
            }

            // кольцо-сканер
            Item {
                width: parent.width
                height: 150

                Canvas {
                    id: ring
                    anchors.centerIn: parent
                    width: 140; height: 140
                    antialiasing: true
                    property real spin: 0
                    property int filled: Math.min(panel.buffer.length, 12)
                    property bool err: panel.status !== ""
                    property bool okBusy: panel.busy
                    onSpinChanged: requestPaint()
                    onFilledChanged: requestPaint()
                    onErrChanged: requestPaint()
                    onOkBusyChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    NumberAnimation on spin {
                        loops: Animation.Infinite
                        running: true
                        from: 0; to: Math.PI * 2
                        duration: panel.busy ? 2200 : 9000
                    }
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const cx = width / 2, cy = height / 2
                        const r1 = 62, r2 = 52
                        ctx.lineCap = "round"

                        ctx.strokeStyle = Rock.a(Theme.text, 0.08)
                        ctx.lineWidth = 6
                        ctx.beginPath(); ctx.arc(cx, cy, r1, 0, Math.PI * 2); ctx.stroke()

                        const segs = 12
                        for (let i = 0; i < segs; i++) {
                            const a0 = -Math.PI / 2 + i * (Math.PI * 2 / segs) + 0.08
                            const a1 = a0 + (Math.PI * 2 / segs) - 0.16
                            const on = i < filled
                            ctx.strokeStyle = err ? Rock.a(Theme.warn, on ? 0.95 : 0.12)
                                : (on ? Rock.a(Theme.accent2, 0.95) : Rock.a(Theme.text, 0.10))
                            ctx.lineWidth = 6
                            ctx.beginPath(); ctx.arc(cx, cy, r1, a0, a1); ctx.stroke()
                        }

                        ctx.strokeStyle = Rock.a(Theme.accent, okBusy ? 0.8 : 0.35)
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.arc(cx, cy, r2, spin, spin + Math.PI * (okBusy ? 1.2 : 0.7))
                        ctx.stroke()
                        ctx.strokeStyle = Rock.a(Theme.accent2, 0.25)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r2, spin + Math.PI, spin + Math.PI * 1.25)
                        ctx.stroke()

                        ctx.fillStyle = Rock.a(Theme.text, 0.06)
                        for (let i = 0; i < 24; i++) {
                            const a = i * Math.PI / 12
                            ctx.beginPath()
                            ctx.arc(cx + Math.cos(a) * 70, cy + Math.sin(a) * 70, 1.2, 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }
                }

                Column {
                    anchors.centerIn: ring
                    spacing: 2
                    Lbl {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: panel.busy ? "\uf110" : (panel.status !== "" ? "\uf071" : (panel.buffer.length > 0 ? "\uf023" : (panel.fpAvailable ? "\uf577" : "\uf084")))
                        color: panel.status !== "" ? Theme.warn : (panel.busy ? Theme.accent2 : Theme.accent)
                        font.pixelSize: 22
                        RotationAnimator on rotation {
                            running: panel.busy
                            from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        }
                    }
                    Lbl {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: panel.busy ? I18n.t("Проверка…") : (panel.status !== "" ? I18n.t("ОТКАЗ") : (panel.buffer.length > 0 ? panel.buffer.length : ""))
                        color: panel.status !== "" ? Theme.warn : Rock.a(Theme.text, 0.55)
                        font.family: Theme.font
                        font.pixelSize: panel.buffer.length > 0 && !panel.busy && panel.status === "" ? 16 : 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                    }
                }
            }

            // поле ввода
            Rectangle {
                id: field
                width: parent.width
                height: 46
                radius: 12
                color: Rock.a(Theme.bg, 0.35)
                border.width: 1
                border.color: panel.status !== "" ? Rock.a(Theme.warn, 0.7)
                    : (panel.busy ? Rock.a(Theme.accent2, 0.7) : Rock.a(Theme.text, 0.14))
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Rectangle {
                        width: 34; height: 26; radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        color: Rock.a(Theme.accent, 0.18)
                        border.width: 1
                        border.color: Rock.a(Theme.accent, 0.35)
                        Lbl {
                            anchors.centerIn: parent
                            text: Kb.layout
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Kb.next() }
                    }

                    Item {
                        width: parent.width - 34 - 30 - 16 - 24
                        height: parent.height

                        Lbl {
                            anchors.centerIn: parent
                            visible: panel.buffer === ""
                            text: panel.busy ? I18n.t("Проверка…")
                                : (panel.fpAvailable ? I18n.t("Пароль или отпечаток") : I18n.t("Введите пароль"))
                            color: Rock.a(Theme.text, 0.35)
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            visible: !panel.reveal && panel.buffer !== ""
                            Repeater {
                                model: Math.min(panel.buffer.length, 18)
                                Rectangle {
                                    width: 7; height: 7; radius: 3.5
                                    color: Theme.accent2
                                    opacity: 0.9
                                }
                            }
                        }

                        Lbl {
                            anchors.centerIn: parent
                            width: parent.width
                            visible: panel.reveal && panel.buffer !== ""
                            text: panel.buffer
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideLeft
                        }
                    }

                    Rectangle {
                        width: 30; height: 30; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: eyeArea.containsMouse ? Rock.a(Theme.text, 0.08) : "transparent"
                        Lbl {
                            anchors.centerIn: parent
                            text: panel.reveal ? "\uf070" : "\uf06e"
                            color: Rock.a(Theme.text, 0.7)
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
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 12
                color: enterArea.containsMouse ? Rock.a(Theme.accent, 0.95) : Rock.a(Theme.accent, 0.78)
                border.width: 1
                border.color: Rock.a(Theme.accent2, 0.35)
                Behavior on color { ColorAnimation { duration: 120 } }
                Lbl {
                    anchors.centerIn: parent
                    text: panel.busy ? I18n.t("ПРОВЕРКА…") : I18n.t("РАЗБЛОКИРОВАТЬ  ↵")
                    color: Theme.textOnAccent
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2.2
                }
                MouseArea {
                    id: enterArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!panel.busy) panel.submitted()
                }
            }

            RowLayout {
                width: parent.width
                spacing: 14
                Row { spacing: 5; Lbl { text: "↵"; color: Theme.accent2; font.pixelSize: 10; font.weight: Font.DemiBold } Lbl { text: I18n.t("войти"); color: Rock.a(Theme.text, 0.45); font.pixelSize: 9 } }
                Row { spacing: 5; Lbl { text: "Tab"; color: Theme.accent2; font.pixelSize: 10; font.weight: Font.DemiBold } Lbl { text: I18n.t("показать"); color: Rock.a(Theme.text, 0.45); font.pixelSize: 9 } }
                Row { spacing: 5; Lbl { text: "Esc"; color: Theme.accent2; font.pixelSize: 10; font.weight: Font.DemiBold } Lbl { text: I18n.t("сброс"); color: Rock.a(Theme.text, 0.45); font.pixelSize: 9 } }
                Item { Layout.fillWidth: true }
                Row {
                    visible: panel.fpAvailable && panel.fpFails < 8
                    spacing: 5
                    Lbl { text: "\uf577"; color: Theme.accent2; font.pixelSize: 11 }
                    Lbl { text: I18n.t("палец"); color: Rock.a(Theme.text, 0.45); font.pixelSize: 9 }
                }
            }

            Lbl {
                width: parent.width
                text: panel.status
                visible: panel.status !== ""
                color: Theme.warn
                font.family: Theme.font
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
