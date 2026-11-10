import QtQuick
import QtQuick.Layouts
import Quickshell

// «Атмосферная станция»: погодный пульт с живым шаром, шкалой-барометром
// и лентой ближайших часов. Всё рисуется на палитре обоев.
BarPopup {
    id: pop
    alignment: "center"
    implicitWidth: 452
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
    readonly property string tempLabel: Weather.temp === "" ? "–" : Weather.temp
    readonly property real curFrac: {
        const t = Number(Weather.temp)
        if (isNaN(t) || dayMax <= dayMin) return 0.5
        return Math.max(0, Math.min(1, (t - dayMin) / (dayMax - dayMin)))
    }

    function css(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
                + Math.round(c.b * 255) + "," + a + ")"
    }

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 8

        Rectangle {
            id: card
            width: 424
            height: layout.implicitHeight + 32
            radius: Rock.uiRadius + 6
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: Rock.a(Rock.pink, 0.35)
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.lighter(Rock.uiSurface, 1.10) }
                    GradientStop { position: 1.0; color: Qt.darker(Rock.uiSurface, 1.06) }
                }

                Canvas {
                    anchors.fill: parent
                    opacity: 0.6
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = pop.css(Rock.uiText, 0.05)
                        for (let y = 12; y < height; y += 16)
                            for (let x = 12; x < width; x += 16) {
                                ctx.beginPath()
                                ctx.arc(x, y, 0.9, 0, Math.PI * 2)
                                ctx.fill()
                            }
                    }
                }
            }

            Canvas {
                anchors.fill: parent
                opacity: 0.7
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const L = 10, m = 8
                    ctx.strokeStyle = pop.css(Rock.pink, 0.35)
                    ctx.lineWidth = 1.4
                    ctx.lineCap = "round"
                    const xs = [m, width - m, m, width - m]
                    const ys = [m, m, height - m, height - m]
                    const sx = [1, -1, 1, -1]
                    const sy = [1, 1, -1, -1]
                    for (let i = 0; i < 4; i++) {
                        ctx.beginPath()
                        ctx.moveTo(xs[i] + sx[i] * L, ys[i])
                        ctx.lineTo(xs[i], ys[i])
                        ctx.lineTo(xs[i], ys[i] + sy[i] * L)
                        ctx.stroke()
                    }
                }
            }

            ColumnLayout {
                id: layout
                x: 18
                y: 16
                width: card.width - 36
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Rock.pink
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 900 }
                            NumberAnimation { to: 1.0; duration: 900 }
                        }
                    }
                    Lbl {
                        text: I18n.t("ПОГОДА")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.weight: Font.Black
                        font.pixelSize: 20
                        font.letterSpacing: 0.5
                    }
                    Lbl {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 4
                        text: "/ " + I18n.t("АТМОСФЕРА")
                        color: Rock.a(Rock.uiText, 0.4)
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 2.0
                    }
                    Item { Layout.fillWidth: true }
                    RockChip {
                        visible: Weather.city !== ""
                        fill: Rock.uiSurface2
                        shadowColor: Rock.pink
                        offset: 0
                        radius: 7
                        padH: 8
                        padV: 3
                        Lbl {
                            Layout.maximumWidth: 130
                            elide: Text.ElideRight
                            text: Weather.city.toUpperCase()
                            color: Rock.uiText
                            font.pixelSize: 9
                            font.weight: Font.Black
                            font.letterSpacing: 0.8
                        }
                    }
                }

                // ───────── загрузка ─────────
                ColumnLayout {
                    visible: !Weather.ready
                    Layout.fillWidth: true
                    spacing: 6
                    Item { Layout.preferredHeight: 6 }
                    WeatherOrb {
                        Layout.alignment: Qt.AlignHCenter
                        width: 104
                        height: 104
                        code: 2
                        isDay: true
                        active: pop.visible
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
                    Item { Layout.preferredHeight: 14 }
                }

                // ───────── главный блок ─────────
                RowLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 176
                        Layout.preferredHeight: 176

                        Canvas {
                            id: dial
                            anchors.fill: parent
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()
                                const w = width, h = height
                                if (w <= 0 || h <= 0) return
                                const cx = w / 2, cy = h / 2
                                const R = Math.min(w, h) / 2 - 6
                                const start = Math.PI * 0.75
                                const sweep = Math.PI * 1.5
                                const frac = pop.curFrac
                                const TAU = Math.PI * 2

                                // деления барометра
                                for (let i = 0; i <= 54; i++) {
                                    const a = start + sweep * i / 54
                                    const major = i % 9 === 0
                                    const r0 = R - (major ? 12 : 6)
                                    ctx.strokeStyle = pop.css(Rock.uiText, major ? 0.5 : 0.16)
                                    ctx.lineWidth = major ? 1.6 : 1
                                    ctx.beginPath()
                                    ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0)
                                    ctx.lineTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R)
                                    ctx.stroke()
                                }

                                // дорожка диапазона
                                ctx.strokeStyle = pop.css(Rock.uiText, 0.12)
                                ctx.lineWidth = 5
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(cx, cy, R - 16, start, start + sweep)
                                ctx.stroke()

                                // текущая температура на шкале
                                if (frac > 0.002) {
                                    const grad = ctx.createLinearGradient(cx - R, cy - R, cx + R, cy + R)
                                    grad.addColorStop(0, pop.css(Rock.cyan, 1))
                                    grad.addColorStop(1, pop.css(Rock.pink, 1))
                                    ctx.strokeStyle = grad
                                    ctx.lineWidth = 5
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, R - 16, start, start + sweep * frac)
                                    ctx.stroke()
                                }

                                const ea = start + sweep * frac
                                const ex = cx + Math.cos(ea) * (R - 16)
                                const ey = cy + Math.sin(ea) * (R - 16)
                                ctx.fillStyle = pop.css(Rock.pink, 0.30)
                                ctx.beginPath()
                                ctx.arc(ex, ey, 9, 0, TAU)
                                ctx.fill()
                                ctx.fillStyle = pop.css(Rock.pink, 1)
                                ctx.beginPath()
                                ctx.arc(ex, ey, 4.2, 0, TAU)
                                ctx.fill()
                                ctx.strokeStyle = pop.css(Rock.uiSurface, 1)
                                ctx.lineWidth = 1.5
                                ctx.stroke()
                            }
                        }

                        WeatherOrb {
                            id: orb
                            anchors.centerIn: parent
                            width: 112
                            height: 112
                            code: Weather.code
                            isDay: Weather.isDay
                            active: pop.visible
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            spacing: 4
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 5
                                height: 5
                                radius: 2.5
                                color: Rock.cyan
                            }
                            Lbl {
                                text: "LIVE"
                                color: Rock.a(Rock.uiText, 0.55)
                                font.pixelSize: 8
                                font.weight: Font.Black
                                font.letterSpacing: 1.6
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        Item {
                            Layout.preferredWidth: tempText.width + 4
                            Layout.preferredHeight: tempText.height + 4
                            Lbl {
                                x: 2.5
                                y: 2.5
                                text: pop.tempLabel + "°"
                                color: Rock.a(Rock.cyan, 0.35)
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 60
                                font.letterSpacing: -3
                            }
                            Lbl {
                                id: tempText
                                text: pop.tempLabel + "°"
                                color: Rock.uiText
                                font.family: Rock.display
                                font.weight: Font.Black
                                font.pixelSize: 60
                                font.letterSpacing: -3
                            }
                        }

                        Lbl {
                            Layout.fillWidth: true
                            text: Weather.desc !== "" ? Weather.desc : "—"
                            color: Rock.uiText
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Lbl {
                            Layout.fillWidth: true
                            text: I18n.t("ОЩУЩАЕТСЯ") + " " + (Weather.feels === "" ? "–" : Weather.feels) + "°"
                            color: Rock.uiSub
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 1.0
                        }

                        Item { Layout.preferredHeight: 4 }

                        RowLayout {
                            spacing: 6
                            RockChip {
                                fill: Rock.a(Rock.cyan, 0.16)
                                shadowColor: Rock.cyan
                                offset: 0
                                radius: 6
                                padH: 7
                                padV: 2
                                Lbl {
                                    text: I18n.t("МИН ") + (pop.today ? pop.today.lo : "–") + "°"
                                    color: Rock.uiText
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                }
                            }
                            RockChip {
                                fill: Rock.a(Rock.pink, 0.16)
                                shadowColor: Rock.pink
                                offset: 0
                                radius: 6
                                padH: 7
                                padV: 2
                                Lbl {
                                    text: I18n.t("МАКС ") + (pop.today ? pop.today.hi : "–") + "°"
                                    color: Rock.uiText
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                }
                            }
                        }
                    }
                }

                // ───────── метрики ─────────
                RowLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: [
                            { icon: "\uf043", value: (Weather.humidity === "" ? "–" : Weather.humidity + "%"), label: I18n.t("ВЛАЖНОСТЬ"), tint: Rock.cyan },
                            { icon: "\ue31e", value: (Weather.wind === "" ? "–" : Weather.wind + I18n.t(" км/ч")), label: I18n.t("ВЕТЕР ") + Weather.windDir, tint: Rock.pink },
                            { icon: "\ue30d", value: (Weather.uv === "" ? "–" : Weather.uv), label: I18n.t("УФ-ИНДЕКС"), tint: Rock.yellow },
                            { icon: "\uf0e4", value: (Weather.pressure === "" ? "–" : Weather.pressure), label: I18n.t("ДАВЛЕНИЕ"), tint: Rock.uiText }
                        ]
                        delegate: Item {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 44

                            Rectangle {
                                visible: index > 0
                                width: 1
                                height: parent.height - 12
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                color: Rock.a(Rock.uiText, 0.10)
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 5
                                    Lbl {
                                        text: modelData.icon
                                        color: modelData.tint
                                        font.pixelSize: 12
                                    }
                                    Lbl {
                                        text: modelData.value
                                        color: Rock.uiText
                                        font.family: Rock.display
                                        font.weight: Font.Black
                                        font.pixelSize: 14
                                    }
                                }
                                Lbl {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 92
                                    elide: Text.ElideRight
                                    text: modelData.label
                                    color: Rock.uiSub
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.7
                                }
                            }
                        }
                    }
                }

                // ───────── ближайшие часы ─────────
                Rectangle {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    implicitHeight: hourlyCol.implicitHeight + 24
                    radius: Rock.uiRadiusSm
                    color: Rock.a(Rock.uiSurface2, 0.75)
                    border.width: Rock.uiBorder
                    border.color: Rock.a(Rock.uiText, 0.08)

                    ColumnLayout {
                        id: hourlyCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Lbl {
                                text: "\uf0c2"
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
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    spacing: 0
                                    Lbl {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        color: Rock.uiSub
                                        font.pixelSize: 12
                                    }
                                    Lbl {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.temp + "°"
                                        color: Rock.uiText
                                        font.family: Rock.display
                                        font.weight: Font.Black
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }

                        Canvas {
                            id: ribbon
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()
                                const h = Weather.hourly
                                if (!h || h.length < 2) return
                                const n = h.length
                                const w = width
                                const pad = 7
                                const TAU = Math.PI * 2
                                let mn = 1e9, mx = -1e9
                                for (let i = 0; i < n; i++) {
                                    mn = Math.min(mn, h[i].temp)
                                    mx = Math.max(mx, h[i].temp)
                                }
                                const xs = i => (i + 0.5) * w / n
                                const ys = v => mx === mn ? height / 2
                                    : pad + (1 - (v - mn) / (mx - mn)) * (height - 2 * pad)

                                // столбики осадков за графиком
                                for (let i = 0; i < n; i++) {
                                    const p = h[i].pop || 0
                                    if (p <= 0) continue
                                    const bh = (p / 100) * (height - pad * 2)
                                    const bw = Math.max(4, w / n * 0.5)
                                    ctx.fillStyle = pop.css(Rock.cyan, 0.14)
                                    ctx.fillRect(xs(i) - bw / 2, height - pad - bh, bw, bh)
                                }

                                function trace() {
                                    ctx.beginPath()
                                    ctx.moveTo(xs(0), ys(h[0].temp))
                                    for (let i = 1; i < n; i++) {
                                        const x0 = xs(i - 1), y0 = ys(h[i - 1].temp)
                                        const x1 = xs(i), y1 = ys(h[i].temp)
                                        ctx.bezierCurveTo((x0 + x1) / 2, y0, (x0 + x1) / 2, y1, x1, y1)
                                    }
                                }

                                trace()
                                ctx.lineTo(xs(n - 1), height - pad)
                                ctx.lineTo(xs(0), height - pad)
                                ctx.closePath()
                                const g = ctx.createLinearGradient(0, 0, 0, height)
                                g.addColorStop(0, pop.css(Rock.pink, 0.30))
                                g.addColorStop(1, pop.css(Rock.pink, 0.0))
                                ctx.fillStyle = g
                                ctx.fill()

                                trace()
                                ctx.strokeStyle = pop.css(Rock.pink, 0.16)
                                ctx.lineWidth = 7
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"
                                ctx.stroke()

                                trace()
                                ctx.strokeStyle = pop.css(Rock.pink, 1)
                                ctx.lineWidth = 2.2
                                ctx.stroke()

                                for (let i = 0; i < n; i++) {
                                    ctx.beginPath()
                                    ctx.arc(xs(i), ys(h[i].temp), 2.6, 0, TAU)
                                    ctx.fillStyle = pop.css(Rock.uiSurface2, 1)
                                    ctx.fill()
                                    ctx.strokeStyle = pop.css(Rock.pink, 1)
                                    ctx.lineWidth = 1.6
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
                                    color: Rock.a(Rock.uiText, 0.5)
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

                // ───────── три дня ─────────
                RowLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: Weather.days
                        delegate: Rectangle {
                            id: dayCard
                            required property var modelData
                            required property int index

                            readonly property real loFrac: Math.max(0, Math.min(1,
                                (modelData.lo - pop.dayMin) / Math.max(1, pop.dayMax - pop.dayMin)))
                            readonly property real hiFrac: Math.max(0, Math.min(1,
                                (modelData.hi - pop.dayMin) / Math.max(1, pop.dayMax - pop.dayMin)))

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 96
                            radius: Rock.uiRadiusSm
                            color: index === 0 ? Rock.uiActive : Rock.a(Rock.uiSurface2, 0.75)
                            border.width: Rock.uiBorder
                            border.color: index === 0 ? Rock.a(Rock.pink, 0.45) : Rock.a(Rock.uiText, 0.08)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Lbl {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: modelData.label.toUpperCase()
                                        color: index === 0 ? Rock.uiText : Rock.uiSub
                                        font.pixelSize: 8
                                        font.weight: Font.Black
                                        font.letterSpacing: 1.0
                                    }
                                    Lbl {
                                        text: modelData.icon
                                        color: index === 0 ? Rock.pink : Rock.uiSub
                                        font.pixelSize: 13
                                    }
                                }

                                RowLayout {
                                    spacing: 5
                                    Lbl {
                                        text: modelData.hi + "°"
                                        color: Rock.uiText
                                        font.family: Rock.display
                                        font.weight: Font.Black
                                        font.pixelSize: 22
                                        font.letterSpacing: -0.6
                                    }
                                    Lbl {
                                        Layout.alignment: Qt.AlignBottom
                                        Layout.bottomMargin: 2
                                        text: modelData.lo + "°"
                                        color: Rock.uiSub
                                        font.pixelSize: 11
                                    }
                                }

                                Lbl {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.desc
                                    color: Rock.uiSub
                                    font.pixelSize: 8
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 5
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 2.5
                                        color: Rock.a(Rock.uiText, 0.12)
                                    }
                                    Rectangle {
                                        x: parent.width * dayCard.loFrac
                                        width: Math.max(4, parent.width * Math.max(0.02, dayCard.hiFrac - dayCard.loFrac))
                                        height: parent.height
                                        radius: 2.5
                                        color: index === 0 ? Rock.pink : Rock.cyan
                                    }
                                }
                            }
                        }
                    }
                }

                // ───────── подвал ─────────
                RowLayout {
                    visible: Weather.ready
                    Layout.fillWidth: true
                    spacing: 7

                    Lbl {
                        text: "\ue30d"
                        color: Rock.yellow
                        font.pixelSize: 11
                    }
                    Lbl {
                        text: I18n.t("ВОСХОД") + " " + (Weather.sunrise === "" ? "–" : Weather.sunrise)
                        color: Rock.uiSub
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 0.4
                    }
                    Rectangle {
                        width: 1
                        height: 9
                        color: Rock.a(Rock.uiText, 0.15)
                    }
                    Lbl {
                        text: "\ue32b"
                        color: Rock.purple
                        font.pixelSize: 11
                    }
                    Lbl {
                        text: I18n.t("ЗАКАТ") + " " + (Weather.sunset === "" ? "–" : Weather.sunset)
                        color: Rock.uiSub
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 0.4
                    }
                    Item { Layout.fillWidth: true }
                    Lbl {
                        text: "OPEN-METEO"
                        color: Rock.a(Rock.uiText, 0.32)
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }
            }
        }
    }

    Connections {
        target: Weather
        function onHourlyChanged() { ribbon.requestPaint() }
        function onTempChanged() { dial.requestPaint() }
        function onDaysChanged() { dial.requestPaint() }
    }
}
