import QtQuick
import QtQuick.Layouts

// Компактный переключатель из нескольких вариантов.
RowLayout {
    id: root

    property var options: []          // [{ key, label }]
    property string value: ""
    signal picked(string key)

    spacing: 6

    Repeater {
        model: root.options

        delegate: Rectangle {
            id: opt
            required property var modelData
            readonly property bool on: root.value === modelData.key

            implicitWidth: choiceLbl.implicitWidth + 22
            implicitHeight: 30
            radius: Math.max(6, PanelConfig.islandRadius - 6)
            color: on ? Rock.uiAccent
                      : (choiceArea.containsMouse ? Rock.a(Rock.uiAccent, 0.14) : Rock.a(Rock.uiText, 0.05))
            border.width: 1
            border.color: on ? Rock.uiAccent : Rock.a(Rock.uiText, 0.18)
            Behavior on color { ColorAnimation { duration: 120 } }

            Lbl {
                id: choiceLbl
                anchors.centerIn: parent
                text: opt.modelData.label
                color: opt.on ? Rock.uiOnActive : Rock.uiSub
                font.family: Rock.display
                font.pixelSize: 11
                font.bold: true
            }

            MouseArea {
                id: choiceArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(opt.modelData.key)
            }
        }
    }
}
