import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "right"
    implicitWidth: 420
    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: Rock.comic ? 22 : Rock.marisa ? 8 : Rock.sao ? 4 : 18

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
                Lbl {
                    text: Rock.comic ? I18n.t("УВЕДОМЛЕНИЯ") : Rock.marisa ? I18n.t("ГРИМУАР ВЕСТЕЙ") : Rock.sao ? I18n.t("СИСТЕМНЫЕ ВЕСТИ") : I18n.t("ПЕРЕДАЧИ")
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 18
                }
                Lbl {
                    text: Notifs.count === 0 ? I18n.t("Всё прочитано") : Notifs.count + I18n.t(" в истории")
                    color: Rock.uiSub
                    opacity: 0.62
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
                color: moreArea.containsMouse || moreMenu.visible ? Rock.a(Rock.pink, 0.18) : "transparent"
                border.width: moreMenu.visible ? 2 : 0
                border.color: Rock.uiEdge
                Behavior on color { ColorAnimation { duration: 120 } }
                Lbl {
                    anchors.centerIn: parent
                    text: "\uf141"
                    color: Rock.uiText
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
                        color: Rock.uiSurface
                        border.color: Rock.uiEdge
                        border.width: Rock.uiBorder
                        implicitWidth: menuCol.implicitWidth + 12
                        implicitHeight: menuCol.implicitHeight + 12

                        ColumnLayout {
                            id: menuCol
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: [
                                    { icon: "\uf00d", label: I18n.t("Очистить все"), danger: true },
                                    { icon: "\uf1f6", label: Notifs.dnd ? I18n.t("Выключить тишину") : I18n.t("Включить тишину"), toggleDnd: true },
                                    { icon: "\uf0a2", label: I18n.t("Открыть центр уведомлений"), center: true },
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 30
                                    radius: 9
                                    color: ma.containsMouse ? Rock.a(Rock.yellow, 0.38) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8
                                        Lbl { text: modelData.icon; font.pixelSize: 11; color: modelData.danger ? Rock.orange : Rock.uiSub }
                                        Lbl { Layout.fillWidth: true; text: modelData.label; font.pixelSize: 11; color: modelData.danger ? Rock.orange : Rock.uiText }
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

            Lbl { text: I18n.t("Тишина"); color: Rock.uiSub; font.pixelSize: 11 }
            Toggle {
                checked: Notifs.dnd
                uncheckedColor: Rock.uiSurface2
                borderColor: Rock.uiEdge
                uncheckedKnob: Rock.uiText
                onToggled: Notifs.dnd = !Notifs.dnd
            }
            Rectangle {
                visible: Notifs.count > 0
                implicitWidth: clearLbl.implicitWidth + 24
                implicitHeight: 28
                radius: 14
                color: clearArea.containsMouse ? Rock.a(Rock.pink, 0.18) : "transparent"
                border.width: Rock.uiBorder
                border.color: Rock.uiEdge
                Behavior on color { ColorAnimation { duration: 120 } }
                Lbl { id: clearLbl; anchors.centerIn: parent; text: I18n.t("Очистить"); color: Rock.pinkDeep; font.pixelSize: 11; font.bold: true }
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
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: searchField.activeFocus ? Rock.uiAccent : Rock.uiEdge
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8
                Lbl { text: "\uf002"; color: Rock.uiSub; font.pixelSize: 12 }
                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    color: Rock.uiText
                    font.family: Theme.font
                    font.pixelSize: 12
                    clip: true
                    selectionColor: Rock.uiAccent
                    selectedTextColor: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                    text: pop.query
                    onTextChanged: pop.query = text
                    onAccepted: { /* фильтр живой, Enter ничего не делает */ }
                }
                Lbl {
                    visible: pop.query !== ""
                    text: "\uf00d"
                    color: Rock.uiSub
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
                    color: Rock.pink
                    font.pixelSize: 38
                    opacity: 0.55
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? I18n.t("Режим «Тишина» включён") : I18n.t("Нет уведомлений")
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 15
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Notifs.dnd
                    text: I18n.t("Новые уведомления молча копятся в истории")
                    color: Rock.uiSub
                    font.pixelSize: 10
                    opacity: 0.65
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
                text: I18n.t("Ничего не найдено по «") + pop.query + "»"
                color: Rock.uiSub
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
                                    color: Rock.pinkDeep
                                    font.pixelSize: 11
                                }
                            }
                            Lbl {
                                Layout.fillWidth: true
                                text: grp.modelData.app + (grp.modelData.items.length > 1 ? "  ·  " + grp.modelData.items.length : "")
                                color: Rock.uiSub
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            IconBtn {
                                size: 24
                                icon: "\uf00d"
                                iconColor: Rock.uiSub
                                hoverColor: Rock.a(Rock.pink, 0.18)
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

        // ── счётчик в очереди показа ──
        Lbl {
            visible: Notifs.pending > 0
            Layout.alignment: Qt.AlignHCenter
            text: I18n.t("\uf053  ещё ") + Notifs.pending + I18n.t(" в очереди показа")
            color: Rock.uiSub
            font.pixelSize: 10
            opacity: 0.65
        }
    }
}
