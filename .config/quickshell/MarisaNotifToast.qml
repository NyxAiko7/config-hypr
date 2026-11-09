import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: toast

    property var notif: null
    property real ttlFrac: 1
    property real slide: 0

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property var actions: Notifs.actionList(notif)

    implicitWidth: 408
    implicitHeight: 190

    Connections {
        target: Notifs
        function onKeyChanged() {
            dropIn.restart()
            lifeAnim.restart()
        }
    }

    NumberAnimation {
        id: dropIn
        target: toast
        property: "slide"
        from: 120
        to: 0
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
        x: 5
        y: 6
        width: page.width
        height: page.height
        radius: 7
        rotation: 0.9
        color: Rock.a(Rock.ink, 0.28)
    }

    Rectangle {
        id: page
        width: toast.width - 8
        height: toast.height - 9
        radius: 7
        color: Rock.uiSurface
        border.width: 2
        border.color: Rock.uiEdge
        clip: true

        MarisaPattern {
            anchors.fill: parent
            opacity: 0.42
        }

        MarisaTrim {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 6
            height: 3
            cell: 3
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 7
            height: 1
            color: Rock.a(Rock.gold, 0.4)
        }

        Item {
            width: 22
            height: 22
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: 9

            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 16
                radius: 2
                rotation: 45
                color: closeArea.containsMouse ? Rock.a(Rock.orange, 0.18) : "transparent"
                border.width: 1
                border.color: Rock.a(Rock.orange, closeArea.containsMouse ? 0.8 : 0.35)
            }
            Lbl {
                anchors.centerIn: parent
                text: "\uf00d"
                color: closeArea.containsMouse ? Rock.orange : Rock.uiSub
                font.pixelSize: 8
            }
            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.dismissCurrent()
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.rightMargin: 34
            anchors.topMargin: 14
            spacing: 11

            Item {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: Rock.uiSurface2
                    border.width: 1.5
                    border.color: Rock.a(Rock.gold, 0.75)
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    radius: 4
                    rotation: 45
                    color: "transparent"
                    border.width: 1
                    border.color: Rock.a(Rock.gold, 0.28)
                }
                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: Notifs.appIconSource(toast.notif)
                    sourceSize: Qt.size(48, 48)
                    smooth: true
                    visible: status === Image.Ready
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: appIcon.status !== Image.Ready
                    text: "\uf0f3"
                    color: Rock.pinkDeep
                    font.pixelSize: 16
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Lbl {
                        text: I18n.t("ВЕСТЬ")
                        color: Rock.a(Rock.uiSub, 0.9)
                        font.family: Rock.display
                        font.pixelSize: 7
                        font.letterSpacing: 1.8
                        font.bold: true
                    }
                    Rectangle {
                        width: 14
                        height: 1
                        color: Rock.a(Rock.gold, 0.6)
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: toast.notif ? String(toast.notif.appName || "").toUpperCase() : ""
                        color: Rock.pinkDeep
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                    }
                    Lbl {
                        text: Notifs.timeAgo(toast.notif)
                        color: Rock.a(Rock.uiText, 0.45)
                        font.pixelSize: 8
                    }
                }

                Lbl {
                    Layout.fillWidth: true
                    text: toast.notif ? toast.notif.summary : ""
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }

                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: toast.notif ? String(toast.notif.body).replace(/\s*\n\s*/g, "  ") : ""
                    color: Rock.a(Rock.uiText, 0.72)
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 16
            spacing: 6

            Rectangle {
                width: 4
                height: 4
                radius: 1
                rotation: 45
                color: toast.critical ? Rock.orange : Rock.gold
            }

            Lbl {
                text: toast.critical ? I18n.t("ПЕЧАТЬ ТРЕВОГИ") : I18n.t("ПЕЧАТЬ МАРИСЫ")
                color: toast.critical ? Rock.orange : Rock.a(Rock.uiSub, 0.8)
                font.pixelSize: 7
                font.letterSpacing: 1
            }

            Item { Layout.fillWidth: true }

            Repeater {
                model: toast.actions.slice(0, 2)
                delegate: Rectangle {
                    id: act
                    required property var modelData
                    implicitWidth: actLbl.implicitWidth + 18
                    implicitHeight: 20
                    radius: 3
                    color: actArea.containsMouse ? Rock.a(Rock.gold, 0.22) : Rock.a(Rock.uiSurface2, 0.6)
                    border.width: 1
                    border.color: Rock.a(Rock.gold, actArea.containsMouse ? 0.9 : 0.5)

                    Lbl {
                        id: actLbl
                        anchors.centerIn: parent
                        text: "✦ " + act.modelData.text
                        color: Rock.uiText
                        font.pixelSize: 8
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

            Rectangle {
                width: pendingLbl.implicitWidth + 12
                height: 20
                visible: Notifs.pending > 0
                radius: 3
                color: Rock.a(Rock.pink, 0.16)
                border.width: 1
                border.color: Rock.a(Rock.pinkDeep, 0.6)

                Lbl {
                    id: pendingLbl
                    anchors.centerIn: parent
                    text: "+" + Notifs.pending + I18n.t(" В ОЧЕРЕДИ")
                    color: Rock.pinkDeep
                    font.pixelSize: 7
                    font.bold: true
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            height: 3
            color: Rock.a(Rock.gold, 0.16)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, toast.ttlFrac))
                height: parent.height
                color: toast.critical ? Rock.orange : Rock.gold
            }
        }
    }

    Rectangle {
        x: -1
        y: 26
        width: 5
        height: 54
        radius: 2.5
        color: Rock.pink

        Rectangle {
            anchors.centerIn: parent
            width: 9
            height: 9
            radius: 1.8
            color: Rock.pink
            rotation: 45
            border.width: 1.5
            border.color: Rock.uiEdge
        }
    }
}
