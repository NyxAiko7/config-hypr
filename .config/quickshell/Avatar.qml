import QtQuick
import Qt5Compat.GraphicalEffects

// Круглый аватар: картинка пользователя, либо первая буква имени, если файл не выбран.
Item {
    id: root

    property string source: ""
    property string letter: ""
    property color bg: "#ff4f8b"
    property color fg: "#fff4e8"
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real radius: width / 2

    property string fontFamily: "DejaVu Sans"
    property int fontSize: 16
    property int fontWeight: Font.Bold
    property real textRotation: 0

    readonly property bool hasImage: source !== "" && img.status === Image.Ready

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        color: "white"
        visible: false
        layer.enabled: true
    }

    OpacityMask {
        anchors.fill: parent
        source: img
        maskSource: mask
        visible: root.hasImage
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.bg
        visible: !root.hasImage
        Text {
            anchors.centerIn: parent
            text: root.letter
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            font.weight: root.fontWeight
            rotation: root.textRotation
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.borderColor
    }
}
