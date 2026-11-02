import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

// Кассетная карточка «сейчас играет» справа снизу.
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
    width: card.width + 9
    height: card.height + 9
    rotation: 1.4
    opacity: enterProgress
    transform: Translate { y: (1 - root.enterProgress) * 36 }

    // position у Mpris не notify-сигнал — опрашиваем сами
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
        interval: 480
        running: UI.locked && root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: root.eqTick++
    }

    Rectangle {
        x: 8; y: 8
        width: card.width
        height: card.height
        radius: card.radius
        color: Rock.cyan
        border.width: 3
        border.color: Rock.ink
    }

    Rectangle {
        id: card
        width: Math.min(480, (root.parent ? root.parent.width : 1920) * 0.36)
        height: 166
        radius: 18
        color: Rock.ink2
        border.width: 3
        border.color: Rock.ink

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            Item {
                Layout.preferredWidth: 124
                Layout.preferredHeight: 124

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Rock.pink
                    border.width: 3
                    border.color: Rock.ink
                    clip: true

                    Lbl {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        text: "\uf001"
                        color: Rock.cream
                        font.pixelSize: 34
                    }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.p ? (root.p.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 280
                    }
                    RoundMask {
                        anchors.fill: parent
                        radius: 14
                        maskColor: Rock.ink2
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (root.p && root.p.canTogglePlaying) root.p.togglePlaying() }
                    }

                    Rectangle {
                        visible: root.playing
                        anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                        width: 34; height: 20; radius: 10
                        color: Rock.ink
                        border.width: 2
                        border.color: Rock.cream
                        Row {
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: 3
                                Rectangle {
                                    required property int index
                                    width: 3; radius: 1.5
                                    color: [Rock.pink, Rock.yellow, Rock.cyan][index % 3]
                                    height: [5, 10, 7][(root.eqTick + index) % 3]
                                    Behavior on height { NumberAnimation { duration: 380 } }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Lbl {
                    text: "СЕЙЧАС ИГРАЕТ"
                    color: Rock.yellow
                    font.family: Rock.display
                    font.pixelSize: 9
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }
                Lbl {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackTitle || "") : ""
                    color: Rock.cream
                    font.family: Rock.display
                    font.pixelSize: 16
                    font.weight: Font.Black
                    elide: Text.ElideRight
                }
                Lbl {
                    Layout.fillWidth: true
                    text: root.p ? (root.p.trackArtist || "") : ""
                    color: Rock.a(Rock.cream, 0.6)
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 18
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 7
                        radius: 3.5
                        color: Rock.a(Rock.cream, 0.16)
                        border.width: 1
                        border.color: Rock.a(Rock.cream, 0.1)
                        Rectangle {
                            width: parent.width * (root.trackLen > 0
                                ? Math.max(0, Math.min(1, root.trackPos / root.trackLen)) : 0)
                            height: parent.height
                            radius: 3.5
                            color: Rock.yellow
                            Behavior on width { NumberAnimation { duration: 900 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -6
                            anchors.bottomMargin: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (!root.p || root.p.length <= 0) return
                                try {
                                    root.p.position = root.p.length
                                        * Math.max(0, Math.min(1, mouse.x / width))
                                } catch (e) { }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Lbl { text: Fmt.hms(root.trackPos); color: Rock.a(Rock.cream, 0.55); font.pixelSize: 9 }
                    Item { Layout.fillWidth: true }
                    Lbl {
                        text: "-" + Fmt.hms(Math.max(0, root.trackLen - root.trackPos))
                        color: Rock.a(Rock.cream, 0.55)
                        font.pixelSize: 9
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8
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
                            Layout.preferredWidth: big ? 36 : 30
                            Layout.preferredHeight: big ? 36 : 30
                            radius: width / 2
                            color: big
                                ? (mArea.containsMouse ? Rock.pinkDeep : Rock.pink)
                                : (mArea.containsMouse ? Rock.a(Rock.cream, 0.12) : "transparent")
                            border.width: 2
                            border.color: big ? Rock.ink : Rock.a(Rock.cream, 0.3)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Lbl {
                                anchors.centerIn: parent
                                text: btn.big
                                    ? ((root.p && root.p.playbackState === MprisPlaybackState.Playing)
                                        ? "\uf04c" : "\uf04b")
                                    : btn.modelData.icon
                                color: btn.big ? Rock.cream : Rock.a(Rock.cream, 0.8)
                                font.pixelSize: btn.big ? 14 : 11
                            }
                            MouseArea {
                                id: mArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.p) return
                                    if (btn.modelData.act === "toggle") {
                                        if (root.p.canTogglePlaying) root.p.togglePlaying()
                                    } else if (btn.modelData.act === "next") {
                                        if (root.p.canGoNext) root.p.next()
                                    } else {
                                        if (root.p.canGoPrevious) root.p.previous()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
