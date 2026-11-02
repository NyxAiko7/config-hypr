import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "right"
    implicitWidth: 420

    readonly property real maxH: (barWindow.screen ? barWindow.screen.height : 900) - 110
    implicitHeight: Math.min(maxH, 64 + (Notifs.count === 0 ? 230 : feed.implicitHeight) + 88)

    // поиск по ленте
    property string query: ""
    readonly property var shownGroups: {
        if (query.trim() === "") return Notifs.groups
        const q = query.toLowerCase()
        const out = []
        for (const g of Notifs.groups) {
            const items = g.items.filter(n =>
                String(n.summary || "").toLowerCase().indexOf(q) >= 0 ||
                String(n.body || "").toLowerCase().indexOf(q) >= 0 ||
                String(n.appName || "").toLowerCase().indexOf(q) >= 0)
            if (items.length > 0) out.push({ app: g.app, items: items })
        }
        return out
    }

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

            // кнопка «Ещё» — меню быстрых действий
            Rectangle {
                id: moreBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: moreArea.containsMouse || moreMenu.visible ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Lbl {
                    anchors.centerIn: parent
                    text: "\uf141"
                    color: Theme.muted
                    font.pixelSize: 13
                }
                MouseArea {
                    id: moreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: moreMenu.visible = !moreMenu.visible
                }
                // меню быстрых действий (свой оверлей поверх контента попапа)
                Item {
                    id: moreMenu
                    visible: false
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    anchors.topMargin: 6
                    z: 100
                    width: menuBg.width
                    height: menuBg.height

                    Rectangle {
                        id: menuBg
                        radius: 14
                        color: Theme.surface
                        border.color: Theme.hairline
                        border.width: 1
                        implicitWidth: menuCol.implicitWidth + 12
                        implicitHeight: menuCol.implicitHeight + 12

                        ColumnLayout {
                            id: menuCol
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: [
                                    { icon: "\uf00d", label: "Очистить все", danger: true },
                                    { icon: "\uf1f6", label: Notifs.dnd ? "Выключить тишину" : "Включить тишину", toggleDnd: true },
                                    { icon: "\uf0a2", label: "Открыть центр уведомлений", center: true },
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 30
                                    radius: 9
                                    color: ma.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8
                                        Lbl { text: modelData.icon; font.pixelSize: 11; color: modelData.danger ? Theme.warn : Theme.muted }
                                        Lbl { Layout.fillWidth: true; text: modelData.label; font.pixelSize: 11; color: modelData.danger ? Theme.warn : Theme.text }
                                    }
                                    MouseArea {
                                        id: ma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            moreMenu.visible = false
                                            if (modelData.danger) Notifs.clearAll()
                                            else if (modelData.toggleDnd) Notifs.dnd = !Notifs.dnd
                                            else if (modelData.center) UI.toggleCenter()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // клик мимо — закрыть
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -2000
                        z: -1
                        enabled: moreMenu.visible
                        onClicked: moreMenu.visible = false
                    }
                }
            }

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

        // ── поиск ──
        Rectangle {
            visible: Notifs.count > 0
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 17
            color: searchField.activeFocus ? Theme.surface : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
            border.width: searchField.activeFocus ? 1 : 0
            border.color: Theme.accent
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8
                Lbl { text: "\uf002"; color: Theme.muted; font.pixelSize: 12 }
                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    color: Theme.text
                    font.pixelSize: 12
                    clip: true
                    selectionColor: Theme.accent
                    text: pop.query
                    onTextChanged: pop.query = text
                    onAccepted: { /* фильтр живой, Enter ничего не делает */ }
                }
                Lbl {
                    visible: pop.query !== ""
                    text: "\uf00d"
                    color: Theme.muted
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { searchField.text = ""; pop.query = "" }
                    }
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
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Notifs.dnd
                    text: "Новые уведомления молча копятся в истории"
                    color: Theme.muted
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
        }

        // ── ничего не найдено ──
        Item {
            visible: Notifs.count > 0 && pop.shownGroups.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            Lbl {
                anchors.centerIn: parent
                text: "Ничего не найдено по «" + pop.query + "»"
                color: Theme.muted
                font.pixelSize: 12
            }
        }

        // ── лента, сгруппирована по приложениям ──
        Flickable {
            id: scroll
            visible: Notifs.count > 0 && pop.shownGroups.length > 0
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
                    model: pop.shownGroups
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

        // ── счётчик в очереди острова ──
        Lbl {
            visible: Notifs.pending > 0
            Layout.alignment: Qt.AlignHCenter
            text: "\uf053  ещё " + Notifs.pending + " в очереди показа"
            color: Theme.muted
            font.pixelSize: 10
            opacity: 0.8
        }
    }
}
