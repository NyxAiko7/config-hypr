#!/bin/bash
swayidle -w \
    timeout 1200 'hyprlock' \
    timeout 1201 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    before-sleep 'hyprlock' &
