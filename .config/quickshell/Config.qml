pragma Singleton
import Quickshell

// Личные настройки
Singleton {
    // Город для погоды. Пусто = определить автоматически по IP (сервис wttr.in)
    readonly property string weatherCity: ""
    readonly property int weatherRefreshMin: 20

    // Папка с обоями для переключателя. Пусто = ~/Pictures/Wallpapers (или ~/Pictures)
    readonly property string wallpaperDir: ""
    // Своя команда установки обоев (shell). Путь к картинке лежит в $f.
    // Пример: "swww img \"$f\" --transition-type wipe"
    // Пусто = автоопределение: swww → hyprpaper → swaybg
    readonly property string wallpaperSetter: ""
}
