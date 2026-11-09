import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

// Уведомление-«кассета» в духе Bocchi the Rock.
Item {
    id: toast

    property var notif: null
    property real ttlFrac: 1
    property real slide: 0
    property real wobble: -1.2

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property var actions: Notifs.actionList(notif)

    implicitWidth: 396
    implicitHeight: 202

    Connections {
        target: Notifs
        function onKeyChanged() {
            dropIn.restart()
            wobbleAnim.restart()
            lifeAnim.restart()
        }
    }

    NumberAnimation {
        id: dropIn
        target: toast
        property: "slide"
        from: 100
        to: 0
        duration: 480
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }

    NumberAnimation {
        id: wobbleAnim
        target: toast
        property: "wobble"
        from: -5
        to: -1.2
        duration: 650
        easing.type: Easing.OutElastic
        easing.amplitude: 1.1
        easing.period: 0.28
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
        visible: Rock.comic
        x: 6
        y: 7
        width: shell.width
        height: shell.height
        radius: 18
        color: toast.critical ? Rock.orange : Rock.pink
        border.width: 3
        border.color: Rock.ink
    }

    Rectangle {
        id: shell
        width: toast.width - 8
        height: toast.height - 9
        radius: Rock.comic ? 18 : Rock.marisa ? 8 : Rock.sao ? 4 : 13
        color: Rock.uiSurface
        border.width: Rock.uiBorder
        border.color: Rock.uiEdge
        rotation: Rock.comic ? toast.wobble : 0
        transformOrigin: Item.Center

        SaoGrid {
            anchors.fill: parent
            step: 24
        }

        MarisaPattern {
            anchors.fill: parent
            opacity: 0.38
        }

        MarisaTrim {
            visible: Rock.marisa
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 5
            height: 3
            cell: 3
        }

        MarisaFrame {
            anchors.fill: parent
            inset: 6
            frameRadius: Math.max(2, Rock.uiRadiusSm)
            runes: false
        }

        SaoFrame {
            anchors.fill: parent
            inset: 4
            cut: 9
            segments: 18
        }

        Rectangle {
            visible: Rock.comic
            x: -2
            y: 26
            width: 20
            height: 44
            radius: 5
            color: Rock.yellow
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            Lbl {
                anchors.centerIn: parent
                text: "A"
                color: Rock.ink
                font.family: Rock.display
                font.weight: Font.Black
                font.pixelSize: 14
            }
        }

        Rectangle {
            visible: !Rock.comic
            x: -1
            y: 22
            width: 4
            height: 52
            radius: 2
            color: Rock.gold
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 2
                color: Rock.gold
                rotation: 45
                border.width: 2
                border.color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.7)
            }
        }

        Repeater {
            model: Rock.comic ? 0 : 16
            delegate: Rectangle {
                required property int index
                x: ((index * 61 + 19) % 97) / 97 * shell.width
                y: ((index * 43 + 13) % 89) / 89 * shell.height
                width: index % 5 === 0 ? 2 : 1
                height: width
                radius: width / 2
                color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, index % 5 === 0 ? 0.5 : 0.24)
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 18
            anchors.rightMargin: 14
            anchors.topMargin: 12
            height: deck.y - 20
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    Layout.alignment: Qt.AlignTop

                    Rectangle {
                        anchors.fill: parent
                        radius: 17
                        color: Rock.uiSurface2
                        border.width: Rock.uiBorder
                        border.color: Rock.uiEdge
                    }
                    Image {
                        id: appIcon
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: Notifs.appIconSource(toast.notif)
                        sourceSize: Qt.size(44, 44)
                        smooth: true
                        visible: status === Image.Ready
                    }
                    Lbl {
                        anchors.centerIn: parent
                        visible: appIcon.status !== Image.Ready
                        text: "\uf0f3"
                        color: Rock.pinkDeep
                        font.pixelSize: 15
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Lbl {
                            Layout.fillWidth: true
                            text: toast.notif ? toast.notif.summary : ""
                            color: Rock.uiText
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        Lbl {
                            text: Notifs.timeAgo(toast.notif)
                            color: Rock.a(Rock.uiText, 0.48)
                            font.pixelSize: 9
                        }

                        IconBtn {
                            size: 20
                            icon: "\uf052"
                            iconColor: Rock.uiSub
                            hoverColor: Rock.a(Rock.pink, 0.18)
                            onClicked: Notifs.dismissCurrent()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Lbl {
                            Layout.fillWidth: true
                            text: toast.notif ? (toast.notif.appName || "") : ""
                            color: Rock.pinkDeep
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Item {
                            Layout.preferredWidth: sideLbl.implicitWidth + 8
                            Layout.preferredHeight: 12

                            Rectangle {
                                anchors.fill: parent
                                radius: 3
                                color: Rock.comic ? Rock.a(Rock.yellow, 0.85) : Rock.a(Rock.gold, 0.16)
                                border.width: 1
                                border.color: Rock.comic ? Rock.a(Rock.ink, 0.4) : Rock.a(Rock.gold, 0.65)
                            }
                            Lbl {
                                id: sideLbl
                                anchors.centerIn: parent
                                text: Rock.comic ? "SIDE A" : Rock.marisa ? "SPELL" : "SIGNAL"
                                color: Rock.comic ? Rock.ink : Rock.gold
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }
                        Lbl {
                            visible: Notifs.pending > 0
                            text: "+" + Notifs.pending
                            color: Rock.pinkDeep
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Lbl {
                            visible: toast.critical
                            text: "● REC"
                            color: Rock.orange
                            font.pixelSize: 8
                            font.bold: true
                            SequentialAnimation on opacity {
                                running: toast.critical
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.25; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                }
            }

            Lbl {
                Layout.fillWidth: true
                visible: text !== ""
                text: toast.notif ? String(toast.notif.body).replace(/\s*\n\s*/g, "  ") : ""
                color: Rock.a(Rock.uiText, 0.7)
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: toast.actions.length > 0
                Repeater {
                    model: toast.actions.slice(0, 2)
                    delegate: Rectangle {
                        id: act
                        required property var modelData
                        implicitWidth: actLbl.implicitWidth + 16
                        implicitHeight: 21
                        radius: 5
                        color: actArea.containsMouse ? Qt.lighter(Rock.comic ? Rock.yellow : Rock.uiActive, 1.06)
                                                     : (Rock.comic ? Rock.yellow : Rock.uiActive)
                        border.width: Rock.uiBorder
                        border.color: Rock.uiEdge
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Lbl {
                            id: actLbl
                            anchors.centerIn: parent
                            text: act.modelData.text
                            color: Rock.comic ? Rock.ink : Rock.marisa ? Rock.uiText : Rock.cream
                            font.pixelSize: 9
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
            }
        }

        Rectangle {
            id: deck
            x: 12
            y: shell.height - 74
            width: shell.width - 24
            height: 62
            radius: Rock.comic ? 10 : Rock.marisa ? 4 : 9
            color: Rock.uiSurface2
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge

            Rectangle {
                visible: Rock.comic
                anchors.fill: parent
                anchors.margins: 7
                radius: 7
                color: Rock.ink2
                border.width: 1
                border.color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.18)
            }

            Item {
                id: leftReel
                visible: Rock.comic
                x: 20
                y: (deck.height - height) / 2
                width: 44
                height: 44

                RotationAnimation on rotation {
                    running: toast.notif !== null && !Notifs.hold
                    from: 0
                    to: 360
                    duration: 4200
                    loops: Animation.Infinite
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Rock.uiSurface2
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                }
                Repeater {
                    model: 6
                    delegate: Rectangle {
                        required property int index
                        x: leftReel.width / 2 - width / 2
                        y: leftReel.height / 2
                        width: 3
                        height: leftReel.height / 2 - 7
                        radius: 1.5
                        color: Rock.uiSub
                        transform: Rotation {
                            origin.x: width / 2
                            origin.y: 0
                            angle: index * 60
                        }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    radius: 7.5
                    color: Rock.ink
                    border.width: 2
                    border.color: Rock.pink
                }
            }

            Item {
                id: rightReel
                visible: Rock.comic
                x: deck.width - width - 20
                y: (deck.height - height) / 2
                width: 44
                height: 44

                RotationAnimation on rotation {
                    running: toast.notif !== null && !Notifs.hold
                    from: 0
                    to: 360
                    duration: 5600
                    loops: Animation.Infinite
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Rock.uiSurface2
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                }
                Repeater {
                    model: 6
                    delegate: Rectangle {
                        required property int index
                        x: rightReel.width / 2 - width / 2
                        y: rightReel.height / 2
                        width: 3
                        height: rightReel.height / 2 - 7
                        radius: 1.5
                        color: Rock.uiSub
                        transform: Rotation {
                            origin.x: width / 2
                            origin.y: 0
                            angle: index * 60
                        }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    radius: 7.5
                    color: Rock.ink
                    border.width: 2
                    border.color: Rock.cyan
                }
            }

            Rectangle {
                visible: Rock.comic
                x: leftReel.x + leftReel.width + 12
                y: (deck.height - height) / 2
                width: rightReel.x - x - 12
                height: 16
                radius: 3
                color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.16)
                border.width: 1
                border.color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.22)

                Repeater {
                    model: 9
                    delegate: Rectangle {
                        required property int index
                        x: 6 + index * (parent.width - 12) / 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 8
                        color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.28)
                    }
                }
            }

            Item {
                visible: !Rock.comic
                anchors.fill: parent
                anchors.margins: 8

                Lbl {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: Rock.marisa ? "GRIMOIRE TRANSMISSION" : "ASTRAL TRANSMISSION"
                    color: Rock.a(Rock.gold, 0.9)
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 8
                    font.letterSpacing: 1.1
                }

                Lbl {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: Rock.marisa ? "STARLIT LINK" : "STELLAR LINK"
                    color: Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.42)
                    font.pixelSize: 8
                    font.letterSpacing: 0.8
                }

                Rectangle {
                    id: rail
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 3
                    height: 1
                    color: Rock.a(Rock.gold, 0.55)
                }

                Repeater {
                    model: 7
                    delegate: Rectangle {
                        required property int index
                        x: index * (rail.width - width) / 6
                        y: rail.y - height / 2
                        width: index === 0 || index === 6 ? 8 : 6
                        height: width
                        radius: 1.5
                        rotation: 45
                        color: index === 3 ? Rock.gold : (index % 2 === 0 ? Rock.a(Rock.gold, 0.8) : Rock.a(Rock.marisa ? Rock.uiText : Rock.cream, 0.34))
                        border.width: 1
                        border.color: Rock.a(Rock.gold, 0.75)
                    }
                }

                Rectangle {
                    id: signalPulse
                    y: rail.y - 3
                    width: 6
                    height: 6
                    radius: 3
                    color: Rock.marisa ? Rock.uiText : Rock.cream
                    NumberAnimation on x {
                        running: toast.notif !== null && !Notifs.hold
                        from: 0
                        to: Math.max(0, rail.width - signalPulse.width)
                        duration: 3200
                        loops: Animation.Infinite
                    }
                }

            }
        }
    }
}
