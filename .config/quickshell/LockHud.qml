import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// Верхняя полоса телеметрии в стиле «Обсерватория».
RowLayout {
    id: hud

    property real enterProgress: 0
    property int batPct: -1
    property bool charging: false
    property bool lockDirty: false

    height: 28
    spacing: 18
    opacity: enterProgress
    transform: Translate { y: (1 - hud.enterProgress) * -14 }

    component Tag: Row {
        property string icon: ""
        property string label: ""
        property color tint: Theme.text
        spacing: 6
        Lbl { text: icon; color: tint; font.pixelSize: 12; opacity: 0.9 }
        Lbl { text: label; color: Rock.a(Theme.text, 0.8); font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1.1 }
    }

    Row {
        spacing: 10
        Layout.alignment: Qt.AlignVCenter
        Rectangle {
            width: 7; height: 7; radius: 3.5
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent2
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 0.2; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Lbl {
            text: I18n.t("СЕАНС ЗАБЛОКИРОВАН")
            color: Rock.a(Theme.text, 0.85)
            font.family: Theme.font
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 2.4
        }
        Rectangle { width: 40; height: 1; color: Rock.a(Theme.accent, 0.35); anchors.verticalCenter: parent.verticalCenter }
        Lbl {
            text: Quickshell.env("USER") + "@" + (Quickshell.env("HOSTNAME") || "host")
            color: Rock.a(Theme.text, 0.5)
            font.family: Theme.font
            font.pixelSize: 10
            font.letterSpacing: 0.6
        }
    }

    Item { Layout.fillWidth: true }

    Tag {
        visible: UPower.displayDevice.isLaptopBattery
        icon: hud.charging ? "\uf583" : "\uf240"
        label: hud.batPct >= 0 ? hud.batPct + "%" : "?"
        tint: hud.batPct <= 20 && !hud.charging ? Theme.warn : (hud.charging ? Theme.accent2 : Theme.text)
    }

    Tag {
        icon: Net.icon
        label: Net.connected ? "ONLINE" : "OFFLINE"
        tint: Net.connected ? Theme.accent2 : Rock.a(Theme.text, 0.5)
    }

    Tag {
        visible: SysStats.temp > 0
        icon: SysStats.temp >= 78 ? "\uf76b" : "\uf2c9"
        label: SysStats.temp + "°C"
        tint: SysStats.temp >= 78 ? Theme.warn : Theme.text
    }

    Tag {
        visible: hud.lockDirty && Notifs.count > 0
        icon: "\uf0f3"
        label: String(Notifs.count)
        tint: Theme.accent
    }
}
