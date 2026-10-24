import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: page
    property bool active: false
    signal back()

    onActiveChanged: {
        Net.wantList = active
        if (active) Net.scan()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconBtn { icon: "\uf053"; iconColor: Theme.text; onClicked: page.back() }
            Lbl { Layout.fillWidth: true; text: "Wi-Fi"; font.bold: true; font.pixelSize: 15 }
            IconBtn { icon: "\uf021"; spin: Net.scanning; onClicked: Net.scan() }
            Toggle { checked: Net.wifiEnabled; onToggled: Net.toggleWifi() }
        }

        // ошибка подключения
        Rectangle {
            visible: Net.lastError !== ""
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 12
            color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.16)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                Lbl { Layout.fillWidth: true; text: Net.lastError; color: Theme.warn; font.pixelSize: 11; elide: Text.ElideRight }
                IconBtn { size: 24; icon: "\uf00d"; iconColor: Theme.warn; onClicked: Net.lastError = "" }
            }
        }

        // Wi-Fi выключен
        Item {
            visible: !Net.wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                Lbl { Layout.alignment: Qt.AlignHCenter; text: "\uf1eb"; color: Theme.muted; font.pixelSize: 30; opacity: 0.5 }
                Lbl { Layout.alignment: Qt.AlignHCenter; text: "Wi-Fi выключен"; color: Theme.muted }
            }
        }

        ListView {
            id: list
            visible: Net.wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: Net.networks

            Lbl {
                anchors.centerIn: parent
                visible: list.count === 0
                text: Net.scanning ? "Поиск сетей…" : "Сети не найдены"
                color: Theme.muted
            }

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool busy: Net.connecting === modelData.ssid
                width: list.width
                height: 56
                radius: 14
                color: rowArea.containsMouse ? Theme.surface : "transparent"
                border.width: modelData.inUse ? 1 : 0
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.modelData.inUse || row.busy) return
                        if (row.modelData.saved || !row.modelData.secured)
                            Net.connectTo(row.modelData.ssid, "")
                        else
                            UI.wifiSsid = row.modelData.ssid      // запрос пароля
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 12

                    Lbl {
                        Layout.preferredWidth: 22
                        text: "\uf1eb"
                        color: row.modelData.inUse ? Theme.accent : Theme.text
                        font.pixelSize: 16
                        opacity: row.modelData.signal >= 75 ? 1 : (row.modelData.signal >= 50 ? 0.8 : (row.modelData.signal >= 25 ? 0.55 : 0.35))
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Lbl {
                            Layout.fillWidth: true
                            text: row.modelData.ssid
                            font.bold: row.modelData.inUse
                            elide: Text.ElideRight
                        }
                        Lbl {
                            Layout.fillWidth: true
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            color: row.modelData.inUse || row.busy ? Theme.accent : Theme.muted
                            text: (row.busy ? "Подключение…"
                                 : row.modelData.inUse ? "Подключено"
                                 : row.modelData.saved ? "Сохранена"
                                 : (row.modelData.secured ? "Защищена" : "Открытая"))
                                + "  ·  " + row.modelData.signal + "%"
                        }
                    }
                    Lbl {
                        visible: row.modelData.secured
                        text: "\uf023"
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                    IconBtn {
                        visible: row.modelData.inUse
                        size: 30
                        icon: "\uf127"
                        onClicked: Net.disconnectCurrent()
                    }
                    IconBtn {
                        visible: row.modelData.saved
                        size: 30
                        icon: "\uf1f8"
                        onClicked: Net.forget(row.modelData.ssid)
                    }
                }
            }
        }
    }
}
