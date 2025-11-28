#!/bin/bash
swayidle -w \
    timeout 60 'hyprlock' \
    timeout 61 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    before-sleep 'hyprlock' &
