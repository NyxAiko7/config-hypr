1) Quickshell:  cp quickshell/*.qml ~/.config/quickshell/
2) SwayNC:      mkdir -p ~/.config/swaync && cp swaync/config.json swaync/style.css ~/.config/swaync/
3) Запусти wal: wal -i /путь/к/обоям.png
   Quickshell сам подхватит палитру, перекрасит панель и запишет
   ~/.config/swaync/colors.css (шаблоны pywal и симлинки больше не нужны).
4) Горячие клавиши: см. hyprland-binds.conf
Проверка: в выводе `quickshell` должна появиться строка "Theme: палитра обновлена из ...".
