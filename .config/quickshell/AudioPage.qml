import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: page
    property bool active: false
    signal back()

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    PwObjectTracker { objects: page.sinks.concat(page.sources) }

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
            }
        }
    }
}
