import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// Верхняя HUD-строка локскрина: «ON AIR», юзер, батарея, сеть, температура.
RowLayout {
    id: hud

    property real enterProgress: 0
    property int batPct: -1
    property bool charging: false
    property bool lockDirty: false

    height: 30
    opacity: enterProgress
    transform: Translate { y: (1 - hud.enterProgress) * -18 }

    RockChip {
        fill: Rock.yellow
        shadowColor: Rock.pink
        spacing: 8
        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: Rock.pink
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: true
                NumberAnimation { to: 0.25; duration: 850; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 850; easing.type: Easing.InOutSine }
            }
        }
        Lbl {
            text: Rock.comic ? "ON AIR · BOCCHI MODE" : Rock.marisa ? "SPELL CARD · MARISA MODE" : Rock.sao ? "SYSTEM · AINCRAD MODE" : "STELLAR · ASTRAL MODE"
            color: Rock.ink
            font.family: Rock.display
            font.pixelSize: 11
            font.weight: Font.Black
            font.letterSpacing: 1.2
        }
    }

    RockChip {
        fill: Rock.comic ? Rock.cream : Rock.uiSurface2
        shadowColor: Rock.cyan
        Lbl {
            text: Quickshell.env("USER") + "@" + (Quickshell.env("HOSTNAME") || "artix")
            color: Rock.uiText
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }
    }

    Item { Layout.fillWidth: true }

    RockChip {
        visible: UPower.displayDevice.isLaptopBattery
        fill: Rock.comic ? Rock.cream : Rock.uiSurface2
        shadowColor: Rock.yellow
        spacing: 5
        Lbl {
            text: hud.charging ? "\uf583" : "\uf240"
            color: hud.charging ? Rock.pinkDeep : Rock.uiText
            font.pixelSize: 12
        }
        Lbl {
            text: hud.batPct >= 0 ? hud.batPct + "%" : "?"
            color: hud.batPct <= 20 && !hud.charging ? (Rock.sao ? Rock.danger : Rock.pinkDeep) : Rock.uiText
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    RockChip {
        fill: Rock.comic ? Rock.cream : Rock.uiSurface2
        shadowColor: Rock.pink
        spacing: 6
        Lbl {
            text: Net.icon
            color: Net.connected ? Rock.pinkDeep : Rock.uiText
            font.pixelSize: 12
        }
        Lbl {
            text: Net.connected ? "ONLINE" : "OFFLINE"
            color: Rock.uiText
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }
    }

    RockChip {
        visible: SysStats.temp > 0
        fill: Rock.comic ? Rock.cream : Rock.uiSurface2
        shadowColor: Rock.cyan
        spacing: 5
        Lbl {
            text: SysStats.temp >= 78 ? "\uf76b" : (SysStats.temp >= 68 ? "\uf76a" : "\uf768")
            color: SysStats.temp >= 78 ? Rock.pinkDeep : Rock.uiText
            font.pixelSize: 12
        }
        Lbl {
            text: SysStats.temp + "°C"
            color: Rock.uiText
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }

    RockChip {
        visible: hud.lockDirty && Notifs.count > 0
        fill: Rock.pink
        shadowColor: Rock.yellow
        spacing: 5
        Lbl { text: "\uf0f3"; color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink; font.pixelSize: 12 }
        Lbl { text: Notifs.count; color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink; font.pixelSize: 10; font.weight: Font.Black }
    }
}
