import QtQuick
import QtQuick.Layouts

// Одна строка настроек: заголовок слева, элемент управления справа.
Item {
    id: row

    property string title: ""
    property string hint: ""
    default property alias control: right.data

    Layout.fillWidth: true
    Layout.preferredHeight: hint === "" ? 44 : 56
    implicitHeight: Layout.preferredHeight

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 1

            Lbl {
                Layout.fillWidth: true
                text: row.title
                color: Rock.uiText
                font.family: Rock.display
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Lbl {
                Layout.fillWidth: true
                visible: row.hint !== ""
                text: row.hint
                color: Rock.uiSub
                font.family: Rock.display
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: right
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }
}
