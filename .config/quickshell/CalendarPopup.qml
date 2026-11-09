import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "center"
    implicitWidth: 300
    implicitHeight: 330
    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: Rock.comic ? 22 : Rock.marisa ? 8 : Rock.sao ? 4 : 18

    readonly property var months: [I18n.t("Январь"),I18n.t("Февраль"),I18n.t("Март"),I18n.t("Апрель"),I18n.t("Май"),I18n.t("Июнь"),I18n.t("Июль"),I18n.t("Август"),I18n.t("Сентябрь"),I18n.t("Октябрь"),I18n.t("Ноябрь"),I18n.t("Декабрь")]
    readonly property var days: [I18n.t("Пн"),I18n.t("Вт"),I18n.t("Ср"),I18n.t("Чт"),I18n.t("Пт"),I18n.t("Сб"),I18n.t("Вс")]

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
        color: a.containsMouse ? Rock.a(Rock.pink, 0.22) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        Lbl { anchors.centerIn: parent; text: parent.icon; color: Rock.uiSub; font.pixelSize: 10 }
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
                color: Rock.uiText
                font.family: Rock.display
                font.weight: Font.Black
                font.pixelSize: 17
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
                    color: Rock.uiSub
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
                    radius: Rock.comic ? 16 : Rock.marisa ? 6 : Rock.sao ? 3 : 10
                    color: isToday ? Rock.uiAccent : "transparent"
                    border.width: isToday ? Rock.uiBorder : 0
                    border.color: Rock.uiEdge

                    Lbl {
                        anchors.centerIn: parent
                        text: parent.d.getDate()
                        color: parent.isToday ? (Rock.marisa ? Rock.cream : (Rock.comic ? Rock.cream : Rock.ink)) : Rock.uiText
                        opacity: parent.inMonth ? ((parent.index % 7) >= 5 && !parent.isToday ? 0.65 : 1) : 0.25
                        font.bold: parent.isToday
                        font.family: parent.isToday ? Rock.display : Rock.mono
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
