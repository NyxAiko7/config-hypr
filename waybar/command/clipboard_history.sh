#!/bin/bash

# Вызывает Cliphist, форматирует вывод, передает в Rofi, 
# затем декодирует выбранный элемент и помещает его обратно в буфер обмена.

cliphist list | rofi -dmenu -i -p "История буфера обмена: " | cliphist decode | wl-copy
