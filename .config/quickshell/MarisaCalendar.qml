import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "center"

    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: 8

    implicitWidth: 326
    implicitHeight: 388

    readonly property var months: [I18n.t("Январь"),I18n.t("Февраль"),I18n.t("Март"),I18n.t("Апрель"),I18n.t("Май"),I18n.t("Июнь"),I18n.t("Июль"),I18n.t("Август"),I18n.t("Сентябрь"),I18n.t("Октябрь"),I18n.t("Ноябрь"),I18n.t("Декабрь")]
    readonly property var days: [I18n.t("Пн"),I18n.t("Вт"),I18n.t("Ср"),I18n.t("Чт"),I18n.t("Пт"),I18n.t("Сб"),I18n.t("Вс")]

    property var today: new Date()
    property var viewDate: new Date()
    readonly property int offset: (new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay() + 6) % 7

    readonly property real phase: moonPhase(viewDate)
    function moonPhase(date) {
        const synodic = 29.530588853
        const ref = Date.UTC(2000, 0, 6, 18, 14)
        const days = (date.getTime() - ref) / 86400000
        let p = (days / synodic) % 1
        if (p < 0) p += 1
        return p
    }
    readonly property real lit: 1 - Math.abs(phase * 2 - 1)
    function phaseName() {
        const p = phase
        if (p < 0.03 || p > 0.97) return I18n.t("НОВОЛУНИЕ")
        if (p < 0.22) return I18n.t("РАСТУЩИЙ СЕРП")
        if (p < 0.28) return I18n.t("ПЕРВАЯ ЧЕТВЕРТЬ")
        if (p < 0.47) return I18n.t("РАСТУЩАЯ ЛУНА")
        if (p < 0.53) return I18n.t("ПОЛНОЛУНИЕ")
        if (p < 0.72) return I18n.t("УБЫВАЮЩАЯ ЛУНА")
        if (p < 0.78) return I18n.t("ПОСЛЕДНЯЯ ЧЕТВЕРТЬ")
        return I18n.t("УБЫВАЮЩИЙ СЕРП")
    }

    function shift(n) { viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + n, 1) }
    onVisibleChanged: if (visible) { today = new Date(); viewDate = new Date() }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => pop.shift(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    component Arrow: Item {
        id: arrow
        property string icon
        signal activated()
        implicitWidth: 26
        implicitHeight: 26
        Rectangle {
            anchors.fill: parent
            radius: 4
            rotation: 45
            color: arrowArea.containsMouse ? Rock.a(Rock.gold, 0.16) : "transparent"
            border.width: 1
            border.color: Rock.a(Rock.gold, 0.4)
            Behavior on color { ColorAnimation { duration: 120 } }
            Lbl {
                anchors.centerIn: parent
                rotation: -45
                text: arrow.icon
                color: Rock.uiSub
                font.pixelSize: 10
            }
        }
        MouseArea {
            id: arrowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Canvas {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                readonly property real ph: pop.phase
                readonly property real luminosity: pop.lit
                onPhChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 3
                    ctx.fillStyle = Rock.a(Rock.uiSurface2, 0.9)
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.fillStyle = Qt.lighter(Rock.uiSurface, 1.03)
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.fill()
                    const d = 2 * r * Math.max(0, Math.min(1, 1 - luminosity))
                    const dir = ph < 0.5 ? 1 : -1
                    ctx.fillStyle = Rock.a(Rock.ink, 0.82)
                    ctx.beginPath()
                    ctx.arc(cx - dir * d, cy, r, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.strokeStyle = Rock.a(Rock.gold, 0.55)
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1
                Lbl {
                    Layout.fillWidth: true
                    text: pop.months[pop.viewDate.getMonth()] + " " + pop.viewDate.getFullYear()
                    color: Rock.uiText
                    font.family: Rock.display
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pop.viewDate = new Date() }
                }
                Lbl {
                    Layout.fillWidth: true
                    text: pop.phaseName() + " · " + Math.round(pop.lit * 100) + "%"
                    color: Rock.a(Rock.gold, 0.9)
                    font.pixelSize: 7
                    font.bold: true
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }
            }

            Arrow { icon: "\uf053"; onActivated: pop.shift(-1) }
            Arrow { icon: "\uf054"; onActivated: pop.shift(1) }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Rock.a(Rock.uiEdge, 0.4)
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
                    Layout.preferredWidth: 40
                    Layout.bottomMargin: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Rock.a(Rock.uiSub, 0.85)
                    font.family: Rock.display
                    font.pixelSize: 9
                    font.letterSpacing: 0.5
                    opacity: index >= 5 ? 0.6 : 1
                }
            }

            Repeater {
                model: 42
                delegate: Item {
                    id: cell
                    required property int index
                    readonly property var d: new Date(pop.viewDate.getFullYear(), pop.viewDate.getMonth(), 1 - pop.offset + index)
                    readonly property bool inMonth: d.getMonth() === pop.viewDate.getMonth()
                    readonly property bool isToday: d.getFullYear() === pop.today.getFullYear()
                        && d.getMonth() === pop.today.getMonth() && d.getDate() === pop.today.getDate()

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 34

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 4
                        color: cell.isToday ? "transparent"
                               : (cellArea.containsMouse ? Rock.a(Rock.gold, 0.10) : "transparent")
                        border.width: cellArea.containsMouse && !cell.isToday ? 1 : 0
                        border.color: Rock.a(Rock.gold, 0.35)
                    }

                    Rectangle {
                        visible: cell.isToday
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        rotation: 45
                        radius: 3
                        color: Rock.a(Rock.gold, 0.22)
                        border.width: 1.5
                        border.color: Rock.gold
                    }

                    Lbl {
                        anchors.centerIn: parent
                        text: cell.isToday ? "✦" : cell.d.getDate()
                        color: cell.isToday ? Rock.gold : Rock.uiText
                        font.family: Rock.display
                        font.pixelSize: cell.isToday ? 12 : 12
                        font.bold: cell.isToday
                        opacity: cell.inMonth ? ((cell.index % 7) >= 5 ? 0.68 : 1) : 0.22
                    }

                    Rectangle {
                        visible: cell.isToday
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 3
                        anchors.bottomMargin: 2
                        width: 4
                        height: 4
                        radius: 1
                        rotation: 45
                        color: Rock.pinkDeep
                    }

                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Lbl {
                text: "✦"
                color: Rock.gold
                font.pixelSize: 9
            }
            Lbl {
                Layout.fillWidth: true
                text: I18n.t("СЕГОДНЯ · ") + Qt.formatDateTime(pop.today, "dd MMMM yyyy").toUpperCase()
                color: Rock.a(Rock.uiSub, 0.9)
                font.pixelSize: 7
                font.letterSpacing: 0.8
                elide: Text.ElideRight
            }
        }
    }
}
