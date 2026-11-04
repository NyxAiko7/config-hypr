import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "right"
    implicitWidth: 420

    readonly property real maxH: (barWindow.screen ? barWindow.screen.height : 900) - 110
    implicitHeight: Math.min(maxH, 64 + (Notifs.count === 0 ? 190 : feed.implicitHeight) + 32)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── шапка ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                spacing: 0
                Lbl { text: "Уведомления"; font.bold: true; font.pixelSize: 15 }
                Lbl {
                    text: Notifs.count === 0 ? "Всё прочитано" : Notifs.count + " в истории"
                    color: Theme.muted
                    font.pixelSize: 10
                }
            }
            Item { Layout.fillWidth: true }
            Lbl { text: "Тишина"; color: Theme.muted; font.pixelSize: 11 }
            Toggle { checked: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
            Rectangle {
                visible: Notifs.count > 0
                implicitWidth: clearLbl.implicitWidth + 24
                implicitHeight: 28
                radius: 14
                color: clearArea.containsMouse ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Lbl { id: clearLbl; anchors.centerIn: parent; text: "Очистить"; color: Theme.accent; font.pixelSize: 11 }
                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }
        }

        // ── пусто ──
        Item {
            visible: Notifs.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                    color: Theme.muted
                    font.pixelSize: 34
                    opacity: 0.45
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? "Режим «Тишина» включён" : "Нет уведомлений"
                    color: Theme.muted
                }
            }
        }

        // ── лента, сгруппирована по приложениям ──
        Flickable {
            id: scroll
            visible: Notifs.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: feed.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: feed
                width: scroll.width
                spacing: 14

                Repeater {
                    model: Notifs.groups
                    delegate: ColumnLayout {
                        id: grp
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Item {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Image {
                                    id: gIcon
                                    anchors.fill: parent
                                    source: Notifs.appIconSource(grp.modelData.items[0])
                                    sourceSize: Qt.size(32, 32)
                                    visible: status === Image.Ready
                                }
                                Lbl {
                                    anchors.centerIn: parent
                                    visible: !gIcon.visible
                                    text: "\uf0f3"
                                    color: Theme.accent
                                    font.pixelSize: 11
                                }
                            }
                            Lbl {
                                Layout.fillWidth: true
                                text: grp.modelData.app + (grp.modelData.items.length > 1 ? "  ·  " + grp.modelData.items.length : "")
                                color: Theme.muted
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            IconBtn {
                                size: 24
                                icon: "\uf00d"
                                onClicked: {
                                    const items = grp.modelData.items.slice()
                                    for (let i = 0; i < items.length; i++) items[i].dismiss()
                                }
                            }
                        }

                        Repeater {
                            model: grp.modelData.items
                            delegate: NotifCard {
                                required property var modelData
                                Layout.fillWidth: true
                                notif: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
