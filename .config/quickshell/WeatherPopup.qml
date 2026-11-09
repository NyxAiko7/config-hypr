import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "center"
    implicitWidth: 432
    implicitHeight: card.height + 26
    fill: "transparent"
    accent: "transparent"
    radius: 0
    borderWidth: 0

    onVisibleChanged: if (visible) Weather.refresh(false)

    readonly property var today: Weather.days.length > 0 ? Weather.days[0] : null
    readonly property real dayMin: {
        const d = Weather.days
        if (d.length === 0) return 0
        let m = 1e9
        for (let i = 0; i < d.length; i++) m = Math.min(m, d[i].lo)
        return m
    }
    readonly property real dayMax: {
        const d = Weather.days
        if (d.length === 0) return 0
        let m = -1e9
        for (let i = 0; i < d.length; i++) m = Math.max(m, d[i].hi)
        return m
    }
    readonly property bool hasPop: {
        const h = Weather.hourly
        for (let i = 0; i < h.length; i++) if (h[i].pop >= 10) return true
        return false
    }

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 8

        Rectangle {
            visible: Rock.comic
            x: 9
            y: 11
            width: card.width
            height: card.height
            radius: 18
            color: Rock.pink
            border.width: 3
            border.color: Rock.ink
            rotation: -1.1
            transformOrigin: Item.Center
        }

        Rectangle {
            id: card
            width: 404
            height: layout.implicitHeight + 34
            radius: Rock.comic ? 18 : Rock.marisa ? 8 : Rock.sao ? 4 : 14
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: layout
                x: 17
                y: 17
                width: card.width - 34
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        spacing: -4
                        RowLayout {
                            spacing: 5
                            Lbl {
                                text: "\uf0e7"
                                color: Rock.yellow
                                font.pixelSize: 15
                                rotation: Rock.comic ? -8 : 0
                            }
                            Lbl {
                                text: I18n.t("ПОГОДА")
                                color: Rock.uiText
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 25
                                font.letterSpacing: 0.2
                            }
                        }
                        Lbl {
                            text: Rock.marisa ? "SPELL FORECAST" : Rock.sao ? "AINCRAD FORECAST" : "KESSOKU METEO"
                            color: Rock.pinkDeep
                            font.pixelSize: 8
                            font.weight: Font.Black
                            font.letterSpacing: 2.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RockChip {
                        visible: Weather.city !== ""
                        fill: Rock.yellow
                        shadowColor: Rock.pink
                        offset: 2
                        radius: 7
                        padH: 8
                        padV: 3
                        Lbl {
                            Layout.maximumWidth: 120
                            elide: Text.ElideRight
                            text: Weather.city.toUpperCase()
                            color: Rock.ink
                            font.family: Rock.display
                            font.weight: Font.Black
                            font.pixelSize: 9
                            font.letterSpacing: 0.6
                        }
                    }
                }

                ColumnLayout {
                    visible: !Weather.ready
                    Layout.fillWidth: true
                    spacing: 4
                    Item { Layout.preferredHeight: 16 }
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: Weather.error ? "\uf071" : "\uf017"
                        color: Rock.pink
                        font.pixelSize: 36
                    }
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: Weather.error ? I18n.t("ПОГОДА СБЕЖАЛА") : I18n.t("НАСТРАИВАЕМ АНПУТ")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 18
                        font.letterSpacing: 0.4
                    }
                    Lbl {
                        Layout.alignment: Qt.AlignHCenter
                        text: Weather.error ? I18n.t("не удалось получить прогноз") : I18n.t("загружаем небо…")
                        color: Rock.uiSub
                        font.pixelSize: 11
                    }
                    Item { Layout.preferredHeight: 20 }
                }

                Rectangle {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    implicitHeight: 138
                    radius: Rock.comic ? 15 : 12
                    color: Rock.uiSurface2
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge

                    Canvas {
                        width: 124
                        height: 82
                        anchors.right: parent.right
                        anchors.top: parent.top
                        opacity: 0.17
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            ctx.fillStyle = Rock.pink
                            for (let y = 5; y < height; y += 7)
                                for (let x = 5; x < width; x += 7) {
                                    ctx.beginPath()
                                    ctx.arc(x, y, 1.15, 0, Math.PI * 2)
                                    ctx.fill()
                                }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Item {
                            Layout.preferredWidth: 94
                            Layout.preferredHeight: 94
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                x: 3
                                y: 4
                                width: 88
                                height: 88
                                radius: 44
                                color: Rock.pinkDeep
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                rotation: Rock.comic ? -5 : 0
                                transformOrigin: Item.Center
                            }
                            Rectangle {
                                width: 88
                                height: 88
                                radius: 44
                                color: Rock.yellow
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                rotation: Rock.comic ? -5 : 0
                                transformOrigin: Item.Center
                            }
                            Lbl {
                                anchors.centerIn: parent
                                text: Weather.icon
                                color: Rock.ink
                                font.pixelSize: 46
                                rotation: Rock.comic ? -5 : 0
                            }
                            RockChip {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -2
                                fill: Rock.pink
                                shadowColor: Rock.ink
                                offset: 1.5
                                radius: 6
                                padH: 6
                                padV: 1
                                Lbl {
                                    text: I18n.t("СЕЙЧАС")
                                    color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                                    font.pixelSize: 7
                                    font.weight: Font.Black
                                    font.letterSpacing: 1.1
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Item {
                                Layout.preferredWidth: tempText.width + 5
                                Layout.preferredHeight: tempText.height + 5
                                Lbl {
                                    x: 3
                                    y: 3
                                    text: Weather.temp + "°"
                                    color: Rock.pinkDeep
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 48
                                    font.letterSpacing: -1.6
                                }
                                Lbl {
                                    x: 1.5
                                    y: 1.5
                                    text: Weather.temp + "°"
                                    color: Rock.cyan
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 48
                                    font.letterSpacing: -1.6
                                }
                                Lbl {
                                    id: tempText
                                    text: Weather.temp + "°"
                                    color: Rock.uiText
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 48
                                    font.letterSpacing: -1.6
                                }
                            }

                            Lbl {
                                Layout.fillWidth: true
                                text: Weather.desc
                                color: Rock.uiSub
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            RockChip {
                                fill: Rock.uiSurface2
                                shadowColor: Rock.cyan
                                offset: 1.5
                                radius: 6
                                padH: 6
                                padV: 1
                                Lbl {
                                    text: I18n.t("ОЩУЩ ") + Weather.feels + "°"
                                    color: Rock.uiSub
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.4
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 5

                            RockChip {
                                Layout.alignment: Qt.AlignRight
                                fill: Rock.yellow
                                shadowColor: Rock.pink
                                offset: 1.5
                                radius: 6
                                padH: 6
                                padV: 2
                                Lbl {
                                    text: I18n.t("МАКС ") + (pop.today ? pop.today.hi : "–") + "°"
                                    color: Rock.ink
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                }
                            }
                            RockChip {
                                Layout.alignment: Qt.AlignRight
                                fill: Rock.cyan
                                shadowColor: Rock.ink
                                offset: 1.5
                                radius: 6
                                padH: 6
                                padV: 2
                                Lbl {
                                    text: I18n.t("МИН ") + (pop.today ? pop.today.lo : "–") + "°"
                                    color: Rock.marisa ? Rock.cream : Rock.ink
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                }
                            }
                        }
                    }
                }

                RockChip {
                    Layout.alignment: Qt.AlignHCenter
                    visible: Weather.ready && Weather.nextPrecip >= 40
                    fill: Rock.pink
                    shadowColor: Rock.yellow
                    offset: 2
                    radius: 7
                    padH: 9
                    padV: 2
                    Lbl {
                        text: I18n.t("\uf043 ВОЗЬМИ ЗОНТ · ") + Weather.nextPrecip + "%"
                        color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                        font.pixelSize: 9
                        font.weight: Font.Black
                        font.letterSpacing: 0.5
                    }
                }

                RowLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    Layout.topMargin: 1
                    spacing: 7

                    Repeater {
                        model: [
                            { icon: "\uf043", value: Weather.humidity + "%", label: I18n.t("ВЛАЖНОСТЬ"), fill: Rock.cyan, tilt: -1.5, lightText: true },
                            { icon: "\ue31e", value: Weather.wind + I18n.t(" км/ч"), label: I18n.t("ВЕТЕР ") + Weather.windDir, fill: Rock.yellow, tilt: 1.2, lightText: false },
                            { icon: "\ue30d", value: Weather.uv === "" ? "–" : Weather.uv, label: I18n.t("УФ-ИНДЕКС"), fill: Rock.pink, tilt: -1.0, lightText: true },
                            { icon: "\uf0e4", value: Weather.pressure, label: I18n.t("ДАВЛЕНИЕ"), fill: Rock.paper, tilt: 1.4 }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 64
                            radius: 11
                            color: modelData.fill
                            border.width: 2
                            border.color: Rock.ink
                            rotation: modelData.tilt

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Lbl {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: Rock.marisa && modelData.lightText ? Rock.cream : Rock.ink
                                    font.pixelSize: 13
                                }
                                Lbl {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.value
                                    color: Rock.marisa && modelData.lightText ? Rock.cream : Rock.ink
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 13
                                }
                                Lbl {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: Rock.marisa && modelData.lightText ? Rock.a(Rock.cream, 0.78) : Rock.ink2
                                    font.pixelSize: 7
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.3
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    implicitHeight: 140
                    radius: Rock.comic ? 13 : 12
                    color: Rock.uiSurface
                    border.width: Rock.uiBorder
                    border.color: Rock.uiEdge

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Lbl {
                                text: "\uf001"
                                color: Rock.pink
                                font.pixelSize: 11
                            }
                            Lbl {
                                text: I18n.t("БЛИЖАЙШИЕ ЧАСЫ")
                                color: Rock.uiText
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 9
                                font.letterSpacing: 1.4
                            }
                            Item { Layout.fillWidth: true }
                            Lbl {
                                visible: pop.hasPop
                                text: "\uf043 " + Weather.nextPrecip + "%"
                                color: Rock.cyan
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Repeater {
                                model: Weather.hourly
                                delegate: Lbl {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.temp + "°"
                                    color: Rock.yellow
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Canvas {
                            id: chart
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            onWidthChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            Connections {
                                target: Weather
                                function onHourlyChanged() { chart.requestPaint() }
                            }
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()
                                const h = Weather.hourly
                                if (!h || h.length < 2) return
                                let mn = 1e9, mx = -1e9
                                for (let i = 0; i < h.length; i++) {
                                    mn = Math.min(mn, h[i].temp)
                                    mx = Math.max(mx, h[i].temp)
                                }
                                const n = h.length, pad = 9
                                const xs = i => (i + 0.5) * width / n
                                const ys = v => mx === mn ? height / 2 : pad + (1 - (v - mn) / (mx - mn)) * (height - 2 * pad)

                                ctx.fillStyle = Rock.a(Rock.cyan, 0.10)
                                for (let y = 4; y < height; y += 8)
                                    for (let x = 4; x < width; x += 8) {
                                        ctx.beginPath()
                                        ctx.arc(x, y, 1.1, 0, Math.PI * 2)
                                        ctx.fill()
                                    }

                                function path() {
                                    ctx.beginPath()
                                    ctx.moveTo(xs(0), ys(h[0].temp))
                                    for (let i = 1; i < n; i++) {
                                        const x0 = xs(i - 1), y0 = ys(h[i - 1].temp)
                                        const x1 = xs(i), y1 = ys(h[i].temp)
                                        ctx.bezierCurveTo((x0 + x1) / 2, y0, (x0 + x1) / 2, y1, x1, y1)
                                    }
                                }

                                path()
                                ctx.strokeStyle = Rock.uiText
                                ctx.lineWidth = 5
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"
                                ctx.stroke()

                                path()
                                ctx.strokeStyle = Rock.pink
                                ctx.lineWidth = 3
                                ctx.stroke()

                                ctx.lineTo(xs(n - 1), height)
                                ctx.lineTo(xs(0), height)
                                ctx.closePath()
                                ctx.fillStyle = Rock.a(Rock.pink, 0.16)
                                ctx.fill()

                                for (let i = 0; i < n; i++) {
                                    ctx.beginPath()
                                    ctx.arc(xs(i), ys(h[i].temp), 3.4, 0, Math.PI * 2)
                                    ctx.fillStyle = Rock.yellow
                                    ctx.fill()
                                    ctx.strokeStyle = Rock.ink
                                    ctx.lineWidth = 1.5
                                    ctx.stroke()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Repeater {
                                model: Weather.hourly
                                delegate: Lbl {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.label
                                    color: Rock.a(Rock.uiText, 0.55)
                                    font.pixelSize: 9
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            visible: pop.hasPop
                            Repeater {
                                model: Weather.hourly
                                delegate: Lbl {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.pop >= 10 ? modelData.pop + "%" : ""
                                    color: Rock.cyan
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 6

                    Lbl {
                        text: I18n.t("СЕТ-ЛИСТ")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 13
                        font.letterSpacing: 1.2
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Rock.a(Rock.uiText, 0.2)
                    }
                    RockChip {
                        fill: Rock.pink
                        shadowColor: Rock.yellow
                        offset: 1.5
                        radius: 5
                        padH: 6
                        padV: 1
                        Lbl {
                            text: I18n.t("3 ДНЯ")
                            color: Rock.comic || Rock.marisa ? Rock.cream : Rock.ink
                            font.pixelSize: 7
                            font.weight: Font.Black
                            font.letterSpacing: 0.8
                        }
                    }
                }

                ColumnLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: Weather.days
                        delegate: Rectangle {
                            id: ticket
                            required property var modelData
                            required property int index

                            readonly property real lo: (modelData.lo - pop.dayMin) / Math.max(1, pop.dayMax - pop.dayMin)
                            readonly property real hi: (modelData.hi - pop.dayMin) / Math.max(1, pop.dayMax - pop.dayMin)
                            readonly property real span: Math.max(0, hi - lo)

                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: Rock.comic ? 10 : 9
                            color: index === 0 ? (Rock.comic ? Rock.yellow : Rock.uiActive) : Rock.uiSurface2
                            border.width: Rock.uiBorder
                            border.color: Rock.uiEdge

                            Rectangle {
                                width: 7
                                height: parent.height - 10
                                radius: 3.5
                                anchors.left: parent.left
                                anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                color: index === 0 ? Rock.pink : (index === 1 ? Rock.cyan : Rock.purple)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 17
                                anchors.rightMargin: 10
                                spacing: 7

                                Lbl {
                                    Layout.preferredWidth: 56
                                    text: modelData.label
                                    color: Rock.uiText
                                    font.family: Rock.display
                                    font.weight: Font.Black
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Lbl {
                                    Layout.preferredWidth: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.icon
                                    color: Rock.uiSub
                                    font.pixelSize: 13
                                }
                                Lbl {
                                    Layout.fillWidth: true
                                    text: modelData.desc
                                    color: Rock.uiSub
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                                Item {
                                    id: range
                                    Layout.preferredWidth: 54
                                    Layout.preferredHeight: 8
                                    readonly property real startX: Math.min(range.width - 6, range.width * ticket.lo)

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: 5
                                        radius: 2.5
                                        color: Rock.a(Rock.uiText, 0.16)
                                    }
                                    Rectangle {
                                        x: range.startX
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(5, Math.min(range.width - range.startX, range.width * ticket.span))
                                        height: 7
                                        radius: 3.5
                                        color: Rock.pink
                                        border.width: 1
                                        border.color: Rock.uiEdge
                                    }
                                }
                                Lbl {
                                    Layout.preferredWidth: 24
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.lo + "°"
                                    color: Rock.uiSub
                                    font.pixelSize: 10
                                }
                                Lbl {
                                    Layout.preferredWidth: 27
                                    horizontalAlignment: Text.AlignRight
                                    text: modelData.hi + "°"
                                    color: Rock.pinkDeep
                                    font.weight: Font.Black
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: Rock.comic
            x: 22
            y: -6
            width: 74
            height: 18
            radius: 2
            color: Rock.a(Rock.yellow, 0.85)
            border.width: 1
            border.color: Rock.a(Rock.ink, 0.25)
            rotation: -7
            z: 20
        }
        Rectangle {
            visible: Rock.comic
            x: card.width - 96
            y: -6
            width: 74
            height: 18
            radius: 2
            color: Rock.a(Rock.cyan, 0.7)
            border.width: 1
            border.color: Rock.a(Rock.ink, 0.25)
            rotation: 6
            z: 20
        }
        Lbl {
            visible: Rock.comic
            x: card.width - 24
            y: card.height - 6
            text: "\uf005"
            color: Rock.yellow
            font.pixelSize: 16
            rotation: 14
            z: 20
        }
    }
}
