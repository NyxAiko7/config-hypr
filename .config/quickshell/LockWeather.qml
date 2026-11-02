import QtQuick
import QtQuick.Layouts

// Погодная «наклейка» слева снизу.
RockCard {
    id: card

    property real enterProgress: 0

    visible: Weather.ready || Weather.loading
    preferredWidth: Math.min(445, (parent ? parent.width : 1920) * 0.34)
    fill: Rock.cream
    edge: Rock.ink
    shadowColor: Rock.pink
    radius: 18
    borderWidth: 3
    padding: 18
    spacing: 10
    rotation: -2
    opacity: enterProgress
    transform: Translate { y: (1 - card.enterProgress) * 36 }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Lbl {
            text: "\uf005 ПОГОДА"
            color: Rock.pinkDeep
            font.family: Rock.display
            font.pixelSize: 11
            font.weight: Font.Black
            font.letterSpacing: 2
        }
        Item { Layout.fillWidth: true }
        Lbl {
            visible: Weather.city !== ""
            text: Weather.city
            color: Rock.a(Rock.ink, 0.6)
            font.pixelSize: 9
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.maximumWidth: 150
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        Lbl {
            text: Weather.icon
            color: Rock.cyan
            font.pixelSize: 52
        }

        ColumnLayout {
            spacing: -2
            Lbl {
                text: Weather.temp + "°"
                color: Rock.ink
                font.family: Rock.display
                font.pixelSize: 46
                font.weight: Font.Black
            }
            Lbl {
                text: Weather.desc !== "" ? Weather.desc : "—"
                color: Rock.a(Rock.ink, 0.62)
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        Item { Layout.fillWidth: true }

        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Lbl {
                text: "ОЩУЩАЕТСЯ"
                color: Rock.pinkDeep
                font.pixelSize: 8
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignRight
            }
            Lbl {
                text: Weather.feels + "°"
                color: Rock.ink
                font.family: Rock.display
                font.pixelSize: 20
                font.weight: Font.Black
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 3
        radius: 1.5
        color: Rock.ink
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 18
        ColumnLayout {
            spacing: 0
            Lbl { text: "ВЕТЕР"; color: Rock.pinkDeep; font.pixelSize: 8; font.weight: Font.Bold; font.letterSpacing: 1.2 }
            Lbl { text: Weather.wind + " км/ч"; color: Rock.ink; font.pixelSize: 12; font.weight: Font.Bold }
        }
        ColumnLayout {
            spacing: 0
            Lbl { text: "ВЛАЖНОСТЬ"; color: Rock.pinkDeep; font.pixelSize: 8; font.weight: Font.Bold; font.letterSpacing: 1.2 }
            Lbl { text: Weather.humidity + "%"; color: Rock.ink; font.pixelSize: 12; font.weight: Font.Bold }
        }
        ColumnLayout {
            spacing: 0
            Lbl { text: "УФ"; color: Rock.pinkDeep; font.pixelSize: 8; font.weight: Font.Bold; font.letterSpacing: 1.2 }
            Lbl { text: Weather.uv; color: Rock.ink; font.pixelSize: 12; font.weight: Font.Bold }
        }
        Item { Layout.fillWidth: true }
    }

    RowLayout {
        visible: Weather.days.length > 0
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: Weather.days
            delegate: Rectangle {
                id: day
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 10
                color: Rock.paper
                border.width: 2
                border.color: Rock.ink
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Lbl { text: day.modelData.label; color: Rock.a(Rock.ink, 0.6); font.pixelSize: 9; font.weight: Font.Bold }
                    Lbl { text: day.modelData.icon; color: Rock.pinkDeep; font.pixelSize: 15 }
                    Lbl { text: day.modelData.hi + "° / " + day.modelData.lo + "°"; color: Rock.ink; font.pixelSize: 10; font.weight: Font.Bold }
                }
            }
        }
    }
}
