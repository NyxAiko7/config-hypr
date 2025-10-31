#!/bin/bash
cava -p ~/.config/cava/config-waybar | while read -r line; do
    echo "{\"text\":\"$line\"}"
done
