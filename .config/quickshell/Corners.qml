import QtQuick
import Quickshell

// Скруглённые углы на каждом мониторе
Variants {
    model: Quickshell.screens

    Scope {
        id: s
        required property var modelData
        Corner { screen: s.modelData; corner: 0 }
        Corner { screen: s.modelData; corner: 1 }
        Corner { screen: s.modelData; corner: 2 }
        Corner { screen: s.modelData; corner: 3 }
    }
}
