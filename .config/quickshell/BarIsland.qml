import QtQuick
import QtQuick.Layouts

// «Стикер» панели: жирный контур, офсетная тень и лёгкий наклон.
Item {
    id: island

    default property alias content: inner.data

    property color fill: Rock.ink2
    property color shadowColor: Rock.pink
    property real shadowOffset: 3
    property real tilt: 0

    height: Theme.islandHeight
    width: inner.implicitWidth + 20
    rotation: tilt
    transformOrigin: Item.Center

    IslandSurface {
        anchors.fill: parent
        radius: 11
        fill: island.fill
        shadowColor: island.shadowColor
        shadowOffset: island.shadowOffset
    }

    RowLayout {
        id: inner
        anchors.centerIn: parent
        spacing: 3
    }
}
