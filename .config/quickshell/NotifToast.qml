import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: toast

    property var notif: null
    property real ttlFrac: 1
    property real slide: 120
    property real reveal: 0
    property real pulse: 0

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property var actions: Notifs.actionList(notif)
    readonly property color tone: critical ? Rock.orange : Rock.accent
    readonly property color tone2: critical ? Rock.accent : Rock.accent2
    readonly property string appName: notif ? (notif.appName || "") : ""
    readonly property string initial: appName !== "" ? appName.charAt(0).toUpperCase() : "N"

    implicitWidth: 420
    implicitHeight: 204

    function mixColor(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t, 1)
    }

    Connections {
        target: Notifs
        function onKeyChanged() {
            dropIn.restart()
            revealAnim.restart()
            lifeAnim.restart()
        }
    }

    NumberAnimation {
        id: dropIn
        target: toast
        property: "slide"
        from: 120
        to: 0
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.1
    }

    NumberAnimation {
        id: revealAnim
        target: toast
        property: "reveal"
        from: 0
        to: 1
        duration: 460
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: lifeAnim
        target: toast
        property: "ttlFrac"
        from: 1
        to: 0
        duration: Math.max(1, Notifs.duration)
        running: true
        paused: Notifs.hold
    }

    NumberAnimation on pulse {
        running: toast.notif !== null && !Notifs.hold
        from: 0
        to: 1
        duration: 1800
        loops: Animation.Infinite
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Notifs.defaultAction(toast.notif) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: Notifs.hold = true
        onExited: Notifs.hold = false
        onClicked: mouse => {
            const n = toast.notif
            if (!n) return
            if (mouse.button === Qt.RightButton) { Notifs.hide(); return }
            if (mouse.button === Qt.MiddleButton) { Notifs.dismissCurrent(); return }
            const d = Notifs.defaultAction(n)
            if (d) { d.invoke(); Notifs.dismissCurrent() }
            else Notifs.hide()
        }
    }

    Rectangle {
        x: card.x - 4
        y: card.y - 4
        width: card.width + 8
        height: card.height + 8
        radius: card.radius + 4
        color: "transparent"
        border.width: 1
        border.color: Rock.a(toast.tone, toast.critical ? 0.55 : 0.20)
    }

    Rectangle {
        id: card
        x: 6
        y: 6
        width: toast.width - 14
        height: toast.height - 12
        radius: 21
        color: Rock.uiSurface
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.lighter(Rock.uiSurface, 1.06) }
            GradientStop { position: 1.0; color: Qt.darker(Rock.uiSurface, 1.06) }
        }
        border.width: toast.critical ? 2 : 1
        border.color: toast.critical ? Rock.a(Rock.orange, 0.85)
                                       : Rock.a(toast.tone, 0.42)
        clip: true

        Rectangle {
            width: 46
            height: 46
            radius: 8
            rotation: 45
            x: card.width - 28
            y: -24
            color: Rock.a(toast.tone2, 0.10)
            border.width: 1
            border.color: Rock.a(toast.tone2, 0.22)
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 70
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 8
            text: toast.initial
            color: Rock.a(Rock.uiText, 0.045)
            font.family: Rock.display
            font.weight: Font.Black
            font.pixelSize: 154
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 62
            radius: 1.5
            gradient: Gradient {
                GradientStop { position: 0.0; color: toast.tone2 }
                GradientStop { position: 1.0; color: toast.tone }
            }
        }

        Item {
            id: spectrum
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 13
            height: 3

            readonly property int n: 32
            readonly property real segW: Math.max(2, (width - (n - 1) * 2) / n)

            Repeater {
                model: spectrum.n
                delegate: Rectangle {
                    required property int index
                    x: index * (spectrum.segW + 2)
                    y: 0
                    width: spectrum.segW
                    height: 3
                    radius: 1.5
                    color: toast.mixColor(toast.tone, toast.tone2, index / (spectrum.n - 1))
                    opacity: (index + 1) / spectrum.n <= toast.ttlFrac ? 1 : 0.12
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
            }
        }

        Item {
            id: emblem
            x: 24
            y: 40
            width: 58
            height: 58

            Rectangle {
                anchors.centerIn: parent
                width: 54
                height: 54
                radius: 27
                color: Rock.a(toast.tone, toast.critical ? 0.16 : 0.08)
            }

            Canvas {
                id: ttlRing
                anchors.centerIn: parent
                width: 58
                height: 58
                property color tone: toast.tone
                property color track: Rock.a(Rock.uiText, 0.10)
                onToneChanged: requestPaint()
                onTrackChanged: requestPaint()
                onTtlFractionChanged: requestPaint()
                property real ttlFraction: toast.ttlFrac

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    const cx = width / 2
                    const cy = height / 2
                    const r = 25

                    ctx.lineWidth = 2
                    ctx.strokeStyle = track
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()

                    ctx.lineWidth = 2.5
                    ctx.lineCap = "round"
                    ctx.strokeStyle = tone
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * Math.max(0, Math.min(1, ttlFraction)))
                    ctx.stroke()
                }

            }

            Rectangle {
                anchors.centerIn: parent
                width: 44
                height: 44
                radius: 13
                rotation: 45
                color: Rock.uiSurface2
                border.width: 1
                border.color: Rock.a(toast.tone, 0.65)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Rock.a(toast.tone, 0.22) }
                    GradientStop { position: 1.0; color: Rock.a(toast.tone2, 0.10) }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 34
                height: 34
                radius: 17
                color: Rock.uiSurface2
                border.width: 1
                border.color: Rock.a(Rock.uiText, 0.10)
            }

            Image {
                id: appIcon
                anchors.centerIn: parent
                width: 21
                height: 21
                source: Notifs.appIconSource(toast.notif)
                sourceSize: Qt.size(42, 42)
                smooth: true
                visible: status === Image.Ready
            }

            Lbl {
                anchors.centerIn: parent
                visible: appIcon.status !== Image.Ready
                text: toast.critical ? "\uf12a" : "\uf0f3"
                color: toast.tone
                font.pixelSize: 15
            }

            Rectangle {
                width: 8
                height: 8
                radius: 2
                rotation: 45
                x: parent.width - width - 1
                y: 1
                color: toast.tone2
                border.width: 1
                border.color: Rock.a(Rock.uiText, 0.35)
            }
        }

        Item {
            id: signalRail
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 46
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            width: 13

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 1
                height: parent.height
                color: Rock.a(Rock.uiText, 0.08)
            }

            Repeater {
                model: 7
                delegate: Rectangle {
                    required property int index
                    width: index % 3 === 0 ? 13 : 7
                    height: 2.5
                    radius: 1.25
                    x: signalRail.width - width
                    y: index * (signalRail.height - height) / 6
                    color: toast.mixColor(toast.tone, toast.tone2, index / 6)
                    opacity: 0.16 + 0.62 * Math.pow(0.5 + 0.5 * Math.sin(
                        2 * Math.PI * ((toast.pulse + index * 0.13) % 1) - Math.PI / 2), 2)
                }
            }
        }

        Item {
            id: body
            anchors.left: emblem.right
            anchors.leftMargin: 17
            anchors.right: signalRail.left
            anchors.rightMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 34
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            opacity: Math.min(1, toast.reveal * 1.3)

            ColumnLayout {
                anchors.fill: parent
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    Lbl {
                        Layout.fillWidth: true
                        text: toast.appName !== "" ? toast.appName.toUpperCase() : "SIGNAL"
                        color: toast.tone
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.15
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 1
                        rotation: 45
                        color: toast.tone2
                        opacity: 0.8
                    }

                    Lbl {
                        text: Notifs.timeAgo(toast.notif)
                        color: Rock.a(Rock.uiText, 0.38)
                        font.pixelSize: 9
                    }

                    Lbl {
                        visible: Notifs.pending > 0
                        text: "+" + Notifs.pending
                        color: toast.tone2
                        font.pixelSize: 9
                        font.bold: true
                    }

                    IconBtn {
                        size: 20
                        icon: "\uf00d"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(toast.tone, 0.18)
                        onClicked: Notifs.dismissCurrent()
                    }
                }

                Lbl {
                    Layout.fillWidth: true
                    text: toast.notif ? toast.notif.summary : ""
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: toast.notif ? String(toast.notif.body).replace(/\s*\n\s*/g, "  ") : ""
                    color: Rock.a(Rock.uiText, 0.62)
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: toast.actions.length > 0 || toast.critical

                    Repeater {
                        model: toast.actions.slice(0, 2)
                        delegate: Rectangle {
                            id: act
                            required property var modelData
                            implicitWidth: actLbl.implicitWidth + 20
                            implicitHeight: 24
                            radius: 7
                            color: actArea.containsMouse ? Rock.a(toast.tone, 0.28)
                                                         : Rock.a(toast.tone, 0.11)
                            border.width: 1
                            border.color: Rock.a(toast.tone, actArea.containsMouse ? 0.85 : 0.42)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Lbl {
                                id: actLbl
                                anchors.centerIn: parent
                                text: act.modelData.text
                                color: Rock.uiText
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                id: actArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    act.modelData.invoke()
                                    Notifs.dismissCurrent()
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Lbl {
                        visible: toast.critical
                        text: "PRIORITY"
                        color: Rock.orange
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 1.2
                        SequentialAnimation on opacity {
                            running: toast.critical
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 520 }
                            NumberAnimation { to: 1; duration: 520 }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: 26
            height: card.height
            y: 0
            x: -30 + toast.reveal * (card.width + 60)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Rock.a(toast.tone, 0.14) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.7 * Math.sin(Math.PI * toast.reveal)
        }
    }
}
