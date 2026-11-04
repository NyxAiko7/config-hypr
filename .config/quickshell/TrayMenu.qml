import QtQuick
import QtQuick.Layouts
import Quickshell

// Контекстное меню иконки трея (DBusMenu) в стиле панели
BarPopup {
    id: pop
    alignment: "right"

    property var handle: null          // QsMenuHandle иконки
    property var current: handle
    property var stack: []

    implicitWidth: 240
    implicitHeight: Math.min(480, list.contentHeight + 16 + (stack.length > 0 ? 36 : 0))

    onVisibleChanged: if (!visible) { stack = []; current = handle }

    QsMenuOpener { id: opener; menu: pop.current }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        Rectangle {
            visible: pop.stack.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 10
            color: backArea.containsMouse ? Theme.surface : "transparent"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 8
                Lbl { text: "\uf053"; color: Theme.muted; font.pixelSize: 10 }
                Lbl { text: "Назад"; color: Theme.muted }
            }
            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const s = pop.stack.slice()
                    pop.current = s.pop()
                    pop.stack = s
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            model: opener.children

            delegate: Item {
                id: entry
                required property var modelData
                width: list.width
                height: modelData.isSeparator ? 9 : 34

                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 16
                    height: 1
                    color: Theme.hairline
                }

                Rectangle {
                    visible: !entry.modelData.isSeparator
                    anchors.fill: parent
                    radius: 10
                    color: (area.containsMouse && entry.modelData.enabled) ? Theme.surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Lbl {
                            visible: entry.modelData.buttonType !== 0
                            Layout.preferredWidth: 14
                            text: entry.modelData.checkState === Qt.Checked ? "\uf00c" : ""
                            color: Theme.accent
                            font.pixelSize: 11
                        }
                        Lbl {
                            Layout.fillWidth: true
                            text: String(entry.modelData.text).replace(/_([^_])/g, "$1")
                            color: entry.modelData.enabled ? Theme.text : Theme.muted
                            elide: Text.ElideRight
                        }
                        Lbl {
                            visible: entry.modelData.hasChildren
                            text: "\uf054"
                            color: Theme.muted
                            font.pixelSize: 10
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entry.modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (entry.modelData.hasChildren) {
                                const s = pop.stack.slice()
                                s.push(pop.current)
                                pop.stack = s
                                pop.current = entry.modelData
                            } else {
                                entry.modelData.triggered()
                                pop.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
