import QtQuick
import QtQuick.Layouts

// Погодный модуль «Обсерватории».
Rectangle {
    id: card

    property real enterProgress: 0

    visible: Weather.ready || Weather.loading
    width: Math.min(430, (parent ? parent.width : 1920) * 0.32)
    height: col.implicitHeight + 28
    radius: 16
    color: Rock.a(Theme.surface, 0.62)
    border.width: 1
    border.color: Rock.a(Theme.text, 0.12)
    opacity: enterProgress
    transform: Translate { y: (1 - card.enterProgress) * 24 }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        RowLayout {
            width: parent.width
            Lbl {
                text: "\uf0c2  " + I18n.t("ПОГОДА")
                color: Rock.a(Theme.accent2, 0.95)
                font.family: Theme.font
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 2.2
            }
            Item { Layout.fillWidth: true }
            Lbl {
                visible: Weather.city !== ""
                text: Weather.city
                color: Rock.a(Theme.text, 0.5)
                font.family: Theme.font
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.maximumWidth: 180
            }
        }

        RowLayout {
            width: parent.width
            spacing: 14
            WeatherOrb {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52
                code: Weather.code
                isDay: Weather.isDay
                active: card.visible
                accent: Theme.accent
                accent2: Theme.accent2
                cloudColor: Theme.text
            }
            Column {
                spacing: 0
                Lbl { text: Weather.temp + "°"; color: Theme.text; font.family: Rock.display; font.pixelSize: 38; font.weight: Font.Bold }
                Lbl { text: Weather.desc !== "" ? Weather.desc : "—"; color: Rock.a(Theme.text, 0.6); font.family: Theme.font; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 6
                Row { spacing: 6; Lbl { text: I18n.t("ОЩУЩАЕТСЯ"); color: Rock.a(Theme.text, 0.4); font.pixelSize: 8; font.letterSpacing: 1 } Lbl { text: Weather.feels + "°"; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold } }
                Row { spacing: 10
                    Row { spacing: 4; Lbl { text: "\uf72e"; color: Rock.a(Theme.text, 0.45); font.pixelSize: 10 } Lbl { text: Weather.wind + I18n.t(" км/ч"); color: Rock.a(Theme.text, 0.75); font.pixelSize: 10 } }
                    Row { spacing: 4; Lbl { text: "\uf043"; color: Rock.a(Theme.text, 0.45); font.pixelSize: 10 } Lbl { text: Weather.humidity + "%"; color: Rock.a(Theme.text, 0.75); font.pixelSize: 10 } }
                }
            }
        }

        Row {
            visible: Weather.days.length > 0
            width: parent.width
            spacing: 6
            Repeater {
                model: Weather.days
                delegate: Rectangle {
                    required property var modelData
                    width: (col.width - 12) / 3
                    height: 38
                    radius: 10
                    color: Rock.a(Theme.bg, 0.28)
                    border.width: 1
                    border.color: Rock.a(Theme.text, 0.08)
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Lbl { text: modelData.label; color: Rock.a(Theme.text, 0.5); font.pixelSize: 9 }
                        Lbl { text: modelData.icon; color: Theme.accent2; font.pixelSize: 13 }
                        Lbl { text: modelData.hi + "°"; color: Theme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                    }
                }
            }
        }
    }
}
