pragma Singleton
import Quickshell

// Личные настройки
Singleton {
    // Погода: достаточно оставить всё пустым — место определится по IP.
    // Можно указать город (найдётся автоматически) или точные координаты.
    readonly property string weatherCity: ""
    readonly property string weatherLat: ""        // например "55.75"
    readonly property string weatherLon: ""        // например "37.62"
    readonly property int weatherRefreshMin: 20

    // Папка с обоями для переключателя. Пусто = ~/Pictures/Wallpapers (или ~/Pictures)
    readonly property string wallpaperDir: ""
    // Своя команда установки обоев (shell). Путь к картинке лежит в $f.
    // Пример: "awww img \"$f\" --transition-type wipe"
    // Пусто = автоопределение: awww → swww → hyprpaper → swaybg
    readonly property string wallpaperSetter: ""
}
