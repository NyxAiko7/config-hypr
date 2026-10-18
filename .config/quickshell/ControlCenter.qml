import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

BarPopup {
    id: cc
    alignment: "right"
    implicitWidth: 340
    implicitHeight: content.implicitHeight + 32

    property var sink: Pipewire.defaultAudioSink
    property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btConnectedDevices: Bluetooth.devices.values.filter(d => d.connected)

    PwObjectTracker { objects: [cc.sink] }

    onVisibleChanged: {
        SysStats.active = visible
        if (visible) { Brightness.refresh(); Net.refresh() }
    }

    function volIcon() {
        if (!sink || !sink.audio || sink.audio.muted) return "\uf6a9"
        const v = sink.audio.volume
        return v < 0.01 ? "\uf026" : (v < 0.5 ? "\uf027" : "\uf028")
    }

    // ── Плитка ──
    component Tile: Rectangle {
        id: tile
        property string icon
        property string title
        property string subtitle
        property bool active: false
        signal clicked()
        signal rightClicked()

        implicitHeight: 54
        radius: 14
        color: active ? (tileArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
                      : (tileArea.containsMouse ? Qt.lighter(Theme.surface, 1.2) : Theme.surface)
        Behavior on color { ColorAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 10
            Lbl {
                text: tile.icon
                color: tile.active ? Theme.textOnAccent : Theme.text
                font.pixelSize: 16
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Lbl {
                    Layout.fillWidth: true
                    text: tile.title
                    font.bold: true
                    color: tile.active ? Theme.textOnAccent : Theme.text
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: tile.subtitle
                    font.pixelSize: 10
                    color: tile.active ? Theme.textOnAccent : Theme.muted
                    opacity: tile.active ? 0.7 : 1
                    elide: Text.ElideRight
                }
            }
        }
        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
        }
    }

    // ── Тонкий ползунок ──
    component Slide: Item {
        id: sl
        property string icon
        property real value: 0
        signal moved(real v)
        implicitHeight: 26

        RowLayout {
            anchors.fill: parent
            spacing: 12
            Lbl {
                text: sl.icon
                color: Theme.muted
                font.pixelSize: Theme.iconSize
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 4; radius: 2
                    color: Theme.surface
                    Rectangle {
                        width: parent.width * sl.value
                        height: parent.height; radius: 2
                        color: Theme.accent
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, parent.width * sl.value - width / 2))
                        width: 12; height: 12; radius: 6
                        color: Theme.text
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: m => sl.moved(Math.max(0, Math.min(1, m.x / width)))
                    onPositionChanged: m => sl.moved(Math.max(0, Math.min(1, m.x / width)))
                }
            }
            Lbl {
                text: Math.round(sl.value * 100)
                color: Theme.muted
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // ── Строка статистики ──
    component Stat: RowLayout {
        property string label
        property int value: 0
        spacing: 12
        Lbl {
            text: parent.label
            color: Theme.muted
            font.pixelSize: 10
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
        }
        Rectangle {
            Layout.fillWidth: true
            height: 4; radius: 2
            color: Theme.surface
            Rectangle {
                width: parent.width * Math.min(1, parent.parent.value / 100)
                height: parent.height; radius: 2
                color: parent.parent.value > 85 ? Theme.warn : Theme.accent2
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
        Lbl {
            text: parent.value
            color: Theme.muted
            Layout.preferredWidth: 26
            horizontalAlignment: Text.AlignRight
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                spacing: 0
                Lbl { text: Quickshell.env("USER"); font.bold: true; font.pixelSize: 14 }
                Lbl {
                    visible: UPower.displayDevice.isLaptopBattery
                    color: Theme.muted
                    font.pixelSize: 11
                    text: Math.round(UPower.displayDevice.percentage * 100) + "% · "
                        + (UPower.displayDevice.state === UPowerDeviceState.Charging ? "заряжается" : "от батареи")
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 34; implicitHeight: 34; radius: 17
                color: pwrArea.containsMouse ? Theme.surface : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Lbl { anchors.centerIn: parent; text: "\uf011"; color: Theme.muted; font.pixelSize: 14 }
                MouseArea {
                    id: pwrArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { cc.visible = false; UI.launcher = false; UI.session = true }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Tile {
                Layout.fillWidth: true
                icon: Net.icon
                title: Net.kind === "ethernet" ? "Ethernet" : "Wi-Fi"
                subtitle: Net.connected ? Net.connection : (Net.wifiEnabled ? "Не подключено" : "Выключено")
                active: Net.wifiEnabled || Net.kind === "ethernet"
                onClicked: Net.toggleWifi()
                onRightClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
            Tile {
                Layout.fillWidth: true
                icon: "\uf293"
                title: "Bluetooth"
                subtitle: !cc.btAdapter ? "Недоступно"
                    : (cc.btAdapter.enabled
                        ? (cc.btConnectedDevices.length > 0
                            ? cc.btConnectedDevices.map(d => d.name || d.deviceName).join(", ")
                            : "Включён")
                        : "Выключен")
                active: cc.btAdapter ? cc.btAdapter.enabled : false
                onClicked: if (cc.btAdapter) cc.btAdapter.enabled = !cc.btAdapter.enabled
                onRightClicked: Quickshell.execDetached(["blueman-manager"])
            }
            Tile {
                Layout.fillWidth: true
                icon: SwayNC.dnd ? "\uf1f6" : "\uf0f3"
                title: "Не беспокоить"
                subtitle: SwayNC.dnd ? "Включено" : "Выключено"
                active: SwayNC.dnd
                onClicked: SwayNC.toggleDnd()
                onRightClicked: SwayNC.toggle()
            }
            Tile {
                Layout.fillWidth: true
                icon: cc.volIcon()
                title: "Звук"
                subtitle: (cc.sink && cc.sink.audio && !cc.sink.audio.muted) ? "Включён" : "Выключен"
                active: cc.sink && cc.sink.audio ? !cc.sink.audio.muted : false
                onClicked: if (cc.sink && cc.sink.audio) cc.sink.audio.muted = !cc.sink.audio.muted
                onRightClicked: Quickshell.execDetached(["pavucontrol"])
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Slide {
                Layout.fillWidth: true
                icon: cc.volIcon()
                value: (cc.sink && cc.sink.audio) ? cc.sink.audio.volume : 0
                onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v }
            }
            Slide {
                Layout.fillWidth: true
                visible: Brightness.available
                icon: "\uf185"
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Stat { Layout.fillWidth: true; label: "CPU"; value: SysStats.cpu }
            Stat { Layout.fillWidth: true; label: "RAM"; value: SysStats.mem }
        }
    }
}
