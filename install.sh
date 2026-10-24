#!/usr/bin/env bash
#
# install-hyprland-setup.sh
# Установка Hyprland, SDDM, Rofi, шрифтов и Nautilus,
# включение SDDM и копирование .config в /home/USER/
#
# Запуск: sudo ./install-hyprland-setup.sh
# Папка .config должна лежать рядом со скриптом (в той же директории).

set -euo pipefail

# ---------- 1. Проверка прав root ----------
if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: скрипт нужно запускать от имени root (sudo)." >&2
    exit 1
fi

# ---------- 2. Определение целевого пользователя ----------
# Если скрипт запущен через sudo, берём имя реального пользователя.
# Иначе запрашиваем ввод.
if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
else
    read -rp "Введите имя пользователя, для которого копировать .config: " TARGET_USER
fi

# Проверяем, что пользователь существует
if ! id "$TARGET_USER" &>/dev/null; then
    echo "Ошибка: пользователь '$TARGET_USER' не найден." >&2
    exit 1
fi

TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
echo "Целевой пользователь: $TARGET_USER (домашний каталог: $TARGET_HOME)"

# ---------- 3. Установка пакетов ----------
PACKAGES=(
    hyprland
    sddm
    rofi
    ttf-firacode-nerd
    noto-fonts
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    noto-fonts-emoji
    nautilus
)

echo "Обновление базы пакетов..."
pacman -Sy --noconfirm

echo "Установка пакетов: ${PACKAGES[*]}"
pacman -S --needed --noconfirm "${PACKAGES[@]}"

# ---------- 4. Включение SDDM ----------
echo "Включение службы SDDM..."
systemctl enable sddm.service

# ---------- 5. Копирование .config ----------
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_SRC="${SCRIPT_DIR}/.config"

if [[ ! -d "$CONFIG_SRC" ]]; then
    echo "Предупреждение: папка $CONFIG_SRC не найдена. Копирование .config пропущено." >&2
else
    CONFIG_DEST="${TARGET_HOME}/.config"

    # Резервная копия существующего .config
    if [[ -d "$CONFIG_DEST" ]]; then
        BACKUP="${CONFIG_DEST}_backup_$(date +%Y%m%d_%H%M%S)"
        echo "Создаю резервную копию существующего .config → $BACKUP"
        cp -a "$CONFIG_DEST" "$BACKUP"
    fi

    echo "Копирование .config в $CONFIG_DEST ..."
    mkdir -p "$CONFIG_DEST"
    cp -a "${CONFIG_SRC}/." "$CONFIG_DEST/"

    # Исправление прав: файлы должны принадлежать целевому пользователю
    chown -R "${TARGET_USER}:${TARGET_USER}" "$CONFIG_DEST"
    echo "Готово: .config скопирован и права выставлены."
fi

echo "Установка завершена."
echo "Перезагрузите систему или выполните: systemctl start sddm"
