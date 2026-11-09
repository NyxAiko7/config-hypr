import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

BarPopup {
    id: cc
    alignment: "right"

    property string page: "main"

    fill: Rock.uiSurface
    accent: Rock.uiAccent
    radius: 8

    implicitWidth: 430
    readonly property real maxH: (barWindow.screen ? barWindow.screen.height : 900) - 110
    implicitHeight: page === "main" ? Math.min(mainScroll.contentHeight + 38, maxH)
                                   : (page === "wifi" ? Math.min(600, maxH) : 500)

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var btAdapter: Bluetooth.defaultAdapter
    readonly property var btConnectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string userName: Quickshell.env("USER") || "user"
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property var upower: UPower.displayDevice

    PwObjectTracker { objects: [cc.sink, cc.source] }

    onVisibleChanged: {
        SysStats.active = visible
        Net.detailsActive = visible
        if (visible) { Brightness.refresh(); Net.refresh(); Quick.refresh() }
        else page = "main"
    }

    Connections {
        target: UI
        function onWifiSsidChanged() { if (UI.wifiSsid !== "") cc.visible = false }
    }

    function volIcon() {
        if (!sink || !sink.audio || sink.audio.muted) return "\uf026"
        const v = sink.audio.volume
        return v < 0.01 ? "\uf026" : (v < 0.5 ? "\uf027" : "\uf028")
    }
    function batteryLine() {
        const d = cc.upower
        if (!d || !d.isLaptopBattery) return I18n.t("работает ") + SysStats.uptimeText
        return Math.round(d.percentage * 100) + "% · "
            + (d.state === UPowerDeviceState.Charging ? I18n.t("заряжается") : I18n.t("от батареи"))
            + I18n.t(" · работает ") + SysStats.uptimeText
    }
    function batIcon() {
        const d = cc.upower
        if (!d) return "\uf240"
        if (d.state === UPowerDeviceState.Charging) return "\uf0e7"
        const icons = ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
        return icons[Math.min(4, Math.floor(d.percentage * 5))]
    }

    component Medallion: Item {
        id: med
        property string icon: ""
        property string label: ""
        property bool active: false
        property color tint: Rock.gold
        signal activated()

        implicitWidth: 56
        implicitHeight: 62

        Rectangle {
            id: disc
            anchors.horizontalCenter: parent.horizontalCenter
            width: 42
            height: 42
            radius: 21
            color: med.active ? Rock.a(med.tint, 0.20) : "transparent"
            border.width: 1
            border.color: med.active ? med.tint : Rock.a(Rock.uiEdge, 0.55)
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Rock.a(med.active ? med.tint : Rock.uiEdge, 0.35)
            }

            Lbl {
                anchors.centerIn: parent
                text: med.icon
                color: med.active ? med.tint : Rock.uiSub
                font.pixelSize: 15
            }
        }

        Lbl {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: disc.bottom
            anchors.topMargin: 3
            text: med.label
            color: med.active ? Rock.uiText : Rock.a(Rock.uiSub, 0.8)
            font.pixelSize: 7
            font.letterSpacing: 0.4
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: med.activated()
        }
    }

    component SealAction: Item {
        id: act
        property string icon: ""
        property string label: ""
        property bool active: false
        signal activated()
        implicitHeight: 66

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 40
            radius: 6
            rotation: 45
            color: act.active ? Rock.a(Rock.pink, 0.2) : Rock.a(Rock.uiSurface2, 0.5)
            border.width: 1
            border.color: act.active ? Rock.pinkDeep : Rock.a(Rock.uiEdge, 0.5)
            Behavior on color { ColorAnimation { duration: 130 } }

            Lbl {
                anchors.centerIn: parent
                rotation: -45
                text: act.icon
                color: act.active ? Rock.pinkDeep : Rock.uiSub
                font.pixelSize: 13
            }
        }
        Lbl {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: act.label
            color: Rock.a(Rock.uiSub, 0.85)
            font.pixelSize: 7
            font.letterSpacing: 0.3
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: act.activated()
        }
    }

    component InkSlider: Item {
        id: sl
        property string icon: ""
        property string label: ""
        property real value: 0
        property color tint: Rock.pink
        signal moved(real v)
        signal iconClicked()
        implicitHeight: 40

        RowLayout {
            anchors.fill: parent
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: Rock.a(sl.tint, 0.14)
                border.width: 1
                border.color: Rock.a(sl.tint, 0.6)
                Lbl {
                    anchors.centerIn: parent
                    text: sl.icon
                    color: sl.tint
                    font.pixelSize: 11
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sl.iconClicked()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                RowLayout {
                    Layout.fillWidth: true
                    Lbl {
                        Layout.fillWidth: true
                        text: sl.label
                        color: Rock.a(Rock.uiSub, 0.85)
                        font.pixelSize: 7
                        font.letterSpacing: 1.2
                    }
                    Lbl {
                        text: Math.round(sl.value * 100)
                        color: Rock.uiText
                        font.family: Rock.display
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                Item {
                    id: track
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    readonly property bool hot: area.containsMouse || area.pressed

                    Repeater {
                        model: 11
                        delegate: Rectangle {
                            required property int index
                            x: parent.width * index / 10 - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: index % 5 === 0 ? 7 : 4
                            color: Rock.a(Rock.uiEdge, index % 5 === 0 ? 0.45 : 0.2)
                        }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 2
                        color: Rock.a(Rock.uiText, 0.16)
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Math.max(0, Math.min(1, sl.value))
                        height: track.hot ? 5 : 4
                        color: sl.tint
                        Behavior on height { NumberAnimation { duration: 100 } }
                    }
                    Text {
                        text: "✦"
                        color: sl.tint
                        font.pixelSize: track.hot ? 15 : 12
                        y: parent.height / 2 - height / 2
                        x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, sl.value)) - width / 2))
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function setV(mx) { sl.moved(Math.max(0, Math.min(1, mx / width))) }
                        onPressed: m => setV(m.x)
                        onPositionChanged: m => { if (pressed) setV(m.x) }
                    }
                }
            }
        }
    }

    component StarGauge: Item {
        id: gauge
        property string label: ""
        property int value: 0
        property string sub: ""
        property color tint: Rock.gold
        implicitHeight: 104

        Canvas {
            id: ring
            width: 74
            height: 74
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property real v: Math.max(0, Math.min(1, gauge.value / 100))
            onVChanged: requestPaint()
            Component.onCompleted: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const c = width / 2, r = c - 5
                ctx.lineWidth = 3
                ctx.strokeStyle = Rock.a(Rock.uiEdge, 0.3)
                ctx.beginPath()
                ctx.arc(c, c, r, 0, Math.PI * 2)
                ctx.stroke()
                ctx.strokeStyle = Rock.gold
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + v * Math.PI * 2)
                ctx.stroke()
                ctx.fillStyle = Rock.a(Rock.gold, 0.7)
                for (let i = 0; i < 8; i++) {
                    const a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.arc(c + Math.cos(a) * (r + 4), c + Math.sin(a) * (r + 4), 0.9, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }
        Lbl {
            anchors.centerIn: ring
            text: gauge.value + "%"
            color: Rock.uiText
            font.family: Rock.display
            font.pixelSize: 16
            font.bold: true
        }
        Lbl {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ring.bottom
            anchors.topMargin: 3
            text: gauge.label
            color: Rock.a(Rock.uiSub, 0.85)
            font.pixelSize: 8
            font.letterSpacing: 1.2
        }
        Lbl {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ring.bottom
            anchors.topMargin: 15
            visible: gauge.sub !== ""
            text: gauge.sub
            color: Rock.gold
            font.pixelSize: 7
        }
    }

    Item {
        id: magic
        anchors.fill: parent
        anchors.margins: 8
        visible: cc.page === "main"

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 4
            width: Math.min(parent.width - 10, 386)
            height: 8
            radius: 4
            color: Rock.a(Rock.gold, 0.16)
            border.width: 1
            border.color: Rock.a(Rock.gold, 0.45)
        }
    }

    Flickable {
        id: mainScroll
        visible: cc.page === "main"
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: mainScroll.width
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 11

                Item {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        rotation: 45
                        color: Rock.a(Rock.gold, 0.18)
                        border.width: 1.5
                        border.color: Rock.gold
                    }
                    Avatar {
                        anchors.centerIn: parent
                        width: 34
                        height: 34

                        source: PanelConfig.avatarUrl
                        letter: cc.userName.charAt(0).toUpperCase()
                        bg: Rock.pink
                        fg: Rock.cream
                        borderWidth: 1
                        borderColor: Rock.a(Rock.uiEdge, 0.6)
                        fontFamily: Rock.display
                        fontSize: 16
                        fontWeight: Font.Bold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: -1
                    Lbl {
                        Layout.fillWidth: true
                        text: I18n.t("КНИГА УПРАВЛЕНИЯ")
                        color: Rock.uiText
                        font.family: Rock.display
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 0.4
                        elide: Text.ElideRight
                    }
                    Lbl {
                        Layout.fillWidth: true
                        text: "GRIMOIRE CONTROL · " + cc.userName.toUpperCase()
                        color: Rock.pinkDeep
                        font.pixelSize: 7
                        font.bold: true
                        font.letterSpacing: 1.6
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 4
                        Lbl {
                            visible: cc.upower !== null
                            text: cc.batIcon()
                            color: Rock.uiSub
                            font.pixelSize: 9
                        }
                        Lbl {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: cc.batteryLine()
                            color: Rock.a(Rock.uiSub, 0.75)
                            font.pixelSize: 8
                        }
                    }
                }

                IconBtn {
                    size: 30
                    icon: "\uf013"
                    iconColor: Rock.uiSub
                    hoverColor: Rock.a(Rock.uiText, 0.10)
                    onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.wallpaper = false; UI.settings = true }
                }
                IconBtn {
                    size: 30
                    icon: "\uf1fc"
                    iconColor: Rock.uiSub
                    hoverColor: Rock.a(Rock.uiText, 0.10)
                    onClicked: { cc.visible = false; UI.launcher = false; UI.session = false; UI.settings = false; UI.wallpaper = true }
                }
                IconBtn {
                    size: 30
                    icon: "\uf011"
                    iconColor: Rock.uiSub
                    hoverColor: Rock.a(Rock.uiText, 0.10)
                    onClicked: { cc.visible = false; UI.launcher = false; UI.wallpaper = false; UI.session = true }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Rock.a(Rock.uiEdge, 0.4)
            }

            Item {
                id: circle
                Layout.fillWidth: true
                Layout.preferredHeight: 236

                readonly property real cx: width / 2
                readonly property real cy: 116
                readonly property real ringR: Math.min(80, width * 0.24)

                Canvas {
                    anchors.fill: parent
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const cx = width / 2, cy = 116, r = Math.min(80, width * 0.24)
                        ctx.strokeStyle = Rock.a(Rock.gold, 0.42)
                        ctx.lineWidth = 1
                        for (const f of [1.0, 0.82, 0.55]) {
                            ctx.beginPath()
                            ctx.arc(cx, cy, r * f, 0, Math.PI * 2)
                            ctx.stroke()
                        }
                        ctx.strokeStyle = Rock.a(Rock.uiEdge, 0.28)
                        for (let i = 0; i < 36; i++) {
                            const a = i * Math.PI * 2 / 36
                            const r1 = r * (i % 3 === 0 ? 0.86 : 0.94)
                            ctx.beginPath()
                            ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                            ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
                            ctx.stroke()
                        }
                        ctx.strokeStyle = Rock.a(Rock.pinkDeep, 0.5)
                        ctx.beginPath()
                        for (let i = 0; i <= 6; i++) {
                            const a = -Math.PI / 2 + i * Math.PI * 2 / 6
                            const px = cx + Math.cos(a) * r * 0.82
                            const py = cy + Math.sin(a) * r * 0.82
                            if (i === 0) ctx.moveTo(px, py)
                            else ctx.lineTo(px, py)
                        }
                        ctx.stroke()
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 116 - 34
                    width: 68
                    height: 68
                    radius: 34
                    color: Rock.a(Rock.uiSurface2, 0.9)
                    border.width: 1.5
                    border.color: Rock.gold
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: -3
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: "✦"
                            color: Rock.gold
                            font.pixelSize: 13
                        }
                        Lbl {
                            Layout.alignment: Qt.AlignHCenter
                            text: Math.round((cc.sink && cc.sink.audio ? cc.sink.audio.volume : 0) * 100) + "%"
                            color: Rock.uiText
                            font.family: Rock.display
                            font.pixelSize: 15
                            font.bold: true
                        }
                    }
                }

                Medallion {
                    x: circle.width / 2 + Math.cos(-Math.PI / 2) * circle.ringR - width / 2
                    y: circle.cy + Math.sin(-Math.PI / 2) * circle.ringR - height / 2
                    icon: Net.icon
                    label: Net.kind === "ethernet" ? "ETHERNET" : "WI-FI"
                    active: Net.wifiEnabled || Net.kind === "ethernet"
                    tint: Rock.cyan
                    onActivated: Net.toggleWifi()
                }
                Medallion {
                    x: circle.width / 2 + Math.cos(-Math.PI / 2 + Math.PI / 3) * circle.ringR - width / 2
                    y: circle.cy + Math.sin(-Math.PI / 2 + Math.PI / 3) * circle.ringR - height / 2
                    icon: "\uf293"
                    label: "BLUETOOTH"
                    active: cc.btAdapter ? cc.btAdapter.enabled : false
                    tint: Rock.cyan
                    onActivated: if (cc.btAdapter) cc.btAdapter.enabled = !cc.btAdapter.enabled
                }
                Medallion {
                    x: circle.width / 2 + Math.cos(-Math.PI / 2 + 2 * Math.PI / 3) * circle.ringR - width / 2
                    y: circle.cy + Math.sin(-Math.PI / 2 + 2 * Math.PI / 3) * circle.ringR - height / 2
                    icon: Notifs.dnd ? "\uf1f6" : "\uf0f3"
                    label: I18n.t("ТИШИНА")
                    active: Notifs.dnd
                    tint: Rock.pink
                    onActivated: Notifs.dnd = !Notifs.dnd
                }
                Medallion {
                    x: circle.width / 2 + Math.cos(-Math.PI / 2 + Math.PI) * circle.ringR - width / 2
                    y: circle.cy + Math.sin(-Math.PI / 2 + Math.PI) * circle.ringR - height / 2
                    icon: "\uf0f4"
                    label: I18n.t("НЕ СПАТЬ")
                    active: UI.caffeine
                    tint: Rock.gold
                    onActivated: {
                        UI.caffeine = !UI.caffeine
                        UI.flash("\uf0f4", I18n.t("Не засыпать"), UI.caffeine ? I18n.t("Включено") : I18n.t("Выключено"), "", "info", "")
                    }
                }
                Medallion {
                    x: circle.width / 2 + Math.cos(-Math.PI / 2 + 4 * Math.PI / 3) * circle.ringR - width / 2
                    y: circle.cy + Math.sin(-Math.PI / 2 + 4 * Math.PI / 3) * circle.ringR - height / 2
                    icon: "\uf132"
                    label: "VPN"
                    active: Net.vpn
                    tint: Rock.pink
                    onActivated: Net.toggleVpn()
                }
                Medallion {
                    x: circle.width / 2 + Math.cos(-Math.PI / 2 + 5 * Math.PI / 3) * circle.ringR - width / 2
                    y: circle.cy + Math.sin(-Math.PI / 2 + 5 * Math.PI / 3) * circle.ringR - height / 2
                    icon: "\uf186"
                    label: I18n.t("НОЧНОЙ")
                    active: Quick.night
                    tint: Rock.purple
                    onActivated: Quick.toggleNight()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Repeater {
                    model: [
                        { label: I18n.t("СЕТЬ"), page: "wifi" },
                        { label: I18n.t("СИГНАЛ"), page: "bt" },
                        { label: I18n.t("ЗВУК"), page: "audio" }
                    ]
                    delegate: Rectangle {
                        id: link
                        required property var modelData
                        implicitWidth: linkLbl.implicitWidth + 22
                        implicitHeight: 20
                        radius: 3
                        color: linkArea.containsMouse ? Rock.a(Rock.gold, 0.16) : "transparent"
                        border.width: 1
                        border.color: Rock.a(Rock.gold, 0.4)
                        Lbl {
                            id: linkLbl
                            anchors.centerIn: parent
                            text: "› " + link.modelData.label
                            color: Rock.a(Rock.uiText, 0.7)
                            font.pixelSize: 7
                            font.letterSpacing: 1
                        }
                        MouseArea {
                            id: linkArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.page = link.modelData.page
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Rock.a(Rock.uiEdge, 0.4)
            }

            Lbl {
                text: I18n.t("ЗАКЛИНАНИЯ")
                color: Rock.uiText
                font.family: Rock.display
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                SealAction {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf125"; label: I18n.t("ОБЛАСТЬ")
                    onActivated: { cc.visible = false; Quick.screenshot(true) }
                }
                SealAction {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf030"; label: I18n.t("ЭКРАН")
                    onActivated: { cc.visible = false; Quick.screenshot(false) }
                }
                SealAction {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf03d"; label: Recorder.recording ? I18n.t("СТОП") : I18n.t("ЗАПИСЬ")
                    active: Recorder.recording
                    onActivated: { cc.visible = false; Recorder.toggle(true) }
                }
                SealAction {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf1fb"; label: I18n.t("ПИПЕТКА")
                    onActivated: { cc.visible = false; Quick.pick() }
                }
                SealAction {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\uf0ea"; label: I18n.t("СВИТОК")
                    onActivated: { cc.visible = false; Clip.reload(); UI.openLauncher("clip") }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Rock.a(Rock.uiEdge, 0.4)
            }

            Lbl {
                text: I18n.t("ПОТОКИ СИЛЫ")
                color: Rock.uiText
                font.family: Rock.display
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.4
            }

            InkSlider {
                Layout.fillWidth: true
                icon: cc.volIcon()
                label: I18n.t("ГРОМКОСТЬ")
                value: (cc.sink && cc.sink.audio) ? cc.sink.audio.volume : 0
                tint: Rock.pink
                onMoved: v => { if (cc.sink && cc.sink.audio) cc.sink.audio.volume = v }
                onIconClicked: if (cc.sink && cc.sink.audio) cc.sink.audio.muted = !cc.sink.audio.muted
            }
            InkSlider {
                Layout.fillWidth: true
                visible: Brightness.available
                icon: "\uf185"
                label: I18n.t("СВЕТ")
                value: Brightness.value
                tint: Rock.gold
                onMoved: v => Brightness.set(v)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: cc.source !== null
                Lbl {
                    text: cc.micMuted ? "\uf131" : "\uf130"
                    color: cc.micMuted ? Rock.pinkDeep : Rock.uiSub
                    font.pixelSize: 12
                }
                Lbl {
                    Layout.fillWidth: true
                    text: cc.micMuted ? I18n.t("Микрофон заглушён") : I18n.t("Микрофон открыт")
                    color: Rock.a(Rock.uiSub, 0.85)
                    font.pixelSize: 9
                }
                Rectangle {
                    implicitWidth: 70
                    implicitHeight: 22
                    radius: 4
                    color: micArea.containsMouse ? Rock.a(Rock.uiText, 0.08) : "transparent"
                    border.width: 1
                    border.color: Rock.a(Rock.uiEdge, 0.5)
                    Lbl {
                        anchors.centerIn: parent
                        text: cc.micMuted ? I18n.t("ОТКРЫТЬ") : I18n.t("ЗАГЛУШИТЬ")
                        color: Rock.uiSub
                        font.pixelSize: 7
                        font.letterSpacing: 0.6
                    }
                    MouseArea {
                        id: micArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (cc.source && cc.source.audio) cc.source.audio.muted = !cc.source.audio.muted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Rock.a(Rock.uiEdge, 0.4)
            }

            Lbl {
                text: I18n.t("ЗВЁЗДНЫЙ АРХИВ")
                color: Rock.uiText
                font.family: Rock.display
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                StarGauge {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    label: I18n.t("СОЗНАНИЕ"); value: SysStats.cpu
                    sub: SysStats.temp > 0 ? SysStats.temp + "°" : ""
                }
                StarGauge {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    label: I18n.t("ПАМЯТЬ"); value: SysStats.mem
                }
                StarGauge {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    label: I18n.t("СВИТКИ"); value: SysStats.disk
                }
            }
        }
    }

    WifiPage {
        anchors.fill: parent
        anchors.margins: 16
        visible: cc.page === "wifi"
        active: cc.visible && cc.page === "wifi"
        onBack: cc.page = "main"
    }
    BtPage {
        anchors.fill: parent
        anchors.margins: 16
        visible: cc.page === "bt"
        active: cc.visible && cc.page === "bt"
        onBack: cc.page = "main"
    }
    AudioPage {
        anchors.fill: parent
        anchors.margins: 16
        visible: cc.page === "audio"
        active: cc.visible && cc.page === "audio"
        onBack: cc.page = "main"
    }
}
