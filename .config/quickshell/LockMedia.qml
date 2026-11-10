import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Медиа-модуль «Обсерватории».
Item {
    id: root

    property real enterProgress: 0
    property var p: Media.player
    property bool has: p !== null && p !== undefined && !!p.trackTitle
    property bool playing: p !== null && p !== undefined
        && p.playbackState === MprisPlaybackState.Playing
    property real trackPos: 0
    property real trackLen: 0
    property int eqTick: 0

    visible: has
    width: card.width
    height: card.height
    opacity: enterProgress
    transform: Translate { y: (1 - root.enterProgress) * 24 }

    Timer {
        interval: 1000
        running: UI.locked && root.p !== null && root.p !== undefined
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.p) return
            root.trackPos = root.p.position
            root.trackLen = root.p.length > 0 ? root.p.length : 0
        }
    }

    Timer {
        interval: 420
        running: UI.locked && root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: root.eqTick++
    }

    Rectangle {
        id: card
        width: Math.min(460, (root.parent ? root.parent.width : 1920) * 0.34)
        height: 148
        radius: 16
        color: Rock.a(Theme.surface, 0.62)
        border.width: 1
        border.color: Rock.a(Theme.text, 0.12)
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Rock.a(Theme.accent, 0.10) }
                GradientStop { position: 0.4; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 112
                Layout.preferredHeight: 112
                radius: 12
                color: Rock.a(Theme.bg, 0.35)
                border.width: 1
                border.color: Rock.a(Theme.accent2, 0.25)
                clip: true

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.p ? (root.p.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 240
                }
                Lbl {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "\uf001"
                    color: Rock.a(Theme.text, 0.35)
                    font.pixelSize: 30
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (root.p && root.p.canTogglePlaying) root.p.togglePlaying() }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    Lbl {
                        text: I18n.t("СЕЙЧАС ИГРАЕТ")
                        color: Rock.a(Theme.accent2, 0.9)
                        font.family: Theme.font
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 3
                        visible: root.playing
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                width: 3; radius: 1.5
                                anchors.bottom: parent.bottom
                                color: index % 2 === 0 ? Theme.accent2 : Theme.accent
                                height: [4, 12, 7, 14][(root.eqTick + index) % 4]
                                Behavior on height { NumberAnimation { duration: 300 } }
                            }
                        }
                    }
                }

                Lbl {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackTitle || "") : ""
                    color: Theme.text
                    font.family: Rock.display
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackArtist || "") : ""
                    color: Rock.a(Theme.text, 0.55)
                    font.family: Theme.font
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 4; radius: 2
                    color: Rock.a(Theme.text, 0.12)
                    Rectangle {
                        width: parent.width * (root.trackLen > 0 ? Math.max(0, Math.min(1, root.trackPos / root.trackLen)) : 0)
                        height: parent.height; radius: 2
                        color: Theme.accent2
                        Behavior on width { NumberAnimation { duration: 900 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: -8; anchors.bottomMargin: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (!root.p || root.p.length <= 0) return
                            try { root.p.position = root.p.length * Math.max(0, Math.min(1, mouse.x / width)) } catch (e) {}
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Lbl { text: Fmt.hms(root.trackPos); color: Rock.a(Theme.text, 0.45); font.pixelSize: 9 }
                    Item { Layout.fillWidth: true }
                    Lbl { text: "-" + Fmt.hms(Math.max(0, root.trackLen - root.trackPos)); color: Rock.a(Theme.text, 0.45); font.pixelSize: 9 }
                }

                Row {
                    Layout.alignment: Qt.AlignRight
                    spacing: 6
                    Repeater {
                        model: [
                            { icon: "\uf048", act: "prev" },
                            { icon: "toggle", act: "toggle" },
                            { icon: "\uf051", act: "next" }
                        ]
                        delegate: Rectangle {
                            id: btn
                            required property var modelData
                            readonly property bool big: modelData.act === "toggle"
                            width: big ? 34 : 28; height: big ? 34 : 28
                            radius: width / 2
                            color: big ? (mArea.containsMouse ? Theme.accent : Rock.a(Theme.accent, 0.75))
                                       : (mArea.containsMouse ? Rock.a(Theme.text, 0.1) : "transparent")
                            border.width: 1
                            border.color: big ? Rock.a(Theme.accent2, 0.3) : Rock.a(Theme.text, 0.14)
                            Lbl {
                                anchors.centerIn: parent
                                text: btn.big ? ((root.p && root.p.playbackState === MprisPlaybackState.Playing) ? "\uf04c" : "\uf04b") : btn.modelData.icon
                                color: btn.big ? Theme.textOnAccent : Rock.a(Theme.text, 0.75)
                                font.pixelSize: btn.big ? 13 : 10
                            }
                            MouseArea {
                                id: mArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.p) return
                                    if (btn.modelData.act === "toggle") { if (root.p.canTogglePlaying) root.p.togglePlaying() }
                                    else if (btn.modelData.act === "next") { if (root.p.canGoNext) root.p.next() }
                                    else { if (root.p.canGoPrevious) root.p.previous() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
