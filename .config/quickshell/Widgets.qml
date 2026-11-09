import Quickshell

Variants {
    model: Quickshell.screens

    WidgetScreen {
        required property var modelData
        screen: modelData
    }
}
