import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: page
    property bool active: false
    signal back()

    // маленький показатель: значок, значение, подпись
    component MiniStat: Rectangle {
        id: ms
        property string icon
        property string value
        property string label
        property color valueColor: Theme.text
        implicitHeight: 56
        radius: 14
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                Lbl { text: ms.icon; color: Theme.accent2; font.pixelSize: 11 }
                Lbl { text: ms.value; color: ms.valueColor; font.bold: true; font.pixelSize: 13 }
            }
            Lbl { Layout.alignment: Qt.AlignHCenter; text: ms.label; color: Theme.muted; font.pixelSize: 9 }
        }
    }

    // строка «подпись — значение»
    readonly property string statusLine: {
        const parts = []
        if (Net.connectivity === "limited") parts.push("Нет доступа в интернет")
        else if (Net.connectivity === "portal") parts.push("Нужна авторизация")
        else parts.push("Подключено")
        if (Net.kind === "wifi") {
            if (Net.band !== "") parts.push(Net.band)
            if (Net.security !== "") parts.push(Net.security)
        } else if (Net.kind === "ethernet") parts.push("Кабель")
        return parts.join("  ·  ")
    }

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

        // ── текущее соединение: самое главное ──
        Rectangle {
            visible: Net.connected && (Net.kind === "ethernet" || Net.wifiEnabled)
            Layout.fillWidth: true
            implicitHeight: info.implicitHeight + 24
            radius: 18
            color: Theme.surface

            ColumnLayout {
                id: info
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        Lbl { anchors.centerIn: parent; text: Net.icon; color: Theme.accent; font.pixelSize: 17 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 0
                        Lbl { Layout.fillWidth: true; text: Net.connection; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight }
                        Lbl {
                            Layout.fillWidth: true
                            text: page.statusLine
                            color: Net.connectivity === "limited" || Net.connectivity === "portal" ? Theme.warn : Theme.muted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                    // уровень сигнала
                    Rectangle {
                        visible: Net.kind === "wifi"
                        implicitWidth: sigLbl.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.16)
                        Lbl { id: sigLbl; anchors.centerIn: parent; text: Net.strength + "%"; color: Theme.accent2; font.pixelSize: 11; font.bold: true }
                    }
                }

                // скорость в реальном времени и пинг
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    MiniStat {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        icon: "\uf063"; label: "Приём"
                        value: Net.fmtRate(Net.rxRate)
                    }
                    MiniStat {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        icon: "\uf062"; label: "Отдача"
                        value: Net.fmtRate(Net.txRate)
                    }
                    MiniStat {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        icon: "\uf012"; label: "Пинг"
                        value: Net.latency >= 0 ? Net.latency + " мс" : "—"
                        valueColor: Net.latency < 0 ? Theme.warn : (Net.latency > 150 ? Theme.warn : Theme.text)
                    }
                }

                // IP (клик — скопировать) и скорость канала
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 32
                        radius: 12
                        color: ipArea.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                                                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8
                            Lbl { text: "IP"; color: Theme.muted; font.pixelSize: 10 }
                            Lbl { Layout.fillWidth: true; text: Net.ip !== "" ? Net.ip : "—"; font.pixelSize: 11; elide: Text.ElideRight }
                            Lbl { text: "\uf0c5"; color: Theme.muted; font.pixelSize: 10 }
                        }
                        MouseArea {
                            id: ipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Net.copyIp()
                                UI.flash("\uf0c5", "IP скопирован", Net.ip, "", "info", "")
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 32
                        radius: 12
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8
                            Lbl { text: "Канал"; color: Theme.muted; font.pixelSize: 10 }
                            Lbl { Layout.fillWidth: true; text: Net.linkSpeed !== "" ? Net.linkSpeed : "—"; font.pixelSize: 11; elide: Text.ElideRight }
                        }
                    }
                }
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

        Lbl {
            visible: Net.wifiEnabled
            text: "ДОСТУПНЫЕ СЕТИ"
            color: Theme.muted
            font.pixelSize: 10
            Layout.leftMargin: 6
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
