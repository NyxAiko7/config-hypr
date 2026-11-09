import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

// Карточка в центре уведомлений
Rectangle {
    id: card

    required property var notif
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical

    implicitHeight: col.implicitHeight + 24
    radius: Rock.comic ? 14 : Rock.marisa ? 7 : 10
    color: hoverArea.containsMouse ? Rock.uiHover : Rock.uiSurface
    border.width: critical ? Rock.uiBorder + 1 : Rock.uiBorder
    border.color: critical ? Rock.orange : Rock.uiEdge
    Behavior on color { ColorAnimation { duration: 120 } }

    // клик: действие по умолчанию; свайп влево: закрыть
    property real swipeX: 0
    Behavior on swipeX { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    x: card.swipeX
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Notifs.defaultAction(card.notif) ? Qt.PointingHandCursor : Qt.ArrowCursor
        drag.target: card
        drag.axis: Drag.XAxis
        drag.minimumX: -card.width * 0.6
        drag.maximumX: 0
        drag.threshold: 8
        onPressed: card.swipeX = 0
        onReleased: {
            if (card.x < -card.width * 0.35) { card.notif.dismiss(); return }
            card.swipeX = 0
        }
        onClicked: {
            if (Math.abs(card.x) > 4) return          // это был свайп, не клик
            const d = Notifs.defaultAction(card.notif)
            if (d) { d.invoke(); card.notif.dismiss() }
        }
    }
    // подсказка «смахни» на фоне карточки
    Lbl {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: I18n.t("\uf060  закрыть")
        color: Rock.orange
        font.pixelSize: 11
        font.bold: true
        opacity: Math.min(1, Math.abs(card.swipeX) / (card.width * 0.35))
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignTop
                Rectangle {
                    anchors.fill: parent
                    color: Rock.uiSurface2
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                }
                Image {
                    id: img
                    anchors.fill: parent
                    source: Notifs.contentImage(card.notif) !== "" ? Notifs.contentImage(card.notif)
                                                                   : Notifs.appIconSource(card.notif)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: !img.visible
                    text: "\uf0f3"
                    color: Rock.pinkDeep
                    font.pixelSize: 15
                }
                RoundMask { anchors.fill: parent; radius: 12; maskColor: card.color }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: cardTag.implicitWidth + 8
                        implicitHeight: 14
                        radius: 3
                        color: Rock.comic ? Rock.a(Rock.yellow, 0.85) : Rock.a(Rock.gold, 0.16)
                        border.width: 1
                        border.color: Rock.comic ? Rock.a(Rock.ink, 0.4) : Rock.a(Rock.gold, 0.65)
                        Lbl {
                            id: cardTag
                            anchors.centerIn: parent
                            text: Rock.comic ? "SIDE A" : Rock.marisa ? "SPELL" : "SIGNAL"
                            color: Rock.comic ? Rock.ink : Rock.gold
                            font.pixelSize: 7
                            font.bold: true
                            font.letterSpacing: 0.6
                        }
                    }

                    Lbl {
                        Layout.fillWidth: true
                        text: card.notif.summary
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                    Lbl { text: Notifs.timeAgo(card.notif); color: Rock.uiSub; opacity: 0.6; font.pixelSize: 10 }
                    IconBtn {
                        size: 22
                        icon: "\uf00d"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(Rock.pink, 0.18)
                        onClicked: card.notif.dismiss()
                    }
                }
                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notif.body
                    color: Rock.uiText
                    opacity: 0.78
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Notifs.actionList(card.notif).length > 0
            Repeater {
                model: Notifs.actionList(card.notif)
                delegate: Rectangle {
                    id: act
                    required property var modelData
                    implicitWidth: actLbl.implicitWidth + 24
                    implicitHeight: 28
                    radius: 14
                    color: actArea.containsMouse ? Qt.lighter(Rock.comic ? Rock.yellow : Rock.uiActive, 1.06)
                                                 : (Rock.comic ? Rock.yellow : Rock.uiActive)
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Lbl {
                        id: actLbl
                        anchors.centerIn: parent
                        text: act.modelData.text
                        color: Rock.uiText
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: act.modelData.invoke()
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
