import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Попап «Горячие клавиши»: читает бинды из ~/.config/hypr/hyprland.lua
// через keybinds.py (hyprctl для Lua-конфига отдаёт вместо команд числовые id).
BarPopup {
    id: self

    property var keys: []
    property string title: I18n.t("ГОРЯЧИЕ КЛАВИШИ")

    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: Rock.comic ? 20 : Rock.marisa ? 6 : Rock.sao ? 4 : 16
    borderWidth: Rock.comic ? 3 : 1
    decorated: true

    implicitWidth: 430
    implicitHeight: Math.min(620, 150 + Math.max(0, self.keys.length) * 22)

    Process {
        id: keyProc
        command: ["python3",
                  Quickshell.env("HOME") + "/.config/quickshell/keybinds.py",
                  Quickshell.env("HOME") + "/.config/hypr/hyprland.lua"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text)
                    self.keys = Array.isArray(arr) ? arr : []
                } catch (e) { self.keys = [] }
            }
        }
    }

    onVisibleChanged: if (visible) keyProc.running = true

    Item {
        anchors.fill: parent
        anchors.margins: 16

        // ── шапка ──
        Item {
            id: header
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: self.title
                color: Rock.uiText
                font.family: Rock.display
                font.weight: Font.Black
                font.pixelSize: 14
                font.letterSpacing: 1.2
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 26
                radius: Rock.comic ? 13 : Rock.marisa ? 2 : Rock.sao ? 2 : 13
                color: closeArea.containsMouse ? Rock.a(Rock.uiAccent, 0.22) : "transparent"
                border.width: closeArea.containsMouse ? 1 : 0
                border.color: Rock.uiAccent
                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    color: Rock.uiText
                    font.family: Rock.display
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: self.visible = false
                }
            }
        }

        Rectangle {
            id: sep
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Rock.a(Rock.uiAccent, 0.35)
        }

        // ── список ──
        Flickable {
            id: flick
            anchors.top: sep.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: listCol.height

            Column {
                id: listCol
                width: flick.width
                spacing: 2

                Repeater {
                    model: self.keys
                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isHead: index === 0
                            || self.keys[index - 1].group !== modelData.group

                        width: listCol.width
                        height: isHead ? 32 : 22

                        Text {
                            visible: row.isHead
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            text: String(row.modelData.group || "").toUpperCase()
                            color: Rock.uiAccent
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 10
                            font.letterSpacing: 1.6
                        }

                        Item {
                            visible: !row.isHead
                            anchors.fill: parent

                            Rectangle {
                                id: chip
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: keyText.implicitWidth + 16
                                height: 18
                                radius: Rock.comic ? 6 : Rock.marisa ? 1 : Rock.sao ? 1 : 5
                                color: Rock.a(Rock.uiAccent, 0.14)
                                border.width: 1
                                border.color: Rock.a(Rock.uiAccent, 0.40)

                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: row.modelData.keys
                                    color: Rock.uiText
                                    font.family: Rock.mono
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                anchors.left: chip.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.action
                                color: Rock.uiSub
                                font.family: Rock.mono
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    visible: self.keys.length === 0
                    width: listCol.width
                    text: I18n.t("СПИСОК ПУСТ · проверь ~/.config/hypr/hyprland.lua")
                    color: Rock.uiSub
                    font.family: Rock.display
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
