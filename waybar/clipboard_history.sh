#!/bin/bash



cliphist list | rofi -dmenu -i -p "История буфера обмена: " | cliphist decode | wl-copy
