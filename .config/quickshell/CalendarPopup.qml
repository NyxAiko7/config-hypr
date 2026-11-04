import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "center"
    implicitWidth: 300
    implicitHeight: 330

    readonly property var months: ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"]
    readonly property var days: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]

    property var today: new Date()
    property var viewDate: new Date()
    readonly property int offset: (new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay() + 6) % 7

    function shift(n) { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + n, 1) }
    onVisibleChanged: if (visible) { today = new Date(); viewDate = new Date() }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => pop.shift(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    component Arrow: Rectangle {
        property string icon
        signal activated()
        implicitWidth: 28; implicitHeight: 28; radius: 14
        color: a.containsMouse ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        Lbl { anchors.centerIn: parent; text: parent.icon; color: Theme.muted; font.pixelSize: 10 }
        MouseArea { id: a; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Arrow { icon: "\uf053"; onActivated: pop.shift(-1) }
            Lbl {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: pop.months[pop.viewDate.getMonth()] + " " + pop.viewDate.getFullYear()
                font.bold: true
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pop.viewDate = new Date() }
            }
            Arrow { icon: "\uf054"; onActivated: pop.shift(1) }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: pop.days
                delegate: Lbl {
                    required property var modelData
                    required property int index
                    Layout.preferredWidth: 36
                    Layout.bottomMargin: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.muted
                    font.pixelSize: 10
                    opacity: index >= 5 ? 0.6 : 1
                }
            }
            Repeater {
                model: 42
                delegate: Rectangle {
                    required property int index
                    readonly property var d: new Date(pop.viewDate.getFullYear(), pop.viewDate.getMonth(), 1 - pop.offset + index)
                    readonly property bool inMonth: d.getMonth() === pop.viewDate.getMonth()
                    readonly property bool isToday: d.getFullYear() === pop.today.getFullYear()
                        && d.getMonth() === pop.today.getMonth() && d.getDate() === pop.today.getDate()

                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 32
                    radius: 16
                    color: isToday ? Theme.accent : "transparent"

                    Lbl {
                        anchors.centerIn: parent
                        text: parent.d.getDate()
                        color: parent.isToday ? Theme.textOnAccent : Theme.text
                        opacity: parent.inMonth ? ((parent.index % 7) >= 5 && !parent.isToday ? 0.65 : 1) : 0.25
                        font.bold: parent.isToday
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
