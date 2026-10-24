1) Quickshell:  cp quickshell/*.qml ~/.config/quickshell/
2) SwayNC:      mkdir -p ~/.config/swaync && cp swaync/config.json swaync/style.css ~/.config/swaync/
3) Запусти wal: wal -i /путь/к/обоям.png
   Quickshell сам перекрасится и запишет ~/.config/swaync/colors.css.
4) Горячие клавиши: см. hyprland-binds.conf

Новое в этой версии
- Центр управления → стрелка ">" у плиток Wi-Fi и Bluetooth открывает списки сетей/устройств.
  Wi-Fi: нужен NetworkManager (nmcli). Bluetooth: bluez + bluetoothd.
- Обои и тема: кнопка кисти в баре или в центре управления (IPC: quickshell ipc call wallpaper toggle).
  Папку выбирай прямо в окне: кнопка с папкой → обзор каталогов → «Выбрать эту папку» (запоминается).
  Значение по умолчанию: ~/Pictures/Wallpapers (или wallpaperDir в Config.qml).
  Для установки обоев нужен swww, hyprpaper или swaybg; для цветов — pywal (wal).
- Погода: curl; город в Config.qml.
