import QtQuick
import QtQuick.Layouts

// Скруглённая плашка панели, содержимое лежит в ряд.
Item {
    id: island

    default property alias content: inner.data

    height: Theme.islandHeight
    width: inner.implicitWidth + 20

    IslandSurface {
        anchors.fill: parent
        radius: Theme.islandRadius
    }

    RowLayout {
        id: inner
        anchors.centerIn: parent
        spacing: 3
    }
}
