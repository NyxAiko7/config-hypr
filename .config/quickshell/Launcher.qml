import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: UI.launcher
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.keyboardFocus: UI.launcher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    function score(e, q) {
        const n = e.name.toLowerCase()
        if (n === q) return 100
        if (n.indexOf(q) === 0) return 80
        if (n.indexOf(q) >= 0) return 60
        const extra = ((e.genericName || "") + " " + (e.keywords ? e.keywords.join(" ") : "") + " " + (e.comment || "")).toLowerCase()
        if (extra.indexOf(q) >= 0) return 30
        let i = 0
        for (let k = 0; k < n.length && i < q.length; k++)
            if (n[k] === q[i]) i++
        return i === q.length ? 15 : 0
    }

    readonly property var results: {
        const q = input.text.trim().toLowerCase()
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        if (q === "")
            return apps.slice().sort((a, b) => a.name.localeCompare(b.name))
        return apps.map(e => ({ e: e, s: score(e, q) }))
                   .filter(x => x.s > 0)
                   .sort((a, b) => (b.s - a.s) || a.e.name.localeCompare(b.e.name))
                   .map(x => x.e)
    }

    function launch(e) {
        UI.launcher = false
        e.execute()
    }

    onVisibleChanged: if (visible) {
        input.text = ""
        list.currentIndex = 0
        input.forceActiveFocus()
        fadeIn.restart()
    }

    // затемнение, клик закрывает
    Rectangle {
        id: dim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.38)
        MouseArea { anchors.fill: parent; onClicked: UI.launcher = false }
    }

    Rectangle {
        id: card
        width: 560
        height: 64 + (list.count > 0 ? Math.min(list.count, 8) * 52 + 12 : (input.text !== "" ? 52 : 0))
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        radius: 20
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.hairline
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // не пропускать клики к затемнению

        RowLayout {
            id: searchRow
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            height: 64
            spacing: 14

            Lbl { text: "\uf002"; color: Theme.muted; font.pixelSize: 16 }

            TextInput {
                id: input
                Layout.fillWidth: true
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 16
                selectionColor: Theme.accent
                selectedTextColor: Theme.textOnAccent
                clip: true
                onTextChanged: list.currentIndex = 0

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier
                    if (event.key === Qt.Key_Escape) {
                        UI.launcher = false; event.accepted = true
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                               || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                        list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1); event.accepted = true
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                               || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                        list.currentIndex = Math.max(0, list.currentIndex - 1); event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (list.count > 0) win.launch(win.results[list.currentIndex])
                        event.accepted = true
                    }
                }

                Lbl {
                    visible: input.text === ""
                    text: "Поиск приложений…"
                    color: Theme.muted
                    font.pixelSize: 16
                }
            }
        }

        ListView {
            id: list
            anchors { top: searchRow.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
            clip: true
            model: win.results
            currentIndex: 0
            highlightMoveDuration: 90
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 52
                radius: 12
                color: ListView.isCurrentItem
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                    : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 14
                    Image {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        source: Quickshell.iconPath(row.modelData.icon)
                        sourceSize: Qt.size(56, 56)
                        smooth: true
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Lbl {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Lbl {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: row.modelData.comment || row.modelData.genericName || ""
                            color: Theme.muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: list.currentIndex = row.index
                    onClicked: win.launch(row.modelData)
                }
            }
        }

        Lbl {
            visible: list.count === 0 && input.text !== ""
            anchors { top: searchRow.bottom; horizontalCenter: parent.horizontalCenter }
            anchors.topMargin: 14
            text: "Ничего не найдено"
            color: Theme.muted
        }
    }

    ParallelAnimation {
        id: fadeIn
        NumberAnimation { target: dim;  property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "scale";   from: 0.97; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
