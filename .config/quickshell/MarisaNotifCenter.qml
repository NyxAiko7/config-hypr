import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "right"

    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: 8

    implicitWidth: 440
    readonly property real maxH: (barWindow.screen ? barWindow.screen.height : 900) - 110
    implicitHeight: Math.min(maxH, 70 + (Notifs.count === 0 ? 236 : feed.implicitHeight) + 84)

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

    component StarBtn: Item {
        id: sb
        property string icon: "\uf00d"
        property bool danger: false
        signal activated()
        implicitWidth: 24
        implicitHeight: 24
        Rectangle {
            anchors.fill: parent
            radius: 4
            rotation: 45
            color: sbArea.containsMouse ? Rock.a(sb.danger ? Rock.orange : Rock.gold, 0.16) : "transparent"
            border.width: 1
            border.color: Rock.a(sb.danger ? Rock.orange : Rock.gold, 0.4)
            Behavior on color { ColorAnimation { duration: 110 } }
        }
        Lbl {
            anchors.centerIn: parent
            text: sb.icon
            color: sb.danger ? Rock.orange : Rock.uiSub
            font.pixelSize: 9
        }
        MouseArea {
            id: sbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.activated()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 11

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MarisaHat {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 22
            }

            ColumnLayout {
                spacing: -1
                Lbl {
                    text: I18n.t("ГРИМУАР ВЕСТЕЙ")
                    color: Rock.uiText
                    font.family: Rock.display
                    font.pixelSize: 17
                    font.bold: true
                    font.letterSpacing: 0.4
                }
                Lbl {
                    text: Notifs.count === 0 ? I18n.t("страницы чисты") : Notifs.count + I18n.t(" записей на страницах")
                    color: Rock.a(Rock.uiSub, 0.85)
                    font.pixelSize: 9
                    font.italic: true
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: dndRow.implicitWidth + 18
                implicitHeight: 26
                radius: 4
                color: Notifs.dnd ? Rock.a(Rock.pink, 0.16) : "transparent"
                border.width: 1
                border.color: Notifs.dnd ? Rock.pinkDeep : Rock.a(Rock.uiEdge, 0.5)
                RowLayout {
                    id: dndRow
                    anchors.centerIn: parent
                    spacing: 5
                    Lbl {
                        text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                        color: Notifs.dnd ? Rock.pinkDeep : Rock.uiSub
                        font.pixelSize: 10
                    }
                    Lbl {
                        text: I18n.t("ТИШИНА")
                        color: Notifs.dnd ? Rock.pinkDeep : Rock.uiSub
                        font.pixelSize: 7
                        font.letterSpacing: 0.8
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
            }

            StarBtn {
                icon: "\uf00d"
                danger: true
                visible: Notifs.count > 0
                onActivated: Notifs.clearAll()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Rock.a(Rock.uiEdge, 0.4)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Notifs.count > 0
            spacing: 8
            Lbl {
                text: "\uf002"
                color: Rock.a(Rock.uiSub, 0.8)
                font.pixelSize: 11
            }
            TextInput {
                id: searchField
                Layout.fillWidth: true
                color: Rock.uiText
                font.family: Rock.mono
                font.pixelSize: 11
                clip: true
                selectionColor: Rock.uiAccent
                selectedTextColor: Rock.cream
                text: pop.query
                onTextChanged: pop.query = text
                Lbl {
                    visible: searchField.text === ""
                    text: I18n.t("поиск по свиткам…")
                    color: Rock.a(Rock.uiText, 0.4)
                    font.family: Rock.mono
                    font.pixelSize: 11
                }
            }
            Lbl {
                visible: pop.query !== ""
                text: "✕"
                color: Rock.uiSub
                font.pixelSize: 10
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { searchField.text = ""; pop.query = "" }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Notifs.count > 0
            height: 1
            color: Rock.a(Rock.gold, 0.45)
        }

        Item {
            visible: Notifs.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? "\uf1f6" : "☾"
                    color: Rock.a(Rock.gold, 0.7)
                    font.pixelSize: 42
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: Notifs.dnd ? I18n.t("Тишина в гримуаре") : I18n.t("Страницы пусты")
                    color: Rock.uiText
                    font.family: Rock.display
                    font.pixelSize: 15
                    font.bold: true
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Notifs.dnd
                    text: I18n.t("Весты молча ждут своей очереди")
                    color: Rock.a(Rock.uiSub, 0.8)
                    font.pixelSize: 9
                    font.italic: true
                }
            }
        }

        Item {
            visible: Notifs.count > 0 && pop.shownGroups.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            Lbl {
                anchors.centerIn: parent
                text: I18n.t("Ни одной вести по «") + pop.query + "»"
                color: Rock.a(Rock.uiSub, 0.8)
                font.pixelSize: 11
                font.italic: true
            }
        }

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
                spacing: 13

                Repeater {
                    model: pop.shownGroups
                    delegate: ColumnLayout {
                        id: grp
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 7

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
                                    text: "✦"
                                    color: Rock.gold
                                    font.pixelSize: 11
                                }
                            }
                            Lbl {
                                Layout.fillWidth: true
                                text: grp.modelData.app.toUpperCase()
                                color: Rock.a(Rock.uiSub, 0.9)
                                font.family: Rock.display
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.2
                                elide: Text.ElideRight
                            }
                            Lbl {
                                visible: grp.modelData.items.length > 1
                                text: grp.modelData.items.length
                                color: Rock.a(Rock.gold, 0.85)
                                font.pixelSize: 8
                            }
                            StarBtn {
                                icon: "\uf00d"
                                onActivated: {
                                    const items = grp.modelData.items.slice()
                                    for (let i = 0; i < items.length; i++) items[i].dismiss()
                                }
                            }
                        }

                        Repeater {
                            model: grp.modelData.items
                            delegate: Rectangle {
                                id: card
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: cardCol.implicitHeight + 20
                                radius: 4
                                color: hoverArea.containsMouse ? Rock.uiHover : Rock.uiSurface
                                border.width: 1
                                border.color: hoverArea.containsMouse ? Rock.a(Rock.gold, 0.7) : Rock.a(Rock.uiEdge, 0.65)
                                Behavior on color { ColorAnimation { duration: 110 } }

                                Rectangle {
                                    width: 3
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 5
                                    color: Rock.a(Rock.gold, 0.7)
                                }

                                ColumnLayout {
                                    id: cardCol
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 9
                                    anchors.topMargin: 9
                                    anchors.bottomMargin: 8
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 7

                                        Lbl {
                                            text: "✦"
                                            color: Rock.gold
                                            font.pixelSize: 9
                                        }
                                        Lbl {
                                            Layout.fillWidth: true
                                            text: card.modelData.summary
                                            color: Rock.uiText
                                            font.family: Rock.display
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Lbl {
                                            text: Notifs.timeAgo(card.modelData)
                                            color: Rock.a(Rock.uiSub, 0.8)
                                            font.pixelSize: 8
                                            font.italic: true
                                        }
                                        StarBtn {
                                            implicitWidth: 20
                                            implicitHeight: 20
                                            onActivated: card.modelData.dismiss()
                                        }
                                    }

                                    Lbl {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: card.modelData.body
                                        color: Rock.a(Rock.uiText, 0.82)
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 4
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        visible: Notifs.actionList(card.modelData).length > 0
                                        Repeater {
                                            model: Notifs.actionList(card.modelData)
                                            delegate: Rectangle {
                                                id: act
                                                required property var modelData
                                                implicitWidth: actLbl.implicitWidth + 20
                                                implicitHeight: 22
                                                radius: 3
                                                color: actArea.containsMouse ? Rock.a(Rock.gold, 0.22) : Rock.a(Rock.gold, 0.12)
                                                border.width: 1
                                                border.color: Rock.a(Rock.gold, 0.5)
                                                Lbl {
                                                    id: actLbl
                                                    anchors.centerIn: parent
                                                    text: act.modelData.text
                                                    color: Rock.uiText
                                                    font.pixelSize: 9
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

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Notifs.defaultAction(card.modelData) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        const d = Notifs.defaultAction(card.modelData)
                                        if (d) { d.invoke(); card.modelData.dismiss() }
                                    }
                                }
                                z: -1
                            }
                        }
                    }
                }
            }
        }

        Lbl {
            visible: Notifs.pending > 0
            Layout.alignment: Qt.AlignHCenter
            text: I18n.t("✦ ещё ") + Notifs.pending + I18n.t(" ждут своего часа")
            color: Rock.a(Rock.uiSub, 0.75)
            font.pixelSize: 8
            font.italic: true
        }
    }
}
