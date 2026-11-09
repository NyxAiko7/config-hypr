import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: UI.wallpaper
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.keyboardFocus: UI.wallpaper ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    property bool browsing: false

    function plural(n) {
        const a = n % 10, b = n % 100
        if (a === 1 && b !== 11) return n + I18n.t(" изображение")
        if (a >= 2 && a <= 4 && (b < 10 || b >= 20)) return n + I18n.t(" изображения")
        return n + I18n.t(" изображений")
    }
    function openBrowse() { browsing = true; Wallpapers.browse(Wallpapers.dir) }

    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
    }

    onVisibleChanged: {
        if (visible) {
            Wallpapers.refresh()
            keys.forceActiveFocus()
            fade.restart()
        } else browsing = false
    }

    // ── фон: полутон, лучи и летящие ноты ──
    Rectangle {
        id: dim
        anchors.fill: parent
        color: Rock.sao ? Rock.a(Rock.ink, 0.90) : Rock.a(Rock.uiText, 0.82)

        Canvas {
            anchors.fill: parent
            opacity: 0.7
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const step = Math.max(18, Math.min(width, height) / 48)
                ctx.fillStyle = Rock.a(Rock.pink, 0.22)
                for (let y = 0; y < height; y += step) {
                    for (let x = 0; x < width; x += step) {
                        ctx.beginPath()
                        ctx.arc(x, y, step * 0.13, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
                ctx.strokeStyle = Rock.a(Rock.cyan, 0.10)
                ctx.lineWidth = 2
                for (let x = -height; x < width; x += step * 3) {
                    ctx.beginPath()
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x + height, height)
                    ctx.stroke()
                }
            }
        }

        Rectangle {
            width: parent.width * 0.5; height: parent.height * 1.8
            x: -parent.width * 0.22; y: -parent.height * 0.8
            rotation: -16
            color: Rock.a(Rock.pink, 0.10)
        }
        Rectangle {
            width: parent.width * 0.38; height: parent.height * 1.8
            x: parent.width * 0.55; y: -parent.height * 0.8
            rotation: 14
            color: Rock.a(Rock.cyan, 0.08)
        }

        Repeater {
            model: 10
            delegate: Text {
                required property int index
                x: (index * 197 + 80) % Math.max(1, dim.width)
                y: dim.height + 60
                text: ["\uf001", "\uf005", "\uf004", "\uf008"][index % 4]
                color: [Rock.pink, Rock.cyan, Rock.yellow, Rock.purple][index % 4]
                opacity: 0.16 + (index % 3) * 0.05
                font.family: Theme.font
                font.pixelSize: 16 + (index % 4) * 8
                NumberAnimation on y {
                    from: dim.height + 60
                    to: -70
                    duration: 9000 + index * 900
                    loops: Animation.Infinite
                    running: win.visible
                }
                NumberAnimation on rotation {
                    from: -20; to: 20
                    duration: 3800 + index * 340
                    loops: Animation.Infinite
                    running: win.visible
                    easing.type: Easing.InOutSine
                }
            }
        }

        MouseArea { anchors.fill: parent; onClicked: UI.wallpaper = false }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: { if (win.browsing) win.browsing = false; else UI.wallpaper = false }
    }

    // ── «гитарный кейс»: карточка с толстым контуром и тенью ──
    Item {
        id: frame
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 940)
        height: Math.min(parent.height - 100, 646)
        rotation: Rock.comic ? -0.35 : 0
        opacity: 0
        scale: 0.96

        Rectangle {
            visible: Rock.comic
            x: 9; y: 9
            width: frame.width; height: frame.height
            radius: 27
            color: Rock.pink
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge
        }

        Rectangle {
            id: card
            width: frame.width; height: frame.height
            radius: Rock.comic ? 24 : Rock.marisa ? 10 : Rock.sao ? 5 : 17
            color: Rock.uiSurface
            border.width: Rock.uiBorder
            border.color: Rock.uiEdge

            MouseArea { anchors.fill: parent }

            SaoGrid {
                anchors.fill: parent
                step: 30
            }

            MarisaFrame {
                anchors.fill: parent
                inset: 7
                frameRadius: Math.max(2, card.radius - 5)
            }

            SaoFrame {
                anchors.fill: parent
                inset: 6
                cut: 12
                segments: 30
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 4

                        RowLayout {
                            spacing: 9
                            Rectangle {
                                width: 9; height: 28
                                radius: 4
                                color: Rock.pink
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                rotation: Rock.comic ? -7 : 0
                            }
                            Lbl {
                                text: I18n.t("ОБОИ")
                                color: Rock.uiText
                                font.family: Rock.display
                                font.pixelSize: 31
                                font.weight: Font.Black
                                font.letterSpacing: 1.5
                            }
                            RockChip {
                                fill: Rock.yellow
                                shadowColor: Rock.pink
                                offset: 2
                                padH: 8; padV: 2; radius: 6
                                rotation: Rock.comic ? -3 : 0
                                Lbl {
                                    text: Rock.comic ? "BOCCHI THE ROCK!" : Rock.marisa ? "GRIMOIRE ARCHIVE" : Rock.sao ? "AINCRAD ARCHIVE" : "ASTRAL ARCHIVE"
                                    color: Rock.ink
                                    font.family: Rock.display
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                    font.letterSpacing: 1.1
                                }
                            }
                        }

                        RowLayout {
                            spacing: 6
                            Lbl { text: "\uf07b"; color: Rock.pinkDeep; font.pixelSize: 10 }
                            Lbl {
                                Layout.maximumWidth: 430
                                text: Wallpapers.dir
                                color: Rock.a(Rock.uiText, 0.62)
                                font.pixelSize: 10
                                elide: Text.ElideMiddle
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StickerButton {
                        icon: "\uf07b"; label: I18n.t("ПАПКА")
                        fill: Rock.yellow; shadowColor: Rock.cyan
                        onClicked: win.openBrowse()
                    }
                    StickerButton {
                        icon: "\uf074"; label: I18n.t("РАНДОМ")
                        fill: Rock.cyan; shadowColor: Rock.pink
                        onClicked: Wallpapers.random()
                    }
                    StickerButton {
                        icon: "\uf00d"
                        fill: Rock.pink; shadowColor: Rock.yellow; fg: Rock.comic ? Rock.cream : Rock.ink
                        onClicked: UI.wallpaper = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 3
                    radius: 1.5
                    color: Rock.uiText
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: !win.browsing
                    spacing: 8

                    RockChip {
                        fill: Rock.comic ? Rock.cream : Rock.uiSurface2
                        shadowColor: Rock.cyan
                        offset: 1.5
                        padH: 9; padV: 3; radius: 6
                        Lbl { text: "\uf0eb"; color: Rock.pinkDeep; font.pixelSize: 10 }
                        Lbl {
                            text: I18n.t("КЛИК — ПРИМЕНИТЬ, ЦВЕТА ПОДСТРОЯТСЯ")
                            color: Rock.a(Rock.uiText, 0.68)
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RockChip {
                        fill: Rock.yellow
                        shadowColor: Rock.pink
                        offset: 1.5
                        padH: 9; padV: 3; radius: 6
                        Lbl {
                            text: win.plural(Wallpapers.files.length).toUpperCase()
                            color: Rock.ink
                            font.family: Rock.display
                            font.pixelSize: 9
                            font.weight: Font.Black
                            font.letterSpacing: 0.7
                        }
                    }
                }

                // ── выбор папки ──
                ColumnLayout {
                    visible: win.browsing
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StickerButton {
                            icon: "\uf062"
                            fill: Rock.comic ? Rock.cream : Rock.uiSurface2
                            shadowColor: Rock.pink; fg: Rock.uiText
                            onClicked: Wallpapers.up()
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 10
                            color: Rock.uiSurface2
                            border.width: Rock.uiBorder
                            border.color: Rock.uiEdge
                            Lbl {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                text: Wallpapers.browsePath
                                elide: Text.ElideMiddle
                                color: Rock.uiText
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        Repeater {
                            model: [
                                { t: I18n.t("ДОМ"),     p: Quickshell.env("HOME") },
                                { t: I18n.t("ФОТО"),    p: Quickshell.env("HOME") + "/Pictures" }
                            ]
                            delegate: StickerButton {
                                required property var modelData
                                label: modelData.t
                                fill: Rock.yellow
                                shadowColor: Rock.cyan
                                onClicked: Wallpapers.browse(modelData.p)
                            }
                        }
                    }

                    ListView {
                        id: dirs
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 5
                        boundsBehavior: Flickable.StopAtBounds
                        model: Wallpapers.subdirs

                        Lbl {
                            anchors.centerIn: parent
                            visible: dirs.count === 0
                            text: I18n.t("Вложенных папок нет")
                            color: Rock.a(Rock.uiText, 0.5)
                            font.family: Rock.display
                            font.pixelSize: 14
                            font.weight: Font.Black
                        }

                        delegate: Item {
                            id: dirRow
                            required property string modelData
                            width: dirs.width
                            height: 46

                            Rectangle {
                                visible: Rock.comic
                                x: 3; y: 3
                                width: dirRow.width - 3; height: 41
                                radius: 10
                                color: Rock.pink
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                            }
                            Rectangle {
                                id: dirBody
                                width: dirRow.width - 3; height: 41
                                radius: Rock.comic ? 10 : Rock.marisa ? 4 : 9
                                color: dirArea.containsMouse
                                       ? (Rock.comic ? Rock.yellow : Rock.uiHover)
                                       : Rock.uiSurface2
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12
                                    Lbl { text: "\uf07b"; color: Rock.pinkDeep; font.pixelSize: 14 }
                                    Lbl {
                                        Layout.fillWidth: true
                                        text: dirRow.modelData
                                        elide: Text.ElideRight
                                        color: Rock.uiText
                                        font.family: Rock.display
                                        font.weight: Font.Black
                                    }
                                    Lbl { text: "\uf054"; color: Rock.a(Rock.uiText, 0.45); font.pixelSize: 10 }
                                }
                                MouseArea {
                                    id: dirArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Wallpapers.browse(
                                        Wallpapers.browsePath === "/" ? "/" + dirRow.modelData
                                                                      : Wallpapers.browsePath + "/" + dirRow.modelData)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Lbl {
                            Layout.fillWidth: true
                            text: win.plural(Wallpapers.browseCount) + I18n.t(" в этой папке")
                            color: Rock.a(Rock.uiText, 0.6)
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        StickerButton {
                            visible: Wallpapers.customDir !== ""
                            label: I18n.t("ПО УМОЛЧАНИЮ")
                            fill: Rock.comic ? Rock.cream : Rock.uiSurface2
                            shadowColor: Rock.purple; fg: Rock.uiText
                            onClicked: { Wallpapers.setDir(""); win.browsing = false }
                        }
                        StickerButton {
                            label: I18n.t("ОТМЕНА")
                            fill: Rock.comic ? Rock.cream : Rock.uiSurface2
                            shadowColor: Rock.cyan; fg: Rock.uiText
                            onClicked: win.browsing = false
                        }
                        StickerButton {
                            label: I18n.t("ВЫБРАТЬ ПАПКУ")
                            fill: Rock.yellow; shadowColor: Rock.pink
                            onClicked: { Wallpapers.setDir(Wallpapers.browsePath); win.browsing = false }
                        }
                    }
                }

                // ── сетка обоев ──
                GridView {
                    id: grid
                    visible: !win.browsing
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    readonly property int cols: Math.max(2, Math.floor(width / 200))
                    cellWidth: width / cols
                    cellHeight: cellWidth * 0.64
                    model: Wallpapers.files

                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        spacing: 6
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf001"
                            color: Rock.pink
                            font.pixelSize: 34
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("КАРТИНКИ НЕ НАЙДЕНЫ")
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 18
                            font.weight: Font.Black
                            font.letterSpacing: 1
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("Положи обои в ") + Wallpapers.dir
                            color: Rock.a(Rock.uiText, 0.55)
                            font.pixelSize: 11
                        }
                    }

                    delegate: Item {
                        id: cell
                        required property string modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight
                        readonly property bool isCurrent: Wallpapers.current === modelData
                        readonly property real tilt: [-1.6, 1.1, -0.6, 1.7][index % 4]

                        Item {
                            id: tile
                            anchors.fill: parent
                            anchors.margins: 8
                            rotation: (area.containsMouse || !Rock.comic) ? 0 : cell.tilt
                            scale: area.containsMouse ? 1.04 : 1
                            Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Rectangle {
                                visible: Rock.comic
                                x: 5; y: 5
                                width: tile.width; height: tile.height
                                radius: 12
                                color: [Rock.pink, Rock.cyan, Rock.purple, Rock.yellow][cell.index % 4]
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                            }

                            Rectangle {
                                id: photoFrame
                                width: tile.width; height: tile.height
                                radius: Rock.comic ? 12 : Rock.marisa ? 4 : 10
                                color: Rock.uiSurface2
                                border.width: cell.isCurrent ? Rock.uiBorder + 1 : Rock.uiBorder
                                border.color: cell.isCurrent
                                    ? Rock.pinkDeep
                                    : (area.containsMouse ? Rock.uiAccent : Rock.uiEdge)
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    radius: 8
                                    color: Rock.ink2
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: win.fileUrl(cell.modelData)
                                        sourceSize: Qt.size(420, 280)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        opacity: status === Image.Ready ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                                    }

                                    RoundMask {
                                        anchors.fill: parent
                                        radius: 8
                                        maskColor: Rock.ink2
                                    }

                                    Rectangle {
                                        id: pulse
                                        anchors.fill: parent
                                        radius: 8
                                        color: Rock.pink
                                        opacity: 0
                                    }
                                    SequentialAnimation {
                                        id: pulseAnim
                                        NumberAnimation {
                                            target: pulse; property: "opacity"
                                            from: 0.55; to: 0; duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: area.containsMouse && !cell.isCurrent
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 14
                                width: 132; height: 26
                                radius: 13
                                color: Rock.yellow
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                Lbl {
                                    anchors.centerIn: parent
                                    text: I18n.t("ПРИМЕНИТЬ")
                                    color: Rock.ink
                                    font.family: Rock.display
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                    font.letterSpacing: 1.2
                                }
                            }

                            Rectangle {
                                visible: cell.isCurrent
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                width: 28; height: 28
                                radius: 14
                                rotation: Rock.comic ? 7 : 0
                                color: Rock.pink
                                border.width: Rock.uiBorder
                                border.color: Rock.uiEdge
                                Lbl {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    color: Rock.comic ? Rock.cream : Rock.ink
                                    font.pixelSize: 12
                                    font.weight: Font.Black
                                }
                            }

                            Rectangle {
                                visible: cell.isCurrent && Rock.comic
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                y: -5
                                width: 58; height: 13
                                rotation: -5
                                color: Rock.a(Rock.yellow, 0.92)
                            }

                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = area.mapToItem(win.contentItem, area.mouseX, area.mouseY)
                                    pulseAnim.restart()
                                    Wallpapers.apply(cell.modelData,
                                        p.x / Math.max(1, win.width),
                                        p.y / Math.max(1, win.height))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: fade
        NumberAnimation { target: dim;   property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: frame; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: frame; property: "scale";   from: 0.96; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
