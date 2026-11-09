import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

Item {
    id: page
    property bool active: false
    signal back()

    readonly property var adapter: Bluetooth.defaultAdapter

    function macLike(n) { return /^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(n) }
    function iconFor(d) {
        const i = String(d.icon || "")
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "\uf025"
        if (i.indexOf("keyboard") >= 0) return "\uf11c"
        if (i.indexOf("mouse") >= 0) return "\uf245"
        if (i.indexOf("phone") >= 0) return "\uf10b"
        if (i.indexOf("gaming") >= 0) return "\uf11b"
        if (i.indexOf("speaker") >= 0 || i.indexOf("audio") >= 0) return "\uf028"
        return "\uf293"
    }

    readonly property var devices: {
        const list = Bluetooth.devices.values.filter(d => d.paired || d.connected || !macLike(d.name || ""))
        return list.slice().sort((a, b) =>
            (b.connected - a.connected) || (b.paired - a.paired)
            || String(a.name).localeCompare(String(b.name)))
    }

    function syncDiscovery() {
        if (adapter) adapter.discovering = active && adapter.enabled
    }
    onActiveChanged: syncDiscovery()
    Connections {
        target: page.adapter
        function onEnabledChanged() { page.syncDiscovery() }
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
                text: "Bluetooth"
                color: Rock.uiText
                font.family: Rock.display
                font.weight: Font.Black
                font.pixelSize: 16
                font.letterSpacing: 0.4
            }
            IconBtn {
                visible: page.adapter !== null && page.adapter.enabled
                icon: "\uf021"
                spin: page.adapter ? page.adapter.discovering : false
                iconColor: Rock.uiSub
                hoverColor: Rock.a(Rock.uiText, 0.12)
                onClicked: if (page.adapter) page.adapter.discovering = !page.adapter.discovering
            }
            Toggle {
                visible: page.adapter !== null
                checked: page.adapter ? page.adapter.enabled : false
                uncheckedColor: Rock.uiSurface2
                borderColor: Rock.uiEdge
                uncheckedKnob: Rock.uiText
                onToggled: if (page.adapter) page.adapter.enabled = !page.adapter.enabled
            }
        }

        Item {
            visible: page.adapter === null || !page.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                Lbl { Layout.alignment: Qt.AlignHCenter; text: "\uf293"; color: Rock.uiSub; font.pixelSize: 30; opacity: 0.5 }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    color: Rock.uiSub
                    text: page.adapter === null ? I18n.t("Bluetooth-адаптер не найден") : I18n.t("Bluetooth выключен")
                }
            }
        }

        ListView {
            id: list
            visible: page.adapter !== null && page.adapter.enabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: page.devices

            Lbl {
                anchors.centerIn: parent
                visible: list.count === 0
                text: (page.adapter && page.adapter.discovering) ? I18n.t("Поиск устройств…") : I18n.t("Устройства не найдены")
                color: Rock.uiSub
            }

            delegate: Rectangle {
                id: row
                required property var modelData
                property bool wantConnect: false
                readonly property bool connecting: modelData.state === 3
                width: list.width
                height: 56
                radius: 14
                color: row.modelData.connected
                       ? (rowArea.containsMouse ? Qt.lighter(Rock.comic ? Rock.yellow : Rock.uiActive, 1.06)
                                                : (Rock.comic ? Rock.yellow : Rock.uiActive))
                       : (rowArea.containsMouse ? Rock.uiHover : Rock.uiSurface2)
                border.width: Rock.uiBorder
                border.color: Rock.uiEdge
                Behavior on color { ColorAnimation { duration: 120 } }

                // после сопряжения сразу подключаемся
                Connections {
                    target: row.modelData
                    function onPairedChanged() {
                        if (row.modelData.paired && row.wantConnect) {
                            row.modelData.trusted = true
                            row.modelData.connect()
                            row.wantConnect = false
                        }
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const d = row.modelData
                        if (row.connecting) return
                        if (d.connected) d.disconnect()
                        else if (d.paired) d.connect()
                        else { row.wantConnect = true; d.pair() }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 12

                    Lbl {
                        Layout.preferredWidth: 22
                        horizontalAlignment: Text.AlignHCenter
                        text: page.iconFor(row.modelData)
                        color: row.modelData.connected ? Rock.pink : Rock.uiText
                        font.pixelSize: 16
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Lbl {
                            Layout.fillWidth: true
                            text: row.modelData.name || row.modelData.deviceName || row.modelData.address
                            color: Rock.uiText
                            font.bold: row.modelData.connected
                            elide: Text.ElideRight
                        }
                        Lbl {
                            Layout.fillWidth: true
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            color: (row.modelData.connected || row.connecting) ? Rock.pink : Rock.uiSub
                            text: row.connecting ? I18n.t("Подключение…")
                                : row.modelData.pairing ? I18n.t("Сопряжение…")
                                : row.modelData.connected
                                    ? (I18n.t("Подключено") + (row.modelData.batteryAvailable ? "  ·  " + Bt.percent(row.modelData) + "%" : ""))
                                : row.modelData.paired ? I18n.t("Сопряжено")
                                : I18n.t("Доступно — нажми для сопряжения")
                        }
                    }
                    IconBtn {
                        visible: row.modelData.paired
                        size: 30
                        icon: "\uf1f8"
                        iconColor: Rock.uiSub
                        hoverColor: Rock.a(Rock.uiText, 0.12)
                        onClicked: row.modelData.forget()
                    }
                }
            }
        }
    }
}
