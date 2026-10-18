import QtQuick
import Quickshell
import Quickshell.Hyprland

// alignment: "left" | "center" | "right" относительно anchorItem
PopupWindow {
    id: popup

    required property var barWindow
    required property Item anchorItem
    property string alignment: "left"
    property double closedAt: 0

    function toggle() {
        if (Date.now() - closedAt < 500) return
        if (!visible) {
            const p = anchorItem.mapToItem(null, 0, 0)
            // окно открывается на 6px ниже нижней кромки острова
            anchor.rect = Qt.rect(p.x, p.y, anchorItem.width, barWindow.implicitHeight - p.y + 6)
        }
        visible = !visible
    }

    anchor.window: barWindow
    anchor.edges: alignment === "right" ? (Edges.Bottom | Edges.Right)
                : alignment === "center" ? Edges.Bottom
                : (Edges.Bottom | Edges.Left)
    anchor.gravity: alignment === "right" ? (Edges.Bottom | Edges.Left)
                  : alignment === "center" ? Edges.Bottom
                  : (Edges.Bottom | Edges.Right)

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
        radius: Theme.radius
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.hairline
    }
}
