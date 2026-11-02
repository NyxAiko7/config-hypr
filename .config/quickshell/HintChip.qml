import QtQuick

// Чип-подсказка клавиши для нижнего бара локскрина (Enter / Tab / Esc).
// Вынесен в отдельный файл, чтобы не зависеть от inline-компонентов.
Rectangle {
    id: chip
    property string keyName: ""
    property string action: ""
    implicitHeight: 20
    implicitWidth: row.implicitWidth + 14
    radius: 10
    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Lbl { text: chip.keyName; color: Theme.accent; font.pixelSize: 10; font.bold: true }
        Lbl { text: chip.action; color: Theme.muted; font.pixelSize: 10 }
    }
}
