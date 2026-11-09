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
        property color valueColor: Rock.uiText
        implicitHeight: 56
        radius: 14
        color: Rock.uiSurface2
        border.width: Rock.uiBorder
        border.color: Rock.uiEdge
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                Lbl { text: ms.icon; color: Rock.cyan; font.pixelSize: 11 }
                Lbl { text: ms.value; color: ms.valueColor; font.bold: true; font.pixelSize: 13 }
            }
            Lbl { Layout.alignment: Qt.AlignHCenter; text: ms.label; color: Rock.uiSub; font.pixelSize: 9 }
        }
    }

    // строка «подпись — значение»
    readonly property string statusLine: {
        const parts = []
        if (Net.connectivity === "limited") parts.push(I18n.t("Нет доступа в интернет"))
        else if (Net.connectivity === "portal") parts.push(I18n.t("Нужна авторизация"))
        else parts.push(I18n.t("Подключено"))
        if (Net.kind === "wifi") {
            if (Net.band !== "") parts.push(Net.band)
            if (Net.security !== "") parts.push(Net.security)
        } else if (Net.kind === "ethernet") parts.push(I18n.t("Кабель"))
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
            IconBtn { icon: "\uf053"; iconColor: Rock.uiSub; onClicked: page.back() }
            Lbl {
                Layout.fillWidth: true
                text: "Wi-Fi"
                color: Rock.uiText
                font.family: Rock.display
                font.weight: Font.Black
                font.pixelSize: 16
                font.letterSpacing: 0.4
            }
            IconBtn { icon: "\uf021"; spin: Net.scanning; iconColor: Rock.uiSub; hoverColor: Rock.a(Rock.uiText, 0.12); onClicked: Net.scan() }
            Toggle {
                checked: Net.wifiEnabled
                uncheckedColor: Rock.uiSurface2
                borderColor: Rock.uiEdge
                uncheckedKnob: Rock.uiText
                onToggled: Net.toggleWifi()
            }
        }

        // ошибка подключения
        Rectangle {
            visible: Net.lastError !== ""
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 12
            color: Qt.rgba(Rock.orange.r, Rock.orange.g, Rock.orange.b, 0.16)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                Lbl { Layout.fillWidth: true; text: Net.lastError; color: Rock.orange; font.pixelSize: 11; elide: Text.ElideRight }
                IconBtn { size: 24; icon: "\uf00d"; iconColor: Rock.orange; onClicked: Net.lastError = "" }
            }
        }

        // ── текущее соединение: самое главное ──
        Item {
            visible: Net.connected && (Net.kind === "ethernet" || Net.wifiEnabled)
            Layout.fillWidth: true
            implicitHeight: connCard.height + 6

            Rectangle {
                visible: Rock.comic
                x: 4
                y: 5
                width: connCard.width
                height: connCard.height
                radius: 18
                color: Rock.pink
                border.width: Rock.uiBorder
                border.color: Rock.uiEdge
            }

            Rectangle {
                id: connCard
                width: parent.width - 4
                height: info.implicitHeight + 24
                radius: Rock.comic ? 18 : Rock.marisa ? 7 : Rock.sao ? 4 : 13
                color: Rock.uiSurface2
                border.width: Rock.uiBorder
                border.color: Rock.uiEdge

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
                        color: Qt.rgba(Rock.pink.r, Rock.pink.g, Rock.pink.b, 0.18)
                        Lbl { anchors.centerIn: parent; text: Net.icon; color: Rock.pink; font.pixelSize: 17 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 0
                        Lbl { Layout.fillWidth: true; text: Net.connection; color: Rock.uiText; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight }
                        Lbl {
                            Layout.fillWidth: true
                            text: page.statusLine
                            color: Net.connectivity === "limited" || Net.connectivity === "portal" ? Rock.orange : Rock.uiSub
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
                        color: Qt.rgba(Rock.cyan.r, Rock.cyan.g, Rock.cyan.b, 0.16)
                        Lbl { id: sigLbl; anchors.centerIn: parent; text: Net.strength + "%"; color: Rock.cyan; font.pixelSize: 11; font.bold: true }
                    }
                }

                // скорость в реальном времени и пинг
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    MiniStat {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        icon: "\uf063"; label: I18n.t("Приём")
                        value: Net.fmtRate(Net.rxRate)
                    }
                    MiniStat {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        icon: "\uf062"; label: I18n.t("Отдача")
                        value: Net.fmtRate(Net.txRate)
                    }
                    MiniStat {
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        icon: "\uf012"; label: I18n.t("Пинг")
                        value: Net.latency >= 0 ? Net.latency + I18n.t(" мс") : "—"
                        valueColor: Net.latency < 0 ? Rock.orange : (Net.latency > 150 ? Rock.orange : Rock.uiText)
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
                        color: ipArea.containsMouse ? Qt.rgba(Rock.uiText.r, Rock.uiText.g, Rock.uiText.b, 0.08)
                                                    : Qt.rgba(Rock.uiText.r, Rock.uiText.g, Rock.uiText.b, 0.04)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8
                            Lbl { text: "IP"; color: Rock.uiSub; font.pixelSize: 10 }
                            Lbl { Layout.fillWidth: true; text: Net.ip !== "" ? Net.ip : "—"; color: Rock.uiText; font.pixelSize: 11; elide: Text.ElideRight }
                            Lbl { text: "\uf0c5"; color: Rock.uiSub; font.pixelSize: 10 }
                        }
                        MouseArea {
                            id: ipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Net.copyIp()
                                UI.flash("\uf0c5", I18n.t("IP скопирован"), Net.ip, "", "info", "")
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 32
                        radius: 12
                        color: Qt.rgba(Rock.uiText.r, Rock.uiText.g, Rock.uiText.b, 0.04)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8
                            Lbl { text: I18n.t("Канал"); color: Rock.uiSub; font.pixelSize: 10 }
                            Lbl { Layout.fillWidth: true; text: Net.linkSpeed !== "" ? Net.linkSpeed : "—"; color: Rock.uiText; font.pixelSize: 11; elide: Text.ElideRight }
                        }
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
                Lbl { Layout.alignment: Qt.AlignHCenter; text: "\uf1eb"; color: Rock.uiSub; font.pixelSize: 30; opacity: 0.5 }
                Lbl { Layout.alignment: Qt.AlignHCenter; text: I18n.t("Wi-Fi выключен"); color: Rock.uiSub }
            }
        }

        Lbl {
            visible: Net.wifiEnabled
            text: I18n.t("ДОСТУПНЫЕ СЕТИ")
            color: Rock.uiSub
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
                text: Net.scanning ? I18n.t("Поиск сетей…") : I18n.t("Сети не найдены")
                color: Rock.uiSub
            }

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool busy: Net.connecting === modelData.ssid
                width: list.width
                height: 56
                radius: 14
                color: row.modelData.inUse
                       ? (rowArea.containsMouse ? Qt.lighter(Rock.comic ? Rock.yellow : Rock.uiActive, 1.06)
                                                : (Rock.comic ? Rock.yellow : Rock.uiActive))
                       : (rowArea.containsMouse ? Rock.uiHover : Rock.uiSurface2)
                border.width: Rock.uiBorder
                border.color: Rock.uiEdge
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
                        color: row.modelData.inUse ? Rock.pink : Rock.uiText
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
                            color: row.modelData.inUse || row.busy ? Rock.pink : Rock.uiSub
                            text: (row.busy ? I18n.t("Подключение…")
                                 : row.modelData.inUse ? I18n.t("Подключено")
                                 : row.modelData.saved ? I18n.t("Сохранена")
                                 : (row.modelData.secured ? I18n.t("Защищена") : I18n.t("Открытая")))
                                + "  ·  " + row.modelData.signal + "%"
                        }
                    }
                    Lbl {
                        visible: row.modelData.secured
                        text: "\uf023"
                        color: Rock.uiSub
                        font.pixelSize: 11
                    }
                    IconBtn {
                        visible: row.modelData.inUse
                        size: 30
                        icon: "\uf127"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(Rock.uiText, 0.12)
                        onClicked: Net.disconnectCurrent()
                    }
                    IconBtn {
                        visible: row.modelData.saved
                        size: 30
                        icon: "\uf1f8"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(Rock.uiText, 0.12)
                        onClicked: Net.forget(row.modelData.ssid)
                    }
                }
            }
        }
    }
}
