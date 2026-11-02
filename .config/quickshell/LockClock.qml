import QtQuick
import QtQuick.Layouts
import Quickshell

// Часы и телеметрия: крупное время с цветными контурными слоями, дата-стикер, CPU/RAM.
Item {
    id: root

    property real enterProgress: 0

    width: col.implicitWidth
    height: col.implicitHeight
    opacity: enterProgress
    transform: Translate { x: (1 - root.enterProgress) * -44 }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Column {
        id: col
        spacing: 6

        Row {
            spacing: 10
            Rectangle {
                width: 46; height: 3; radius: 1.5
                color: Rock.yellow
                anchors.verticalCenter: parent.verticalCenter
                rotation: -2
            }
            Lbl {
                text: "ЛОКАЛЬНОЕ ВРЕМЯ"
                color: Rock.pink
                font.family: Rock.display
                font.pixelSize: 11
                font.weight: Font.Black
                font.letterSpacing: 3
            }
        }

        Item {
            width: mainTime.width
            height: mainTime.height

            Text {
                x: 14; y: 14
                width: mainTime.width; height: mainTime.height
                text: mainTime.text
                color: Rock.cyan
                font.family: Rock.display
                font.pixelSize: mainTime.font.pixelSize
                font.weight: Font.Black
                font.letterSpacing: -4
            }
            Text {
                x: 7; y: 7
                width: mainTime.width; height: mainTime.height
                text: mainTime.text
                color: Rock.pinkDeep
                font.family: Rock.display
                font.pixelSize: mainTime.font.pixelSize
                font.weight: Font.Black
                font.letterSpacing: -4
            }
            Text {
                id: mainTime
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Rock.cream
                font.family: Rock.display
                font.pixelSize: Math.min(205, Math.round(root.parent ? root.parent.width * 0.115 : 150))
                font.weight: Font.Black
                font.letterSpacing: -4
            }
        }

        Row {
            spacing: 8

            RockChip {
                fill: Rock.yellow
                shadowColor: Rock.pink
                Lbl {
                    text: Qt.locale("ru_RU").toString(clock.date, "dddd · d MMMM yyyy").toUpperCase()
                    color: Rock.ink
                    font.family: Rock.display
                    font.pixelSize: 11
                    font.weight: Font.Black
                    font.letterSpacing: 1.4
                }
            }

            RockChip {
                fill: Rock.pink
                shadowColor: Rock.cyan
                spacing: 5
                Lbl {
                    text: Qt.formatTime(clock.date, "ss")
                    color: Rock.cream
                    font.family: Rock.display
                    font.pixelSize: 12
                    font.weight: Font.Black
                }
                Lbl {
                    text: "СЕК"
                    color: Rock.cream
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    opacity: 0.8
                }
            }
        }

        RockChip {
            fill: Rock.ink2
            edge: Rock.ink
            shadowColor: Rock.purple
            spacing: 14

            Lbl {
                text: "CPU " + SysStats.cpu + "%"
                color: SysStats.cpu >= 85 ? Rock.yellow : Rock.cream
                font.pixelSize: 10
                font.weight: Font.Bold
            }
            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 5
                radius: 2.5
                color: Rock.a(Rock.cream, 0.18)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, SysStats.cpu / 100))
                    height: parent.height
                    radius: 2.5
                    color: SysStats.cpu >= 85 ? Rock.yellow : Rock.pink
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }

            Lbl {
                text: "RAM " + SysStats.mem + "%"
                color: SysStats.mem >= 90 ? Rock.yellow : Rock.cream
                font.pixelSize: 10
                font.weight: Font.Bold
            }
            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 5
                radius: 2.5
                color: Rock.a(Rock.cream, 0.18)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, SysStats.mem / 100))
                    height: parent.height
                    radius: 2.5
                    color: SysStats.mem >= 90 ? Rock.yellow : Rock.cyan
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }

            Lbl {
                text: "\uf017 " + SysStats.uptimeText
                color: Rock.a(Rock.cream, 0.65)
                font.pixelSize: 9
            }
        }
    }
}
