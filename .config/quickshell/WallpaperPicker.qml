import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// Галерея обоев: размытый задник из текущих обоев, большая «сцена»
// с параллаксом и отражением, карусель cover-flow внизу и «расцветание»
// выбранной картинки на весь экран при применении.
PanelWindow {
    id: win

    visible: UI.wallpaper
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.keyboardFocus: UI.wallpaper ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // ── состояние ──
    property bool browsing: false
    property bool busy: false
    property int focusIndex: 0
    property real pos: 0
    property bool dragging: false
    property real tiltX: 0.5
    property real tiltY: 0.5

    readonly property int count: Wallpapers.files.length
    readonly property string focusedFile: count > 0
        ? Wallpapers.files[Math.max(0, Math.min(count - 1, focusIndex))] : ""
    readonly property real stripSpacing: Math.min(148, width / 9)
    readonly property real coverW: 196
    readonly property real coverH: 122

    Behavior on tiltX { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    Behavior on tiltY { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    Behavior on pos {
        enabled: !dragging
        NumberAnimation { duration: 460; easing.type: Easing.OutCubic }
    }

    function plural(n) {
        const a = n % 10, b = n % 100
        if (a === 1 && b !== 11) return n + I18n.t(" изображение")
        if (a >= 2 && a <= 4 && (b < 10 || b >= 20)) return n + I18n.t(" изображения")
        return n + I18n.t(" изображений")
    }
    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F")
    }
    function basename(p) {
        const i = p.lastIndexOf("/")
        return i >= 0 ? p.slice(i + 1) : p
    }
    function openBrowse() { browsing = true; Wallpapers.browse(Wallpapers.dir) }
    function clampFocus(i) { return Math.max(0, Math.min(count - 1, i)) }
    function step(dir) { if (count > 0) focusIndex = clampFocus(focusIndex + dir) }
    function wheelGo(dy) {
        if (busy || browsing || count === 0) return
        wheelGuard.restart()
        step(dy > 0 ? -1 : 1)
    }
    function randomPick() {
        if (busy || count === 0) return
        const i = Math.floor(Math.random() * count)
        focusIndex = i
        pos = i
        applyAt(i)
    }
    function applyFocused() {
        if (busy || count === 0) return
        applyAt(focusIndex)
    }
    function applyAt(i, gx, gy) {
        if (busy || count === 0) return
        busy = true
        const ox = typeof gx === "number" ? Math.max(0, Math.min(1, gx / Math.max(1, width))) : 0.5
        const oy = typeof gy === "number" ? Math.max(0, Math.min(1, gy / Math.max(1, height))) : 0.55
        bloom.source = fileUrl(Wallpapers.files[i])
        if (bloom.status === Image.Ready) bloomSeq.restart()
        Wallpapers.apply(Wallpapers.files[i], ox, oy)
    }
    function rippleAt(x, y) { ripple.cx = x; ripple.cy = y; rippleAnim.restart() }

    onVisibleChanged: {
        if (visible) {
            Wallpapers.refresh()
            keys.forceActiveFocus()
            fade.restart()
        } else {
            browsing = false
            busy = false
            bloomSeq.stop()
            bloom.opacity = 0
        }
    }
    onFocusIndexChanged: if (!dragging) pos = focusIndex

    Connections {
        target: Wallpapers
        function onFilesChanged() {
            const i = Wallpapers.files.indexOf(Wallpapers.current)
            focusIndex = i >= 0 ? i : clampFocus(focusIndex)
            pos = focusIndex
        }
    }

    Timer { id: wheelGuard; interval: 420 }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: {
            if (busy) return
            if (browsing) browsing = false
            else UI.wallpaper = false
        }
        Keys.onLeftPressed: if (!browsing) step(-1)
        Keys.onRightPressed: if (!browsing) step(1)
        Keys.onReturnPressed: if (!browsing) applyFocused()
        Keys.onEnterPressed: if (!browsing) applyFocused()
        Keys.onPressed: event => {
            if (browsing || busy) return
            if (event.key === Qt.Key_F) { openBrowse(); event.accepted = true }
            else if (event.key === Qt.Key_R) { randomPick(); event.accepted = true }
        }
    }

    // ── кросс-фейд картинок: фронт остаётся видимым, пока не готов задний ──
    component XFade: Item {
        id: xf
        property string target: ""
        property bool mirrored: false
        property string shownUrl: ""
        property var frontImg: null

        onTargetChanged: {
            if (target === "" || target === shownUrl) return
            const slot = (frontImg === imgA) ? imgB : imgA
            slot.source = target
            if (slot.status === Image.Ready && String(slot.source) === target) {
                frontImg = slot
                shownUrl = target
            }
        }
        function imgReady(im) {
            if (im !== frontImg && String(im.source) === target && target !== shownUrl) {
                frontImg = im
                shownUrl = target
            }
        }

        Image {
            id: imgA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(1440, 900)
            asynchronous: true
            cache: true
            mirror: xf.mirrored
            opacity: (xf.frontImg === imgA && status === Image.Ready) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }
            onStatusChanged: if (status === Image.Ready) xf.imgReady(imgA)
        }
        Image {
            id: imgB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(1440, 900)
            asynchronous: true
            cache: true
            mirror: xf.mirrored
            opacity: (xf.frontImg === imgB && status === Image.Ready) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }
            onStatusChanged: if (status === Image.Ready) xf.imgReady(imgB)
        }
    }

    component ToolBtn: Column {
        id: tb
        property string icon: ""
        property string label: ""
        signal activated()
        spacing: 5

        Rectangle {
            width: 40; height: 40; radius: 20
            anchors.horizontalCenter: parent.horizontalCenter
            color: tbMA.containsMouse ? Rock.uiHover : Rock.a(Rock.uiSurface, 0.55)
            border.width: 1
            border.color: tbMA.containsMouse ? Theme.accent : Rock.uiEdge
            scale: tbMA.containsMouse ? 1.08 : 1
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            Lbl {
                anchors.centerIn: parent
                text: tb.icon
                color: tbMA.containsMouse ? Theme.accent : Rock.uiText
                font.pixelSize: 13
            }
            MouseArea {
                id: tbMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tb.activated()
            }
        }
        Lbl {
            visible: tb.label !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: tb.label
            color: Rock.uiSub
            font.pixelSize: 7
            font.weight: Font.Black
            font.letterSpacing: 1.4
        }
    }

    component MiniBtn: Rectangle {
        id: mb
        property string icon: ""
        property real size: 28
        signal activated()
        width: size; height: size; radius: size / 2
        implicitWidth: size; implicitHeight: size
        color: mbMA.containsMouse ? Rock.uiHover : Rock.uiSurface2
        border.width: 1
        border.color: mbMA.containsMouse ? Theme.accent : Rock.uiEdge
        Behavior on color { ColorAnimation { duration: 110 } }

        Lbl {
            anchors.centerIn: parent
            text: mb.icon
            color: mbMA.containsMouse ? Theme.accent : Rock.uiText
            font.pixelSize: Math.round(mb.size * 0.42)
        }
        MouseArea {
            id: mbMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.activated()
        }
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: false
        property bool small: false
        signal activated()
        height: small ? 27 : 34
        radius: height / 2
        implicitWidth: pbLbl.implicitWidth + (small ? 22 : 30)
        implicitHeight: height
        color: pbMA.containsMouse
               ? (primary ? Qt.darker(Theme.accent, 1.15) : Rock.uiHover)
               : (primary ? Theme.accent : Rock.uiSurface2)
        border.width: 1
        border.color: primary ? Qt.darker(Theme.accent, 1.35)
                              : (pbMA.containsMouse ? Theme.accent : Rock.uiEdge)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Lbl {
            id: pbLbl
            anchors.centerIn: parent
            text: pb.label
            color: pb.primary ? Theme.textOnAccent : Rock.uiText
            font.pixelSize: pb.small ? 8 : 9
            font.weight: Font.Black
            font.letterSpacing: 1.2
        }
        MouseArea {
            id: pbMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.activated()
        }
    }

    Item {
        id: scene
        anchors.fill: parent

        Item {
            id: content
            anchors.fill: parent
            opacity: 0

            // ── задник: размытые текущие обои ──
            Image {
                id: wallImg
                anchors.fill: parent
                source: Theme.wallpaper !== "" ? win.fileUrl(Theme.wallpaper) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(1600, 1000)
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wallImg
                visible: wallImg.status === Image.Ready
                blurEnabled: true
                blur: 0.8
                blurMax: 72
                brightness: -0.48
                saturation: -0.4
            }
            Rectangle {
                anchors.fill: parent
                visible: wallImg.status !== Image.Ready
                color: Theme.bg
            }

            // ── северное сияние из акцентов палитры ──
            Rectangle {
                width: parent.width * 0.5
                height: parent.height * 2
                y: -parent.height * 0.5
                rotation: -13
                gradient: Gradient {
                    GradientStop { position: 0; color: Rock.a(Theme.accent, 0.15) }
                    GradientStop { position: 1; color: Rock.a(Theme.accent, 0) }
                }
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: win.visible
                    NumberAnimation { from: -scene.width * 0.16; to: scene.width * 0.22; duration: 17000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: scene.width * 0.22; to: -scene.width * 0.16; duration: 17000; easing.type: Easing.InOutSine }
                }
            }
            Rectangle {
                width: parent.width * 0.4
                height: parent.height * 2
                y: -parent.height * 0.6
                rotation: 11
                gradient: Gradient {
                    GradientStop { position: 0; color: Rock.a(Theme.accent2, 0.12) }
                    GradientStop { position: 1; color: Rock.a(Theme.accent2, 0) }
                }
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: win.visible
                    NumberAnimation { from: scene.width * 0.55; to: scene.width * 0.18; duration: 21000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: scene.width * 0.18; to: scene.width * 0.55; duration: 21000; easing.type: Easing.InOutSine }
                }
            }

            // ── световая пыль ──
            Repeater {
                model: 24
                delegate: Rectangle {
                    id: dust
                    required property int index
                    width: 1 + (dust.index % 3)
                    height: width
                    radius: width / 2
                    x: (dust.index * 167 + 70) % Math.max(1, scene.width)
                    y: scene.height + 24
                    color: dust.index % 4 === 3 ? Rock.a(Theme.accent2, 0.55) : Rock.a(Theme.accent, 0.5)
                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: win.visible
                        NumberAnimation { from: scene.height + 24; to: -30; duration: 13000 + dust.index * 850 }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: win.visible
                        NumberAnimation { from: 0.04 + (dust.index % 5) * 0.03; to: 0.15 + (dust.index % 5) * 0.03; duration: 2600 + dust.index * 300; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.15 + (dust.index % 5) * 0.03; to: 0.04 + (dust.index % 5) * 0.03; duration: 2600 + dust.index * 300; easing.type: Easing.InOutSine }
                    }
                }
            }

            // затемнение для читаемости
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Rock.a(Theme.bg, 0.5) }
                    GradientStop { position: 0.5; color: Rock.a(Theme.bg, 0.18) }
                    GradientStop { position: 1; color: Rock.a(Theme.bg, 0.66) }
                }
            }

            MouseArea {
                id: bgArea
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: m => {
                    win.tiltX = m.x / Math.max(1, width)
                    win.tiltY = m.y / Math.max(1, height)
                }
                onClicked: {
                    if (win.busy) return
                    if (win.browsing) win.browsing = false
                    else UI.wallpaper = false
                }
                onWheel: w => win.wheelGo(w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x)
            }

            // ── шапка ──
            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 88
                opacity: win.browsing ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }

                RowLayout {
                    anchors { left: parent.left; top: parent.top; leftMargin: 30; topMargin: 22 }
                    spacing: 13

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 4
                        Layout.preferredHeight: 34
                        radius: 2
                        color: Theme.accent
                    }
                    ColumnLayout {
                        spacing: 5
                        Lbl {
                            text: I18n.t("ОБОИ")
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 28
                            font.weight: Font.Black
                            font.letterSpacing: 3
                        }
                        RowLayout {
                            spacing: 7
                            Lbl { text: "\uf07b"; color: Rock.uiSub; font.pixelSize: 9 }
                            Lbl {
                                Layout.maximumWidth: Math.min(340, header.width * 0.4)
                                text: Wallpapers.dir
                                color: Rock.a(Rock.uiText, 0.55)
                                font.pixelSize: 10
                                elide: Text.ElideMiddle
                            }
                            Lbl { text: "·"; color: Rock.a(Rock.uiText, 0.4); font.pixelSize: 10 }
                            Lbl {
                                text: win.plural(win.count).toUpperCase()
                                color: Rock.a(Rock.uiText, 0.55)
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                Lbl {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 27 }
                    visible: win.count > 0
                    text: (win.focusIndex + 1) + " / " + win.count
                    color: Rock.a(Rock.uiText, 0.8)
                    font.family: Rock.display
                    font.pixelSize: 13
                    font.weight: Font.Black
                    font.letterSpacing: 1.6
                }

                Row {
                    anchors { right: parent.right; top: parent.top; rightMargin: 30; topMargin: 16 }
                    spacing: 18
                    ToolBtn { icon: "\uf07b"; label: I18n.t("ПАПКА"); onActivated: if (!win.busy) win.openBrowse() }
                    ToolBtn { icon: "\uf074"; label: I18n.t("РАНДОМ"); onActivated: if (!win.busy) win.randomPick() }
                    ToolBtn { icon: "\uf00d"; onActivated: if (!win.busy) UI.wallpaper = false }
                }
            }

            // ── сцена: большая карточка с параллаксом и отражением ──
            Item {
                id: middle
                anchors { top: header.bottom; bottom: stripArea.top; left: parent.left; right: parent.right; margins: 8 }
                visible: win.count > 0
                opacity: win.browsing ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }

                readonly property real cardH: Math.max(170, Math.min(430, (height - 88) / 1.26))
                readonly property real cardW: Math.max(300, Math.min(width - 60, cardH * 1.62))

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    Item {
                        id: tiltGroup
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: middle.cardW
                        implicitHeight: middle.cardH * 1.26 + 6

                        Rectangle {
                            id: auraA
                            visible: false
                            width: tiltGroup.width * 0.78
                            height: middle.cardH * 0.85
                            x: tiltGroup.width / 2 - width / 2 - tiltGroup.width * 0.1
                            y: middle.cardH * 0.45 - height / 2
                            radius: height / 2
                            color: Rock.a(Theme.accent, 0.30)
                        }
                        MultiEffect {
                            source: auraA
                            width: auraA.width + 170
                            height: auraA.height + 170
                            x: auraA.x - 85
                            y: auraA.y - 85
                            blurEnabled: true
                            blur: 1
                            blurMax: 60
                            SequentialAnimation on rotation {
                                loops: Animation.Infinite
                                running: win.visible && !win.browsing
                                NumberAnimation { from: -5; to: 6; duration: 14000; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 6; to: -5; duration: 14000; easing.type: Easing.InOutSine }
                            }
                        }

                        Rectangle {
                            id: auraB
                            visible: false
                            width: tiltGroup.width * 0.6
                            height: middle.cardH * 0.7
                            x: tiltGroup.width / 2 - width / 2 + tiltGroup.width * 0.12
                            y: middle.cardH * 0.6 - height / 2
                            radius: height / 2
                            color: Rock.a(Theme.accent2, 0.26)
                        }
                        MultiEffect {
                            source: auraB
                            width: auraB.width + 150
                            height: auraB.height + 150
                            x: auraB.x - 75
                            y: auraB.y - 75
                            blurEnabled: true
                            blur: 1
                            blurMax: 52
                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                running: win.visible && !win.browsing
                                NumberAnimation { from: 1; to: 1.12; duration: 9000; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.12; to: 1; duration: 9000; easing.type: Easing.InOutSine }
                            }
                        }

                        Item {
                            id: card
                            width: tiltGroup.width
                            height: middle.cardH
                            transform: [
                                Rotation {
                                    origin.x: tiltGroup.width / 2
                                    origin.y: middle.cardH
                                    axis { x: 1; y: 0; z: 0 }
                                    angle: (0.5 - win.tiltY) * 9
                                },
                                Rotation {
                                    origin.x: tiltGroup.width / 2
                                    origin.y: middle.cardH
                                    axis { x: 0; y: 1; z: 0 }
                                    angle: (win.tiltX - 0.5) * 11
                                }
                            ]

                            Rectangle {
                                anchors.fill: parent
                                radius: Rock.uiRadius
                                color: Rock.uiSurface
                                border.width: 1
                                border.color: Rock.uiEdge
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 8
                                clip: true

                                XFade {
                                    id: stageShot
                                    anchors.fill: parent
                                    target: win.focusedFile !== "" ? win.fileUrl(win.focusedFile) : ""
                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: win.visible && win.count > 0 && !win.browsing
                                        NumberAnimation { from: 1; to: 1.055; duration: 13000; easing.type: Easing.InOutSine }
                                        NumberAnimation { from: 1.055; to: 1; duration: 13000; easing.type: Easing.InOutSine }
                                    }
                                }

                                RoundMask {
                                    anchors.fill: parent
                                    radius: Math.max(2, Rock.uiRadius - 8)
                                    maskColor: Rock.uiSurface
                                }
                            }
                        }

                        Item {
                            id: reflect
                            y: middle.cardH + 6
                            width: tiltGroup.width
                            height: middle.cardH * 0.26
                            clip: true
                            opacity: 0.16

                            XFade {
                                anchors.fill: parent
                                mirrored: true
                                target: stageShot.target
                            }
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Rock.a(Theme.bg, 0) }
                                    GradientStop { position: 1; color: Rock.a(Theme.bg, 0.8) }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: caption
                        spacing: 7

                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: tiltGroup.width + 160
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                            text: win.focusedFile !== "" ? win.basename(win.focusedFile).toUpperCase() : ""
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 14
                            font.weight: Font.Black
                            font.letterSpacing: 3
                        }
                        Rectangle {
                            visible: win.focusedFile !== "" && win.focusedFile === Wallpapers.current
                            Layout.alignment: Qt.AlignHCenter
                            width: curLbl.implicitWidth + 18
                            height: 19
                            radius: 9.5
                            color: Rock.uiActive
                            border.width: 1
                            border.color: Rock.a(Theme.accent, 0.55)
                            Lbl {
                                id: curLbl
                                anchors.centerIn: parent
                                text: I18n.t("ТЕКУЩИЕ")
                                color: Theme.accent
                                font.pixelSize: 8
                                font.weight: Font.Black
                                font.letterSpacing: 1.6
                            }
                        }
                    }
                }
            }

            // ── карусель cover-flow ──
            Item {
                id: stripArea
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 42 }
                height: 232
                visible: win.count > 0
                opacity: win.browsing ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }

                MouseArea {
                    id: stripMA
                    anchors.fill: parent
                    property real pressPos: 0
                    property real pressX: 0
                    onPressed: m => { pressPos = win.pos; pressX = m.x; win.dragging = false }
                    onPositionChanged: m => {
                        if (!pressed) return
                        const dx = m.x - pressX
                        if (!win.dragging && Math.abs(dx) > 8) win.dragging = true
                        if (win.dragging)
                            win.pos = Math.max(0, Math.min(win.count - 1, pressPos - dx / win.stripSpacing))
                    }
                    onReleased: {
                        if (!win.dragging) return
                        win.dragging = false
                        win.focusIndex = Math.round(Math.max(0, Math.min(win.count - 1, win.pos)))
                        win.pos = win.focusIndex
                    }
                    onWheel: w => win.wheelGo(w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x)
                }

                Repeater {
                    model: Wallpapers.files

                    delegate: Item {
                        id: cover
                        required property string modelData
                        required property int index
                        readonly property real d: cover.index - win.pos
                        readonly property real ad: Math.abs(cover.d)
                        readonly property bool isFocus: cover.index === win.focusIndex
                        width: win.coverW
                        height: win.coverH
                        visible: cover.ad < 4.2
                        z: 100 - cover.ad * 10

                        x: stripArea.width / 2 - win.coverW / 2
                           + cover.d * win.stripSpacing * (1 - Math.min(0.42, cover.ad * 0.11))
                        y: stripArea.height - win.coverH - 12
                           + Math.min(44, Math.pow(cover.ad, 1.6) * 11)
                           - (cover.isFocus ? 9 : 0)
                        opacity: Math.max(0, 1 - cover.ad * 0.3)
                        rotation: cover.d * 1.4
                        scale: (1 / (1 + cover.ad * 0.24)) * (coverMA.containsMouse && !win.dragging ? 1.06 : 1)
                        transform: Rotation {
                            origin.x: win.coverW / 2
                            origin.y: win.coverH
                            axis { x: 0; y: 1; z: 0 }
                            angle: Math.max(-58, Math.min(58, -cover.d * 22))
                        }
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: coverFrame
                            anchors.fill: parent
                            radius: Math.max(8, Rock.uiRadius - 6)
                            color: coverMA.containsMouse ? Rock.uiHover : Rock.uiSurface
                            border.width: 1
                            border.color: cover.isFocus ? Theme.accent
                                        : (coverMA.containsMouse ? Rock.a(Theme.accent, 0.65) : Rock.uiEdge)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 7
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: cover.ad < 4.5 ? win.fileUrl(cover.modelData) : ""
                                sourceSize: Qt.size(420, 280)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                            RoundMask {
                                anchors.fill: parent
                                radius: coverFrame.radius - 7
                                maskColor: coverFrame.color
                            }
                        }

                        Rectangle {
                            visible: cover.isFocus && Wallpapers.current === cover.modelData
                            anchors { right: parent.right; top: parent.top; margins: 8 }
                            width: 20; height: 20; radius: 10
                            color: Theme.accent
                            border.width: 1
                            border.color: Rock.uiSurface
                            Lbl {
                                anchors.centerIn: parent
                                text: "\uf00c"
                                color: Theme.textOnAccent
                                font.pixelSize: 9
                                font.weight: Font.Black
                            }
                        }

                        Rectangle {
                            visible: cover.isFocus && coverMA.containsMouse && !win.dragging
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 9 }
                            width: applyLbl.implicitWidth + 18
                            height: 20
                            radius: 10
                            color: Theme.accent
                            border.width: 1
                            border.color: Qt.darker(Theme.accent, 1.3)
                            Lbl {
                                id: applyLbl
                                anchors.centerIn: parent
                                text: I18n.t("ПРИМЕНИТЬ")
                                color: Theme.textOnAccent
                                font.pixelSize: 8
                                font.weight: Font.Black
                                font.letterSpacing: 1.2
                            }
                        }

                        MouseArea {
                            id: coverMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: if (!win.dragging && !wheelGuard.running) win.focusIndex = cover.index
                            onClicked: m => {
                                if (win.busy) return
                                if (cover.index !== win.focusIndex) {
                                    win.focusIndex = cover.index
                                } else {
                                    const p = coverMA.mapToItem(scene, m.x, m.y)
                                    win.rippleAt(p.x, p.y)
                                    win.applyAt(cover.index, p.x, p.y)
                                }
                            }
                            onWheel: w => win.wheelGo(w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x)
                        }
                    }
                }
            }

            // ── подсказки ──
            Item {
                id: hintBar
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 32; rightMargin: 32; bottomMargin: 15 }
                height: 12
                visible: win.count > 0
                opacity: (win.browsing || win.busy) ? 0 : 0.9
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Lbl {
                    anchors.left: parent.left
                    text: I18n.t("клик — применить · колесо или ◄► — листать")
                    color: Rock.a(Rock.uiText, 0.5)
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                }
                Lbl {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.t("F — папка · R — случайные")
                    color: Rock.a(Rock.uiText, 0.5)
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                }
                Lbl {
                    anchors.right: parent.right
                    text: I18n.t("ESC — закрыть")
                    color: Rock.a(Rock.uiText, 0.5)
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                }
            }

            // ── пустая папка ──
            ColumnLayout {
                visible: win.count === 0 && !win.browsing
                anchors.centerIn: parent
                spacing: 12
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\uf03e"
                    color: Theme.accent
                    font.pixelSize: 42
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.t("КАРТИНКИ НЕ НАЙДЕНЫ")
                    color: Rock.uiText
                    font.family: Rock.display
                    font.pixelSize: 17
                    font.weight: Font.Black
                    font.letterSpacing: 2
                }
                Lbl {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: middle.width - 80
                    horizontalAlignment: Text.AlignHCenter
                    text: I18n.t("Положи обои в ") + Wallpapers.dir
                    color: Rock.a(Rock.uiText, 0.55)
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                }
                PillBtn {
                    Layout.alignment: Qt.AlignHCenter
                    label: I18n.t("ВЫБРАТЬ ПАПКУ")
                    primary: true
                    onActivated: win.openBrowse()
                }
            }

            // ── кольцо от клика ──
            Rectangle {
                id: ripple
                property real cx: 0
                property real cy: 0
                x: cx - width / 2
                y: cy - height / 2
                width: 0
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                opacity: 0
                visible: opacity > 0.01
                ParallelAnimation {
                    id: rippleAnim
                    NumberAnimation { target: ripple; property: "width"; from: 24; to: 520; duration: 500; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ripple; property: "opacity"; from: 0.75; to: 0; duration: 500 }
                }
            }

            // ── выбор папки ──
            Rectangle {
                id: browseCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 640)
                height: Math.min(parent.height - 120, 560)
                radius: Rock.uiRadius
                color: Rock.uiSurface
                border.width: 1
                border.color: Rock.uiEdge
                visible: win.browsing
                opacity: win.browsing ? 1 : 0
                scale: win.browsing ? 1 : 0.965
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Lbl { text: "\uf07b"; color: Theme.accent; font.pixelSize: 14 }
                        Lbl {
                            text: I18n.t("ПАПКА С ОБОЯМИ")
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 14
                            font.weight: Font.Black
                            font.letterSpacing: 2
                        }
                        Item { Layout.fillWidth: true }
                        MiniBtn { icon: "\uf00d"; onActivated: win.browsing = false }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        MiniBtn { icon: "\uf062"; onActivated: Wallpapers.up() }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: Rock.uiRadiusSm
                            color: Rock.uiSurface2
                            border.width: 1
                            border.color: Rock.uiEdge
                            Lbl {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                text: Wallpapers.browsePath
                                elide: Text.ElideMiddle
                                color: Rock.uiText
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                        PillBtn {
                            small: true
                            label: I18n.t("ДОМ")
                            onActivated: Wallpapers.browse(Quickshell.env("HOME"))
                        }
                        PillBtn {
                            small: true
                            label: I18n.t("ФОТО")
                            onActivated: Wallpapers.browse(Quickshell.env("HOME") + "/Pictures")
                        }
                    }

                    ListView {
                        id: dirs
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: Wallpapers.subdirs

                        Lbl {
                            anchors.centerIn: parent
                            visible: dirs.count === 0
                            text: I18n.t("Вложенных папок нет")
                            color: Rock.a(Rock.uiText, 0.5)
                            font.family: Rock.display
                            font.pixelSize: 13
                            font.weight: Font.Black
                        }

                        delegate: Rectangle {
                            id: dirRow
                            required property string modelData
                            width: dirs.width
                            height: 40
                            radius: 9
                            color: dirMA.containsMouse ? Rock.uiHover : Rock.uiSurface2
                            border.width: 1
                            border.color: dirMA.containsMouse ? Rock.a(Theme.accent, 0.55) : Rock.uiEdge
                            Behavior on color { ColorAnimation { duration: 110 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10
                                Lbl { text: "\uf07b"; color: Theme.accent; font.pixelSize: 12 }
                                Lbl {
                                    Layout.fillWidth: true
                                    text: dirRow.modelData
                                    elide: Text.ElideRight
                                    color: Rock.uiText
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                                Lbl { text: "\uf054"; color: Rock.a(Rock.uiText, 0.4); font.pixelSize: 9 }
                            }
                            MouseArea {
                                id: dirMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wallpapers.browse(
                                    Wallpapers.browsePath === "/" ? "/" + dirRow.modelData
                                                                 : Wallpapers.browsePath + "/" + dirRow.modelData)
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
                        PillBtn {
                            visible: Wallpapers.customDir !== ""
                            label: I18n.t("ПО УМОЛЧАНИЮ")
                            onActivated: { Wallpapers.setDir(""); win.browsing = false }
                        }
                        PillBtn { label: I18n.t("ОТМЕНА"); onActivated: win.browsing = false }
                        PillBtn {
                            label: I18n.t("ВЫБРАТЬ ПАПКУ")
                            primary: true
                            onActivated: { Wallpapers.setDir(Wallpapers.browsePath); win.browsing = false }
                        }
                    }
                }
            }
        }

        // ── расцветание: новые обои накрывают экран и тают ──
        Image {
            id: bloom
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(1440, 900)
            asynchronous: true
            cache: true
            opacity: 0
            visible: opacity > 0.004
            onStatusChanged: if (status === Image.Ready && win.busy && !bloomSeq.running) bloomSeq.restart()
        }
        SequentialAnimation {
            id: bloomSeq
            ParallelAnimation {
                NumberAnimation { target: bloom; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutQuad }
                NumberAnimation { target: bloom; property: "scale"; from: 1.14; to: 1; duration: 480; easing.type: Easing.OutCubic }
                NumberAnimation { target: content; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InQuad }
            }
            PauseAnimation { duration: 260 }
            NumberAnimation { target: bloom; property: "opacity"; to: 0; duration: 620; easing.type: Easing.InOutQuad }
            onFinished: UI.wallpaper = false
        }
    }

    ParallelAnimation {
        id: fade
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: content; property: "scale"; from: 0.975; to: 1; duration: 280; easing.type: Easing.OutCubic }
    }
}
