import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: page
    property bool active: false
    signal back()

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    // потоки воспроизведения приложений
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && page.isPlayback(n))
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    PwObjectTracker { objects: page.sinks.concat(page.sources).concat(page.streams) }

    function isPlayback(n) {
        try {
            const c = n.properties["media.class"]
            return c === undefined || String(c).indexOf("Output") >= 0
        } catch (e) { return true }
    }
    function streamName(n) {
        try {
            const p = n.properties
            if (p && p["application.name"]) return String(p["application.name"])
        } catch (e) {}
        return n.description || n.nickname || n.name
    }
    function label(n) { return n.description || n.nickname || n.name }
    function iconFor(n) {
        const s = (String(n.name) + " " + String(n.description)).toLowerCase()
        if (s.indexOf("headphone") >= 0 || s.indexOf("headset") >= 0 || s.indexOf("bluez") >= 0) return "\uf025"
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return "\uf108"
        return "\uf028"
    }

    component DeviceRow: Rectangle {
        id: row
        property var node
        property bool current: false
        property string glyph
        signal picked()
        Layout.fillWidth: true
        implicitHeight: 48
        radius: 14
        color: rArea.containsMouse ? Theme.surface : "transparent"
        border.width: current ? 1 : 0
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12
            Lbl {
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter
                text: row.glyph
                color: row.current ? Theme.accent : Theme.text
                font.pixelSize: 15
            }
            Lbl {
                Layout.fillWidth: true
                text: page.label(row.node)
                font.bold: row.current
                elide: Text.ElideRight
            }
            Lbl { visible: row.current; text: "\uf00c"; color: Theme.accent; font.pixelSize: 12 }
        }
        MouseArea {
            id: rArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked()
        }
    }

    // строка громкости одного приложения
    component StreamRow: Rectangle {
        id: sr
        property var node
        readonly property real vol: (node && node.audio) ? node.audio.volume : 0
        Layout.fillWidth: true
        implicitHeight: 44
        radius: 14
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12
            Lbl { Layout.preferredWidth: 104; text: page.streamName(sr.node); font.pixelSize: 12; elide: Text.ElideRight }
            Item {
                id: sbar
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.14)
                    Rectangle {
                        width: parent.width * Math.min(1, sr.vol)
                        height: parent.height
                        radius: 2
                        color: Theme.accent
                    }
                }
                Rectangle {
                    width: 10; height: 10; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * Math.min(1, sr.vol) - width / 2))
                    color: Theme.text
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function setV(mx) {
                        if (sr.node && sr.node.audio) sr.node.audio.volume = Math.max(0, Math.min(1, mx / width))
                    }
                    onPressed: m => setV(m.x)
                    onPositionChanged: m => { if (pressed) setV(m.x) }
                }
            }
            Lbl { Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight; text: Math.round(sr.vol * 100); color: Theme.muted; font.pixelSize: 11 }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IconBtn { icon: "\uf053"; iconColor: Theme.text; onClicked: page.back() }
            Lbl { Layout.fillWidth: true; text: "Звук"; font.bold: true; font.pixelSize: 15 }
            IconBtn { icon: "\uf1de"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
        }

        Flickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: lists.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: lists
                width: scroll.width
                spacing: 4

                Lbl { text: "ВЫВОД"; color: Theme.muted; font.pixelSize: 10; Layout.leftMargin: 6; Layout.topMargin: 4 }
                Repeater {
                    model: page.sinks
                    delegate: DeviceRow {
                        required property var modelData
                        node: modelData
                        glyph: page.iconFor(modelData)
                        current: Pipewire.defaultAudioSink === modelData
                        onPicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }

                Lbl { text: "ВВОД"; color: Theme.muted; font.pixelSize: 10; Layout.leftMargin: 6; Layout.topMargin: 12 }
                Repeater {
                    model: page.sources
                    delegate: DeviceRow {
                        required property var modelData
                        node: modelData
                        glyph: "\uf130"
                        current: Pipewire.defaultAudioSource === modelData
                        onPicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }

                Lbl {
                    visible: page.streams.length > 0
                    text: "ПРИЛОЖЕНИЯ"
                    color: Theme.muted
                    font.pixelSize: 10
                    Layout.leftMargin: 6
                    Layout.topMargin: 12
                }
                Repeater {
                    model: page.streams
                    delegate: StreamRow {
                        required property var modelData
                        node: modelData
                    }
                }
            }
        }
    }
}
