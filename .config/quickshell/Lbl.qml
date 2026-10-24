import QtQuick
import QtQuick.Layouts

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    Layout.minimumWidth: 0          // иначе длинная строка раздувает весь Layout
}
