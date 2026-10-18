import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

BarPopup {
    id: popup
    alignment: "left"
    property var player: null

    implicitWidth: 320
    implicitHeight: 172

    function fmt(s) {
        if (!isFinite(s) || s < 0) return "0:00"
        return Math.floor(s / 60) + ":" + ("0" + Math.floor(s % 60)).slice(-2)
    }

    Timer {
        running: popup.visible && popup.player !== null
                 && popup.player.playbackState === MprisPlaybackState.Playing
        interval: 500; repeat: true
        onTriggered: popup.player.positionChanged()
    }

    component Btn: Rectangle {
        property string icon
        property bool big: false
        signal activated()
        implicitWidth: big ? 40 : 32
        implicitHeight: implicitWidth
        radius: width / 2
        color: big ? (area.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent)
                   : (area.containsMouse ? Theme.surface : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        Lbl {
            anchors.centerIn: parent
            text: parent.icon
            color: parent.big ? Theme.textOnAccent : Theme.text
            font.pixelSize: parent.big ? 14 : 12
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                radius: 10
                color: Theme.surface
                clip: true
                Image {
                    id: art
                    anchors.fill: parent
                    source: popup.player ? popup.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "\uf001"
                    color: Theme.muted
                    font.pixelSize: 24
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Lbl {
                    Layout.fillWidth: true
                    text: popup.player ? (popup.player.trackTitle || "Без названия") : ""
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: popup.player ? popup.player.trackArtist : ""
                    color: Theme.accent
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: popup.player ? popup.player.identity : ""
                    color: Theme.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        // Прогресс
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 12
            readonly property real ratio: (popup.player && popup.player.length > 0)
                ? Math.max(0, Math.min(1, popup.player.position / popup.player.length)) : 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 3; radius: 2
                color: Theme.surface
                Rectangle {
                    width: parent.width * parent.parent.ratio
                    height: parent.height; radius: 2
                    color: Theme.accent
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const p = popup.player
                    if (p && p.canSeek && p.length > 0) p.position = (mouse.x / width) * p.length
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Lbl { text: popup.fmt(popup.player ? popup.player.position : 0); color: Theme.muted; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Btn {
                icon: "\uf048"
                onActivated: if (popup.player && popup.player.canGoPrevious) popup.player.previous()
            }
            Btn {
                big: true
                icon: (popup.player && popup.player.playbackState === MprisPlaybackState.Playing) ? "\uf04c" : "\uf04b"
                onActivated: if (popup.player && popup.player.canTogglePlaying) popup.player.togglePlaying()
            }
            Btn {
                icon: "\uf051"
                onActivated: if (popup.player && popup.player.canGoNext) popup.player.next()
            }
            Item { Layout.fillWidth: true }
            Lbl { text: popup.fmt(popup.player ? popup.player.length : 0); color: Theme.muted; font.pixelSize: 11 }
        }
    }
}
