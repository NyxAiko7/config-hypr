import QtQuick
import QtQuick.Layouts

// «Остров» панели. В горизонтальной панели — стикер в ряд,
// в вертикальной — компактная колонка иконок.
Item {
    id: island

    default property alias content: inner.data

    readonly property bool vertical: PanelConfig.vertical
    readonly property real vWidth: Theme.islandHeight + 8

    property color fill: Rock.ink2
    property color shadowColor: Rock.pink
    property real shadowOffset: Rock.panelShadow
    property real tilt: 0

    width: vertical ? vWidth : inner.implicitWidth + 20
    height: vertical ? inner.implicitHeight + 20 : Theme.islandHeight
    rotation: Rock.comic ? tilt : 0
    transformOrigin: Item.Center

    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    IslandSurface {
        anchors.fill: parent
        radius: Rock.panelRadius
        fill: island.fill
        shadowColor: island.shadowColor
        shadowOffset: island.shadowOffset
    }

    // золотая кромка слева у HSR-острова
    Rectangle {
        visible: !Rock.comic && !Rock.marisa && !Rock.sao
        width: 2
        height: Math.min(parent.height * 0.55, 26)
        radius: 1
        color: Rock.a(Rock.gold, 0.55)
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
    }

    // циановая HUD-кромка Aincrad
    Rectangle {
        visible: Rock.sao
        width: 2
        height: Math.min(parent.height * 0.52, 20)
        radius: 0
        color: Rock.gold
        opacity: 0.75
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        visible: Rock.sao
        width: 2
        height: Math.min(parent.height * 0.26, 9)
        radius: 0
        color: Rock.a(Rock.gold, 0.4)
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
    }

    // шашечная кромка гримуара
    MarisaTrim {
        visible: Rock.marisa
        vertical: true
        width: 4
        cell: 4
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        anchors.leftMargin: 1
    }

    GridLayout {
        id: inner
        anchors.centerIn: parent
        flow: island.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: island.vertical ? 1 : 1000
        rowSpacing: island.vertical ? 5 : 3
        columnSpacing: island.vertical ? 5 : 3
    }
}
