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
    radius: 16
    color: hoverArea.containsMouse ? Qt.lighter(Theme.surface, 1.15) : Theme.surface
    border.width: critical ? 1 : 0
    border.color: Theme.warn
    Behavior on color { ColorAnimation { duration: 120 } }

    // клик: выполнить действие по умолчанию и закрыть
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Notifs.defaultAction(card.notif) ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            const d = Notifs.defaultAction(card.notif)
            if (d) { d.invoke(); card.notif.dismiss() }
        }
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
                Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) }
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
                    color: Theme.accent
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
                    Lbl {
                        Layout.fillWidth: true
                        text: card.notif.summary
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Lbl { text: Notifs.timeAgo(card.notif); color: Theme.muted; font.pixelSize: 10 }
                    IconBtn {
                        size: 22
                        icon: "\uf00d"
                        onClicked: card.notif.dismiss()
                    }
                }
                Lbl {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notif.body
                    color: Theme.text
                    opacity: 0.8
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
                    color: actArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Lbl { id: actLbl; anchors.centerIn: parent; text: act.modelData.text; color: Theme.textOnAccent; font.pixelSize: 11; font.bold: true }
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
