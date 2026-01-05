#!/bin/bash

# Задержка 5 секунд. Этого времени хватит, чтобы вызвать Hyprlock.
sleep 5 

# Выберите, какой инструмент для скриншота вы используете:
# Вариант А: Hyprshot (если установлен)
# hyprshot -m output 

# Вариант Б: Grim (захват всего экрана)
grim -o $(hyprctl monitors | grep -E 'Monitor|active work' | grep -B 1 active | awk '/Monitor/ {print $2}') "$HOME/Pictures/Screenshots/hyprlock-$(date +%Y%m%d_%H%M%S).png"

# Или Grim + Slurp для захвата области (менее удобно с Hyprlock)
# grim -g "$(slurp)" "$HOME/Pictures/Screenshots/hyprlock-$(date +%Y%m%d_%H%M%S).png"

# Если вы хотите, чтобы скриншот был сделан, пока вы находитесь в Hyprlock, 
# убедитесь, что ваш инструмент скриншота может работать поверх блокировщика.
