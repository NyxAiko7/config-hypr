import QtQuick

// Сегментная полоса в духе HP/нагрузки Aincrad.
// При hpMode цвет плавно уходит от зелёного к жёлтому и красному.
Item {
    id: root

    property real value: 0.5
    property int segments: 24
    property real gap: 2
    property color fill: Rock.gold
    property color track: Rock.a(Rock.gold, 0.14)
    property bool hpMode: false
    property color warnColor: "#ffd45c"

    implicitHeight: 8
    height: implicitHeight
    opacity: Rock.sao ? 1 : 0

    readonly property int activeSegments: Math.round(Math.max(0, Math.min(1, value)) * segments)
    readonly property real cell: Math.max(1, (width - gap * (segments - 1)) / segments)

    Repeater {
        model: root.segments
        delegate: Rectangle {
            required property int index
            readonly property bool active: index < root.activeSegments
            readonly property color tone: root.hpMode
                ? ((index + 1) / root.segments > 0.62 ? Rock.hp
                   : (index + 1) / root.segments > 0.32 ? root.warnColor : Rock.danger)
                : root.fill
            x: index * (root.cell + root.gap)
            width: root.cell
            height: root.height
            radius: 1
            color: active ? tone : root.track
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }
}
