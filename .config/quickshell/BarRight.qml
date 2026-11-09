import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray

// Правый остров: трей, VPN, обои, раскладка, статус, уведомления.
BarIsland {
    id: rightIsland
    fill: Rock.marisa ? Rock.barFill : Rock.ink2
    shadowColor: Rock.cyan
    tilt: 0.8

    property var barWindow: null
    property var sink: Pipewire.defaultAudioSink
    property var bat: UPower.displayDevice
    property var btAdapter: Bluetooth.defaultAdapter

    // якоря для попапов, которые живут в Bar.qml
    readonly property Item statusAnchor: statusPill
    readonly property Item bellAnchor: bellPill
    signal controlCenterToggleRequested()
    signal notifCenterToggleRequested()

    function volIcon() {
        if (!rightIsland.sink || !rightIsland.sink.audio || rightIsland.sink.audio.muted) return "\uf026"
        const v = rightIsland.sink.audio.volume
        return v < 0.01 ? "\uf026" : (v < 0.5 ? "\uf027" : "\uf028")
    }
    // потребление/зарядка в ваттах ("" если данных нет)
    function watts() {
        const w = Math.abs(rightIsland.bat.changeRate)
        return w >= 0.5 ? w.toFixed(1) + I18n.t(" Вт") : ""
    }
    function batIcon() {
        if (rightIsland.bat.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(rightIsland.bat.percentage * 5))]
    }
    // цвет заряда: критично / мало / зарядка / нормально
    function batColor() {
        if (rightIsland.bat.state === UPowerDeviceState.Charging) return Rock.cyan
        if (rightIsland.bat.percentage < 0.1) return Rock.pink
        if (rightIsland.bat.percentage < 0.2) return Rock.pink
        return Rock.marisa ? Rock.barText : Rock.cream
    }

    // Трей
    Pill {
        visible: SystemTray.items.values.length > 0
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                required property var modelData
                Layout.preferredWidth: 15
                Layout.preferredHeight: 15

                Image {
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                    sourceSize: Qt.size(30, 30)
                    smooth: true
                }

                TrayMenu {
                    id: trayMenu
                    barWindow: rightIsland.barWindow
                    anchorItem: trayItem
                    handle: trayItem.modelData.menu
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        const it = trayItem.modelData
                        if (mouse.button === Qt.MiddleButton) it.secondaryActivate()
                        else if (mouse.button === Qt.RightButton || it.onlyMenu) { if (it.hasMenu) trayMenu.toggle() }
                        else it.activate()
                    }
                }
            }
        }
    }

    // VPN: виден, пока включён (клик — выключить, если профиль в NetworkManager)
    Pill {
        visible: Net.vpn
        interactive: Net.vpnManaged
        onClicked: Net.toggleVpn()
        Lbl { text: "\uf132"; color: Rock.cyan; font.pixelSize: Theme.iconSize }
        Lbl {
            Layout.maximumWidth: 90
            text: Net.vpnName
            color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    // Обои и тема
    Pill {
        interactive: true
        onClicked: { UI.launcher = false; UI.session = false; UI.wallpaper = !UI.wallpaper }
        Lbl { text: "\uf1fc"; color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55); font.pixelSize: Theme.iconSize }
    }

    // Раскладка клавиатуры
    Pill {
        interactive: true
        onClicked: Kb.next()
        Lbl {
            text: Kb.layout
            color: Rock.marisa ? Rock.barText : Rock.cream
            font.family: Rock.display
            font.weight: Font.Black
            font.pixelSize: 11
        }
    }

    // Статус → центр управления
    Pill {
        id: statusPill
        interactive: true
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (rightIsland.sink && rightIsland.sink.audio) rightIsland.sink.audio.muted = !rightIsland.sink.audio.muted
            } else rightIsland.controlCenterToggleRequested()
        }
        onScrolled: wheel => {
            if (rightIsland.sink && rightIsland.sink.audio)
                rightIsland.sink.audio.volume = Math.max(0, Math.min(1.0,
                    rightIsland.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
        }

        Lbl {
            visible: UI.caffeine
            text: "\uf0f4"
            color: Rock.yellow
            font.pixelSize: Theme.iconSize
        }
        Lbl {
            visible: Quick.night
            text: "\uf186"
            color: Rock.purple
            font.pixelSize: Theme.iconSize
        }
        Lbl {
            text: Net.icon
            color: Net.connected ? Rock.marisa ? Rock.barText : Rock.cream : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.4)
            font.pixelSize: Theme.iconSize
        }
        Lbl {
            visible: rightIsland.btAdapter !== null
            text: "\uf293"
            color: Bt.connected.length > 0 ? Rock.cyan
                 : (rightIsland.btAdapter && rightIsland.btAdapter.enabled ? Rock.marisa ? Rock.barText : Rock.cream : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.4))
            font.pixelSize: Theme.iconSize
        }
        Lbl {
            text: rightIsland.volIcon()
            color: (rightIsland.sink && rightIsland.sink.audio && rightIsland.sink.audio.muted) ? Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.4) : Rock.marisa ? Rock.barText : Rock.cream
            font.pixelSize: Theme.iconSize
        }
        RowLayout {
            visible: rightIsland.bat.isLaptopBattery
            spacing: 5
            Lbl {
                text: rightIsland.batIcon()
                color: rightIsland.bat.percentage < 0.2 ? Rock.pink : Rock.marisa ? Rock.barText : Rock.cream
                font.pixelSize: Theme.iconSize
            }
            Lbl {
                text: Math.round(rightIsland.bat.percentage * 100)
                color: Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
            }
            Lbl {
                visible: text !== ""
                text: rightIsland.watts()
                color: rightIsland.bat.state === UPowerDeviceState.Charging ? Rock.cyan : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.55)
                font.pixelSize: 10
            }
        }
    }

    // Уведомления → центр уведомлений
    Pill {
        id: bellPill
        interactive: true
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd
            else if (mouse.button === Qt.MiddleButton) Notifs.clearAll()
            else rightIsland.notifCenterToggleRequested()
        }
        Lbl {
            text: Notifs.dnd ? "\uf1f6" : "\uf0f3"
            color: Notifs.dnd ? Rock.pink : (Notifs.count > 0 ? Rock.yellow : Rock.a(Rock.marisa ? Rock.barText : Rock.cream, 0.45))
            font.pixelSize: Theme.iconSize
        }
        Lbl {
            visible: Notifs.count > 0
            text: Notifs.count
            color: Rock.yellow
            font.bold: true
        }
    }
}
