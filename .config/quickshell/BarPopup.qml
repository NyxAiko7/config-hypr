import QtQuick
import Quickshell
import Quickshell.Hyprland

// alignment: "left" | "center" | "right" относительно anchorItem
// Направление открытия зависит от расположения панели.
PopupWindow {
    id: popup

    required property var barWindow
    required property Item anchorItem
    property string alignment: "left"
    property double closedAt: 0

    property color fill: Rock.marisa ? Rock.uiSurface : Rock.ink2
    property color edge: Rock.ink
    property color accent: Rock.pink
    property real radius: Rock.comic ? 20 : Rock.marisa ? 8 : Rock.sao ? 4 : 16
    property int borderWidth: Rock.comic ? 3 : 1
    property bool decorated: true

    readonly property string pos: PanelConfig.position

    function toggle() {
        if (Date.now() - closedAt < 500) return
        if (!visible) {
            const p = anchorItem.mapToItem(null, 0, 0)
            if (pos === "bottom")
                anchor.rect = Qt.rect(p.x, p.y - 6, anchorItem.width, 1)
            else if (pos === "left")
                anchor.rect = Qt.rect(p.x, p.y, anchorItem.width + 6, anchorItem.height)
            else if (pos === "right")
                anchor.rect = Qt.rect(p.x - 6, p.y, 1, anchorItem.height)
            else
                anchor.rect = Qt.rect(p.x, p.y, anchorItem.width, Theme.barHeight - p.y + 6)
        }
        visible = !visible
    }

    anchor.window: barWindow
    anchor.edges: {
        if (pos === "bottom") {
            return alignment === "right" ? (Edges.Top | Edges.Right)
                 : alignment === "center" ? Edges.Top
                 : (Edges.Top | Edges.Left)
        }
        if (pos === "left" || pos === "right") {
            const side = pos === "left" ? Edges.Right : Edges.Left
            const v = alignment === "right" ? Edges.Bottom
                    : alignment === "left" ? Edges.Top : 0
            return side | v
        }
        return alignment === "right" ? (Edges.Bottom | Edges.Right)
             : alignment === "center" ? Edges.Bottom
             : (Edges.Bottom | Edges.Left)
    }
    anchor.gravity: {
        if (pos === "bottom") {
            return alignment === "right" ? (Edges.Top | Edges.Left)
                 : alignment === "center" ? Edges.Top
                 : (Edges.Top | Edges.Right)
        }
        if (pos === "left" || pos === "right") {
            const side = pos === "left" ? Edges.Right : Edges.Left
            const v = alignment === "right" ? Edges.Top
                    : alignment === "left" ? Edges.Bottom : 0
            return side | v
        }
        return alignment === "right" ? (Edges.Bottom | Edges.Left)
             : alignment === "center" ? Edges.Bottom
             : (Edges.Bottom | Edges.Right)
    }

    color: "transparent"
    visible: false

    onVisibleChanged: if (visible) {
        popup.contentItem.transformOrigin = Item.Top
        fadeIn.restart()
    }

    ParallelAnimation {
        id: fadeIn
        NumberAnimation { target: popup.contentItem; property: "opacity"; from: 0; to: 1; duration: 160 }
        NumberAnimation { target: popup.contentItem; property: "scale"; from: 0.95; to: 1; duration: 220; easing.type: Easing.OutCubic }
    }

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible
        onCleared: { popup.visible = false; popup.closedAt = Date.now() }
    }

    Rectangle {
        anchors.fill: parent
        radius: popup.radius
        color: popup.fill
        border.width: popup.borderWidth
        border.color: Rock.comic ? popup.edge : (Rock.marisa ? Rock.uiEdge : Rock.a(Rock.gold, 0.55))
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Rock.comic ? 5 : 4
        radius: popup.radius - (Rock.comic ? 4 : 3)
        color: "transparent"
        border.width: Rock.comic ? 1.5 : 1
        border.color: popup.accent
        opacity: Rock.comic ? 0.55 : 0.30
    }

    SaoGrid {
        anchors.fill: parent
        anchors.margins: 5
        step: 26
        visible: Rock.sao && popup.decorated
    }

    MarisaPattern {
        anchors.fill: parent
        anchors.margins: 5
        opacity: 0.42
        visible: Rock.marisa && popup.decorated
    }

    MarisaTrim {
        visible: Rock.marisa && popup.decorated
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 1
        height: 3
        cell: 3
    }

    MarisaFrame {
        anchors.fill: parent
        shown: Rock.marisa && popup.decorated
        inset: 6
        frameRadius: Math.max(2, popup.radius - 4)
    }

    SaoFrame {
        anchors.fill: parent
        shown: Rock.sao && popup.decorated
        inset: 5
        cut: 10
        segments: 24
    }

    // книжный корешок слева — пергаментные меню Марисы
    Rectangle {
        visible: Rock.marisa && popup.decorated
        width: 7
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 1
        color: Rock.a(Rock.uiSurface2, 0.9)
        border.width: 1
        border.color: Rock.a(Rock.uiEdge, 0.5)
    }
    Repeater {
        model: Rock.marisa && popup.decorated ? 3 : 0
        delegate: Rectangle {
            required property int index
            width: 5
            height: 2
            x: 2
            y: parent.height * (0.22 + index * 0.28)
            color: Rock.a(Rock.gold, 0.8)
        }
    }
}
