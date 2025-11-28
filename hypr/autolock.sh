#!/bin/bash
swayidle -w \
    timeout 300 'hyprlock' \
    timeout 301 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    before-sleep 'hyprlock' &
