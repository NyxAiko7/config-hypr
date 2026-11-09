import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Левый остров: лаунчер, рабочие столы, запись, помодоро, активное окно.
BarIsland {
    id: leftIsland
    fill: Rock.islandFill
    shadowColor: Rock.pink
    tilt: -0.8

    // значок активного окна
    readonly property string activeIcon: {
        const t = ToplevelManager.activeToplevel
        if (!t || !t.appId) return ""
        let e = null
        try { e = DesktopEntries.byId(t.appId) || DesktopEntries.heuristicLookup(t.appId) } catch (err) {}
        return (e && e.icon) ? Quickshell.iconPath(e.icon) : ""
    }

    // Лаунчер
    Pill {
        interactive: true
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { UI.launcher = false; UI.session = true }
            else UI.openLauncher("apps")
        }
        Lbl {
            text: "\uf303"
            color: Rock.pinkDeep
            font.pixelSize: 15
            scale: parent.hovered ? 1.12 : 1.0
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }

    // Рабочие столы — точки с подсветкой занятых
    Pill {
        Repeater {
            model: Hyprland.workspaces
            delegate: Rectangle {
                required property var modelData
                visible: modelData.id > 0
                Layout.preferredWidth: modelData.focused ? 20 : 6
                Layout.preferredHeight: 6
                radius: 3
                // занятые (есть окна) горят приглушённым акцентом, пустые — тускло
                color: modelData.focused ? Rock.pinkDeep
                       : (modelData.windows !== undefined && modelData.windows.values.length > 0
                          ? Rock.cyan : Rock.a(Rock.ink, 0.22))
                opacity: modelData.focused ? 1 : 0.9
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 220 } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }

    // Идёт запись экрана (клик — остановить)
    Pill {
        visible: Recorder.recording
        interactive: true
        onClicked: Recorder.stop()
        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: Rock.pinkDeep
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: Recorder.recording
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        Lbl { text: Recorder.text(); color: Rock.pinkDeep; font.bold: true }
    }

    // Таймер фокуса: клик — старт/стоп, ПКМ — следующая фаза
    Pill {
        interactive: true
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { if (Pomodoro.running) Pomodoro.skip(); else Pomodoro.start("break") }
            else if (Pomodoro.running) Pomodoro.stop()
            else Pomodoro.start("focus")
        }
        Lbl {
            text: Pomodoro.mode === "break" ? "\uf0f4" : "\uf017"
            color: Pomodoro.mode === "focus" ? Rock.pinkDeep : (Pomodoro.mode === "break" ? Rock.cyan : Rock.a(Rock.ink, 0.4))
            font.pixelSize: Theme.iconSize
        }
        Lbl {
            visible: Pomodoro.running
            text: Pomodoro.text()
            font.bold: true
            color: Pomodoro.mode === "focus" ? Rock.pinkDeep : Rock.cyan
        }
    }

    // Значок и заголовок активного окна
    Image {
        id: winIcon
        Layout.leftMargin: 4
        Layout.preferredWidth: 16
        Layout.preferredHeight: 16
        source: leftIsland.activeIcon
        sourceSize: Qt.size(32, 32)
        smooth: true
        visible: status === Image.Ready
    }
    Lbl {
        Layout.leftMargin: winIcon.visible ? 0 : 6
        Layout.rightMargin: 8
        Layout.maximumWidth: 220
        text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
        color: Rock.a(Rock.ink, 0.58)
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }
}
