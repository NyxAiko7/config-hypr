import QtQuick
import QtQuick.Layouts
import Quickshell

// «Обсерватория»: монументальное время, вертикальная дата и телеметрия.
Item {
    id: root

    property real enterProgress: 0

    width: col.implicitWidth
    height: col.implicitHeight
    opacity: enterProgress
    transform: Translate { x: (1 - root.enterProgress) * -36; y: (1 - root.enterProgress) * 10 }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Column {
        id: col
        spacing: 14

        Row {
            spacing: 14

            Rectangle {
                width: 3
                height: timeBlock.height - 8
                radius: 1.5
                anchors.verticalCenter: timeBlock.verticalCenter
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.2; color: Theme.accent2 }
                    GradientStop { position: 0.8; color: Theme.accent }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Column {
                id: timeBlock
                spacing: -10

                Lbl {
                    text: I18n.t("ОБСЕРВАТОРИЯ")
                    color: Rock.a(Theme.accent2, 0.9)
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 5
                }

                Row {
                    spacing: 10
                    Text {
                        id: hh
                        text: Qt.formatTime(clock.date, "HH")
                        color: Theme.text
                        font.family: Rock.display
                        font.pixelSize: Math.min(190, Math.round(root.parent ? root.parent.width * 0.108 : 150))
                        font.weight: Font.Black
                        font.letterSpacing: -6
                    }
                    Text {
                        text: ":"
                        anchors.verticalCenter: hh.verticalCenter
                        anchors.verticalCenterOffset: -8
                        color: Rock.a(Theme.accent, 0.9)
                        font.family: Rock.display
                        font.pixelSize: hh.font.pixelSize * 0.72
                        font.weight: Font.Light
                        opacity: (clock.date.getSeconds() % 2 === 0) ? 1 : 0.25
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                    Column {
                        anchors.verticalCenter: hh.verticalCenter
                        spacing: -4
                        Text {
                            text: Qt.formatTime(clock.date, "mm")
                            color: Theme.text
                            font.family: Rock.display
                            font.pixelSize: hh.font.pixelSize
                            font.weight: Font.Black
                            font.letterSpacing: -6
                        }
                        Row {
                            spacing: 6
                            Rectangle { width: 18; height: 2; radius: 1; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Lbl {
                                text: Qt.formatTime(clock.date, "ss")
                                color: Rock.a(Theme.text, 0.55)
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                font.letterSpacing: 2
                            }
                        }
                    }
                }

                Lbl {
                    text: Qt.locale(PanelConfig.english ? "en_US" : "ru_RU")
                              .toString(clock.date, "dddd, d MMMM yyyy").toUpperCase()
                    color: Rock.a(Theme.text, 0.65)
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.letterSpacing: 2.2
                }
            }
        }

        Row {
            spacing: 18
            anchors.left: parent.left
            anchors.leftMargin: 18

            Repeater {
                model: [
                    { k: "CPU", v: SysStats.cpu, c: Theme.accent },
                    { k: "RAM", v: SysStats.mem, c: Theme.accent2 },
                    { k: "DSK", v: SysStats.disk, c: Rock.a(Theme.text, 0.7) }
                ]
                delegate: Column {
                    required property var modelData
                    spacing: 4
                    Row {
                        spacing: 6
                        Lbl {
                            text: modelData.k
                            color: Rock.a(Theme.text, 0.45)
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.letterSpacing: 1.5
                        }
                        Lbl {
                            text: modelData.v + "%"
                            color: modelData.v >= 85 ? Theme.warn : Theme.text
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                    Rectangle {
                        width: 78; height: 3; radius: 1.5
                        color: Rock.a(Theme.text, 0.12)
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, modelData.v / 100))
                            height: parent.height; radius: 1.5
                            color: modelData.v >= 85 ? Theme.warn : modelData.c
                            Behavior on width { NumberAnimation { duration: 350 } }
                        }
                    }
                }
            }

            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Lbl { text: "\uf017"; color: Rock.a(Theme.text, 0.4); font.pixelSize: 10 }
                Lbl {
                    text: SysStats.uptimeText
                    color: Rock.a(Theme.text, 0.55)
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }
        }
    }
}
