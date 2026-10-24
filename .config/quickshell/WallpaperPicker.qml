import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: UI.wallpaper
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.keyboardFocus: UI.wallpaper ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    property bool browsing: false

    function plural(n) {
        const a = n % 10, b = n % 100
        if (a === 1 && b !== 11) return n + " изображение"
        if (a >= 2 && a <= 4 && (b < 10 || b >= 20)) return n + " изображения"
        return n + " изображений"
    }
    function openBrowse() { browsing = true; Wallpapers.browse(Wallpapers.dir) }

    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
    }

    onVisibleChanged: {
        if (visible) {
            Wallpapers.refresh()
            keys.forceActiveFocus()
            fade.restart()
        } else browsing = false
    }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        MouseArea { anchors.fill: parent; onClicked: UI.wallpaper = false }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: { if (win.browsing) win.browsing = false; else UI.wallpaper = false }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 880)
        height: Math.min(parent.height - 120, 580)
        radius: 24
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.hairline
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ColumnLayout {
                    spacing: 0
                    Lbl { text: "Обои и тема"; font.bold: true; font.pixelSize: 16 }
                    RowLayout {
                        spacing: 6
                        Lbl { text: "\uf07b"; color: Theme.accent; font.pixelSize: 10 }
                        Lbl {
                            Layout.maximumWidth: 460
                            text: Wallpapers.dir
                            color: Theme.muted
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                IconBtn { size: 36; icon: "\uf07b"; iconColor: Theme.accent; onClicked: win.openBrowse() }
                IconBtn { size: 36; icon: "\uf074"; onClicked: Wallpapers.random() }
                IconBtn { size: 36; icon: "\uf00d"; onClicked: UI.wallpaper = false }
            }

            Lbl {
                visible: !win.browsing
                text: "Выбери картинку — цвета панели, уведомлений и терминала подстроятся сами"
                color: Theme.muted
                font.pixelSize: 11
            }

            // ── выбор папки ──
            ColumnLayout {
                visible: win.browsing
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    IconBtn { size: 34; icon: "\uf062"; iconColor: Theme.text; onClicked: Wallpapers.up() }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 17
                        color: Theme.surface
                        Lbl {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            text: Wallpapers.browsePath
                            elide: Text.ElideMiddle
                            font.pixelSize: 11
                        }
                    }
                    Repeater {
                        model: [
                            { t: "Дом",         p: Quickshell.env("HOME") },
                            { t: "Изображения", p: Quickshell.env("HOME") + "/Pictures" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            implicitWidth: chipLbl.implicitWidth + 24
                            implicitHeight: 34
                            radius: 17
                            color: chipArea.containsMouse ? Qt.lighter(Theme.surface, 1.3) : Theme.surface
                            Lbl { id: chipLbl; anchors.centerIn: parent; text: modelData.t; font.pixelSize: 11 }
                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wallpapers.browse(modelData.p)
                            }
                        }
                    }
                }

                ListView {
                    id: dirs
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: Wallpapers.subdirs

                    Lbl {
                        anchors.centerIn: parent
                        visible: dirs.count === 0
                        text: "Вложенных папок нет"
                        color: Theme.muted
                    }

                    delegate: Rectangle {
                        id: dirRow
                        required property string modelData
                        width: dirs.width
                        height: 40
                        radius: 12
                        color: dirArea.containsMouse ? Theme.surface : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12
                            Lbl { text: "\uf07b"; color: Theme.accent2; font.pixelSize: 14 }
                            Lbl { Layout.fillWidth: true; text: dirRow.modelData; elide: Text.ElideRight }
                            Lbl { text: "\uf054"; color: Theme.muted; font.pixelSize: 10 }
                        }
                        MouseArea {
                            id: dirArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.browse(
                                Wallpapers.browsePath === "/" ? "/" + dirRow.modelData
                                                              : Wallpapers.browsePath + "/" + dirRow.modelData)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Lbl {
                        Layout.fillWidth: true
                        text: win.plural(Wallpapers.browseCount) + " в этой папке"
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                    Rectangle {
                        visible: Wallpapers.customDir !== ""
                        implicitWidth: resetLbl.implicitWidth + 28
                        implicitHeight: 36
                        radius: 18
                        color: resetArea.containsMouse ? Theme.surface : "transparent"
                        Lbl { id: resetLbl; anchors.centerIn: parent; text: "По умолчанию"; color: Theme.muted }
                        MouseArea {
                            id: resetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Wallpapers.setDir(""); win.browsing = false }
                        }
                    }
                    Rectangle {
                        implicitWidth: 90
                        implicitHeight: 36
                        radius: 18
                        color: cancelArea.containsMouse ? Theme.surface : "transparent"
                        Lbl { anchors.centerIn: parent; text: "Отмена"; color: Theme.muted }
                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.browsing = false
                        }
                    }
                    Rectangle {
                        implicitWidth: 170
                        implicitHeight: 36
                        radius: 18
                        color: okArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                        Lbl { anchors.centerIn: parent; text: "Выбрать эту папку"; color: Theme.textOnAccent; font.bold: true }
                        MouseArea {
                            id: okArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Wallpapers.setDir(Wallpapers.browsePath); win.browsing = false }
                        }
                    }
                }
            }

            GridView {
                id: grid
                visible: !win.browsing
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                readonly property int cols: Math.max(2, Math.floor(width / 200))
                cellWidth: width / cols
                cellHeight: cellWidth * 0.62
                model: Wallpapers.files

                Lbl {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted
                    text: "Картинки не найдены\nПоложи обои в " + Wallpapers.dir
                }

                delegate: Item {
                    id: cell
                    required property string modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    readonly property bool isCurrent: Wallpapers.current === modelData

                    Item {
                        anchors.fill: parent
                        anchors.margins: 6
                        scale: area.containsMouse ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Rectangle { anchors.fill: parent; color: Theme.surface }
                        Image {
                            anchors.fill: parent
                            source: win.fileUrl(cell.modelData)
                            sourceSize: Qt.size(420, 260)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }
                        RoundMask { anchors.fill: parent; radius: 14; maskColor: Theme.popupBg }
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.width: cell.isCurrent ? 3 : (area.containsMouse ? 2 : 0)
                            border.color: Theme.accent
                        }
                        Rectangle {
                            visible: cell.isCurrent
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            width: 24; height: 24; radius: 12
                            color: Theme.accent
                            Lbl { anchors.centerIn: parent; text: "\uf00c"; color: Theme.textOnAccent; font.pixelSize: 11 }
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.apply(cell.modelData)
                        }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: fade
        NumberAnimation { target: dim;  property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "scale";   from: 0.96; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
