import QtQuick
import QtQuick.Layouts
import Quickshell

BarPopup {
    id: pop
    alignment: "center"
    implicitWidth: 340
    implicitHeight: content.implicitHeight + 32

    onVisibleChanged: if (visible) Weather.refresh(false)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        Lbl {
            visible: !Weather.ready
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 20
            text: Weather.error ? "Не удалось получить погоду" : "Загрузка…"
            color: Theme.muted
        }

        ColumnLayout {
            visible: Weather.ready
            Layout.fillWidth: true
            spacing: 14

            // Сейчас
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Lbl { text: Weather.icon; color: Theme.accent; font.pixelSize: 40 }
                ColumnLayout {
                    spacing: 0
                    Lbl { text: Weather.temp + "°"; font.pixelSize: 32; font.bold: true }
                    Lbl { text: Weather.desc; color: Theme.muted }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 2
                    Lbl { Layout.alignment: Qt.AlignRight; text: Weather.city; color: Theme.muted; font.pixelSize: 11 }
                    Lbl { Layout.alignment: Qt.AlignRight; text: "Ощущается " + Weather.feels + "°"; color: Theme.muted; font.pixelSize: 11 }
                }
            }

            // Плашки
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [
                        { i: "\uf043", t: Weather.humidity + "%",                 l: "Влажность" },
                        { i: "\ue31e", t: Weather.wind + " км/ч",                 l: "Ветер " + Weather.windDir },
                        { i: "\ue30d", t: Weather.uv === "" ? "–" : Weather.uv,   l: "УФ-индекс" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 60
                        radius: 14
                        color: Theme.surface
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1
                            Lbl { Layout.alignment: Qt.AlignHCenter; text: modelData.i; color: Theme.accent2; font.pixelSize: 13 }
                            Lbl { Layout.alignment: Qt.AlignHCenter; text: modelData.t; font.bold: true }
                            Lbl { Layout.alignment: Qt.AlignHCenter; text: modelData.l; color: Theme.muted; font.pixelSize: 9 }
                        }
                    }
                }
            }

            // Почасовой график
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

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
                            font.pixelSize: 11
                        }
                    }
                }

                Canvas {
                    id: chart
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    onWidthChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    Connections {
                        target: Weather
                        function onHourlyChanged() { chart.requestPaint() }
                    }
                    Connections {
                        target: Theme
                        function onAccentChanged() { chart.requestPaint() }
                    }
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const h = Weather.hourly
                        if (!h || h.length < 2) return
                        let mn = 1e9, mx = -1e9
                        for (let i = 0; i < h.length; i++) { mn = Math.min(mn, h[i].temp); mx = Math.max(mx, h[i].temp) }
                        const n = h.length, pad = 10
                        const xs = i => (i + 0.5) * width / n
                        const ys = v => mx === mn ? height / 2 : pad + (1 - (v - mn) / (mx - mn)) * (height - 2 * pad)

                        ctx.beginPath()
                        ctx.moveTo(xs(0), ys(h[0].temp))
                        for (let i = 1; i < n; i++) {
                            const x0 = xs(i - 1), y0 = ys(h[i - 1].temp), x1 = xs(i), y1 = ys(h[i].temp)
                            ctx.bezierCurveTo((x0 + x1) / 2, y0, (x0 + x1) / 2, y1, x1, y1)
                        }
                        ctx.strokeStyle = Theme.accent
                        ctx.lineWidth = 2
                        ctx.stroke()

                        ctx.lineTo(xs(n - 1), height)
                        ctx.lineTo(xs(0), height)
                        ctx.closePath()
                        ctx.fillStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                        ctx.fill()

                        for (let i = 0; i < n; i++) {
                            ctx.beginPath()
                            ctx.arc(xs(i), ys(h[i].temp), 3, 0, Math.PI * 2)
                            ctx.fillStyle = Theme.accent
                            ctx.fill()
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
                            color: Theme.muted
                            font.pixelSize: 10
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            // Прогноз на дни
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Weather.days
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Lbl { Layout.preferredWidth: 70; text: modelData.label }
                        Lbl { text: modelData.icon; color: Theme.accent2; font.pixelSize: 14; Layout.preferredWidth: 22 }
                        Lbl { Layout.fillWidth: true; text: modelData.desc; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
                        Lbl { text: modelData.lo + "°"; color: Theme.muted }
                        Lbl { text: modelData.hi + "°"; font.bold: true; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }
    }
}
