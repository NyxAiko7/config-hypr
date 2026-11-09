import QtQuick
import QtQuick.Layouts
import Quickshell

// Системное меню Aincrad: двухпанельный терминал LINK START.
// Слева — проиндексированные цели, справа — карточка выбранной цели.
Item {
    id: root

    property string query: ""
    readonly property string mode: UI.launcherMode
    readonly property var results: mode === "clip" ? Clip.search(query)
                                   : (mode === "windows" ? Wins.search(query)
                                                         : Apps.search(query))
    readonly property int currentIndex: resultList.currentIndex
    readonly property int resultCount: results.length
    readonly property var picked: results.length > 0
        ? results[Math.max(0, Math.min(currentIndex, results.length - 1))]
        : null

    implicitWidth: 556
    implicitHeight: content.implicitHeight + 20

    function modeLabel(m) {
        if (m === "clip") return I18n.t("АРХИВ")
        if (m === "windows") return I18n.t("ОКНА")
        return I18n.t("ЗАПУСК")
    }

    function setMode(m) {
        if (UI.launcherMode === m) return
        UI.launcherMode = m
        if (m === "clip") Clip.reload()
        query = ""
        resultList.currentIndex = 0
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function launch(e) {
        if (!e) return
        UI.launcher = false
        if (e.kind === "clip") Clip.paste(e)
        else if (e.kind === "window") Wins.focus(e)
        else Apps.launch(e)
    }

    onVisibleChanged: {
        if (!visible) return
        if (mode === "clip") Clip.reload()
        resultList.currentIndex = 0
        query = ""
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    SaoGrid {
        anchors.fill: parent
        step: 28
        animated: root.visible
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        // ───── заголовок системы ─────
        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Rectangle {
                    anchors.centerIn: parent
                    width: 15; height: 15; radius: 1; rotation: 45
                    color: Rock.a(Rock.gold, 0.18)
                    border.width: 1
                    border.color: Rock.gold
                }
                Lbl {
                    anchors.centerIn: parent
                    text: "\uf303"
                    color: Rock.gold
                    font.pixelSize: 8
                }
            }

            ColumnLayout {
                spacing: -2
                Lbl {
                    text: "AINCRAD SYSTEM MENU"
                    color: Rock.uiText
                    font.family: Rock.display
                    font.weight: Font.Black
                    font.pixelSize: 16
                    font.letterSpacing: 1.6
                }
                Lbl {
                    text: "LINK START · TARGET INDEX // " + root.modeLabel(root.mode)
                    color: Rock.a(Rock.gold, 0.8)
                    font.pixelSize: 8
                    font.letterSpacing: 1.4
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: statusRow.implicitWidth + 16
                implicitHeight: 21
                radius: 2
                color: Rock.a(Rock.gold, 0.12)
                border.width: 1
                border.color: Rock.a(Rock.gold, 0.55)
                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 5
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.resultCount > 0 ? Rock.hp : Rock.danger
                        SequentialAnimation on opacity {
                            running: root.visible
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 700 }
                            NumberAnimation { to: 1.0; duration: 700 }
                        }
                    }
                    Lbl {
                        text: "SIGNAL"
                        color: Rock.gold
                        font.pixelSize: 7
                        font.weight: Font.Black
                        font.letterSpacing: 1
                    }
                }
            }
        }

        // ───── переключатель режимов ─────
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: [
                    { key: "apps", label: I18n.t("ЗАПУСК"), glyph: "\uf303" },
                    { key: "windows", label: I18n.t("ОКНА"), glyph: "\uf2d0" },
                    { key: "clip", label: I18n.t("АРХИВ"), glyph: "\uf0ea" }
                ]
                delegate: Rectangle {
                    id: tab
                    required property var modelData
                    readonly property bool active: root.mode === tab.modelData.key

                    Layout.fillWidth: true
                    implicitHeight: 25
                    radius: 2
                    color: tab.active ? Rock.a(Rock.gold, 0.17)
                                      : (tabArea.containsMouse ? Rock.a(Rock.gold, 0.08) : "transparent")
                    border.width: 1
                    border.color: tab.active ? Rock.gold : Rock.a(Rock.uiText, 0.16)

                    Rectangle {
                        visible: tab.active
                        width: 3
                        height: parent.height - 8
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Rock.gold
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Lbl {
                            text: tab.modelData.glyph
                            color: tab.active ? Rock.gold : Rock.a(Rock.uiText, 0.45)
                            font.pixelSize: 8
                        }
                        Lbl {
                            text: tab.modelData.label
                            color: tab.active ? Rock.uiText : Rock.a(Rock.uiText, 0.55)
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 8
                            font.letterSpacing: 1
                        }
                    }

                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setMode(tab.modelData.key)
                    }
                }
            }
        }

        // ───── поле ввода ─────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 3
            color: Rock.a(Rock.uiSurface2, 0.85)
            border.width: 1
            border.color: searchInput.activeFocus ? Rock.gold : Rock.a(Rock.gold, 0.4)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 30
                color: Rock.a(Rock.gold, 0.10)
                Text {
                    anchors.centerIn: parent
                    text: ">_"
                    color: Rock.gold
                    font.family: Rock.mono
                    font.pixelSize: 11
                }
            }

            TextInput {
                id: searchInput
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Rock.uiText
                font.family: Rock.mono
                font.pixelSize: 13
                selectionColor: Rock.uiAccent
                selectedTextColor: Rock.ink
                selectByMouse: true
                clip: true
                onTextChanged: {
                    root.query = text
                    resultList.currentIndex = 0
                }

                Lbl {
                    visible: searchInput.text === ""
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.mode === "clip" ? I18n.t("Открыть архив данных…")
                        : root.mode === "windows" ? I18n.t("Выбрать окно…")
                        : I18n.t("Имя приложения, 2+2, ? поиск, > команда")
                    color: Rock.a(Rock.uiText, 0.38)
                    font.pixelSize: 12
                }

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier
                    const n = root.results.length
                    if (event.key === Qt.Key_Escape) {
                        UI.launcher = false; event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                               || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                        if (n > 0) resultList.currentIndex = Math.min(n - 1, resultList.currentIndex + 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                               || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                        if (n > 0) resultList.currentIndex = Math.max(0, resultList.currentIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Delete && root.mode === "windows") {
                        const e = root.picked
                        if (e) { Wins.close(e); UI.launcher = false }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (n > 0) root.launch(root.picked)
                        event.accepted = true
                    }
                }
            }
        }

        // ───── список целей + карточка ─────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 360
                Layout.preferredHeight: 252
                radius: 3
                color: Rock.a(Rock.ink, 0.35)
                border.width: 1
                border.color: Rock.a(Rock.gold, 0.22)
                clip: true

                ListView {
                    id: resultList
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    model: root.results
                    currentIndex: 0
                    interactive: count > 5
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 70
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem

                        width: resultList.width
                        height: 44
                        radius: 2
                        color: row.current ? Rock.a(Rock.gold, 0.14)
                                           : (rowArea.containsMouse ? Rock.a(Rock.gold, 0.06) : "transparent")
                        border.width: row.current ? 1 : 0
                        border.color: Rock.a(Rock.gold, 0.5)

                        Rectangle {
                            visible: row.current
                            width: 5; height: 5; radius: 1; rotation: 45
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Rock.gold
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: row.current ? 22 : 14
                            anchors.rightMargin: 9
                            spacing: 8

                            Lbl {
                                Layout.preferredWidth: 30
                                text: "00x" + ("0" + (row.index + 1)).slice(-2)
                                color: row.current ? Rock.gold : Rock.a(Rock.uiText, 0.32)
                                font.family: Rock.mono
                                font.pixelSize: 7
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 2
                                color: "transparent"
                                border.width: 1
                                border.color: row.current ? Rock.gold : Rock.a(Rock.uiText, 0.2)

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon) : ""
                                    sourceSize: Qt.size(40, 40)
                                    smooth: true
                                    visible: status === Image.Ready
                                }
                                Lbl {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.glyph && !row.modelData.icon
                                    text: row.modelData.glyph || ""
                                    color: row.current ? Rock.gold : Rock.a(Rock.uiText, 0.6)
                                    font.pixelSize: 11
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -2
                                Lbl {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    color: Rock.uiText
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Lbl {
                                    Layout.fillWidth: true
                                    text: row.modelData.comment || row.modelData.genericName || ""
                                    color: Rock.a(Rock.uiText, 0.45)
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                            }

                            Lbl {
                                visible: row.current
                                text: "LINK"
                                color: Rock.gold
                                font.pixelSize: 7
                                font.weight: Font.Black
                                font.letterSpacing: 1
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: resultList.currentIndex = row.index
                            onClicked: root.launch(row.modelData)
                        }
                    }
                }

                Lbl {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: I18n.t("ЦЕЛИ НЕ ОБНАРУЖЕНЫ")
                    color: Rock.a(Rock.uiText, 0.35)
                    font.pixelSize: 9
                    font.letterSpacing: 1.4
                }
            }

            // карточка выбранной цели
            Rectangle {
                Layout.preferredWidth: 176
                Layout.preferredHeight: 252
                radius: 3
                color: Rock.a(Rock.uiSurface2, 0.75)
                border.width: 1
                border.color: Rock.a(Rock.gold, 0.32)

                SaoFrame {
                    anchors.fill: parent
                    inset: 3
                    cut: 8
                    segments: 9
                    corner: 10
                    lineColor: Rock.a(Rock.gold, 0.22)
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 7

                    Lbl {
                        text: "TARGET DATA"
                        color: Rock.a(Rock.gold, 0.75)
                        font.pixelSize: 7
                        font.weight: Font.Black
                        font.letterSpacing: 1.6
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        Rectangle {
                            anchors.centerIn: parent
                            width: 54; height: 54; radius: 2; rotation: 45
                            color: Rock.a(Rock.gold, 0.08)
                            border.width: 1
                            border.color: Rock.a(Rock.gold, 0.55)
                        }
                        Image {
                            anchors.centerIn: parent
                            width: 38; height: 38
                            source: root.picked && root.picked.icon ? Quickshell.iconPath(root.picked.icon) : ""
                            sourceSize: Qt.size(64, 64)
                            smooth: true
                            visible: status === Image.Ready
                        }
                        Lbl {
                            anchors.centerIn: parent
                            visible: !root.picked || !root.picked.icon
                            text: root.picked && root.picked.glyph ? root.picked.glyph : "\uf128"
                            color: Rock.gold
                            font.pixelSize: 20
                        }
                    }

                    Lbl {
                        Layout.fillWidth: true
                        text: root.picked ? root.picked.name : "—"
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    Lbl {
                        Layout.fillWidth: true
                        text: root.picked ? (root.picked.comment || root.picked.genericName || "") : ""
                        color: Rock.a(Rock.uiText, 0.45)
                        font.pixelSize: 8
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 26
                        radius: 2
                        color: connectArea.containsMouse ? Rock.gold : Rock.a(Rock.gold, 0.16)
                        border.width: 1
                        border.color: Rock.gold

                        Lbl {
                            anchors.centerIn: parent
                            text: root.mode === "clip" ? I18n.t("ИЗВЛЕЧЬ") : root.mode === "windows" ? I18n.t("ПЕРЕЙТИ") : I18n.t("ЗАПУСТИТЬ")
                            color: connectArea.containsMouse ? Rock.ink : Rock.gold
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 8
                            font.letterSpacing: 1
                        }

                        MouseArea {
                            id: connectArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.picked !== null
                            onClicked: root.launch(root.picked)
                        }
                    }
                }
            }
        }

        // ───── нижняя строка статуса ─────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Rock.a(Rock.gold, 0.22)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Lbl { text: "↑↓"; color: Rock.gold; font.pixelSize: 8; font.weight: Font.Black }
            Lbl { text: I18n.t("ВЫБОР"); color: Rock.a(Rock.uiText, 0.45); font.pixelSize: 8; font.letterSpacing: 0.8 }
            Item { Layout.fillWidth: true }
            Lbl { text: "↵"; color: Rock.gold; font.pixelSize: 8; font.weight: Font.Black }
            Lbl { text: "CONNECT"; color: Rock.a(Rock.uiText, 0.45); font.pixelSize: 8; font.letterSpacing: 0.8 }
            Lbl { text: "·"; color: Rock.a(Rock.uiText, 0.25); font.pixelSize: 8 }
            Lbl { text: "ESC"; color: Rock.gold; font.pixelSize: 8; font.weight: Font.Black }
            Lbl { text: "LOGOUT"; color: Rock.a(Rock.uiText, 0.45); font.pixelSize: 8; font.letterSpacing: 0.8 }
        }
    }
}
