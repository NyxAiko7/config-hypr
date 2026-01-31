#!/bin/bash

# Простой плавный прогресс-бар

title=$(playerctl metadata --format '{{title}}' 2>/dev/null | cut -c1-35)
artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null | cut -c1-25)
status=$(playerctl status 2>/dev/null)

if [ -z "$status" ] || [ "$status" = "Stopped" ]; then
    echo "󰝛 No music playing"
    echo ""
    exit 0
fi

if [ "$status" = "Playing" ]; then
    icon="󰐌"
else
    icon="󰏤"
fi

position=$(playerctl position 2>/dev/null)
duration=$(playerctl metadata mpris:length 2>/dev/null | awk '{print $1/1000000}')

if [ -n "$position" ] && [ -n "$duration" ] && [ "$duration" -gt 0 ]; then
    width=20
    
    # Используем bc для точных вычислений
    filled=$(echo "scale=10; $position / $duration * $width" | bc)
    filled_int=$(echo "$filled" | cut -d. -f1)
    filled_frac=$(echo "$filled" | cut -d. -f2)
    filled_frac=${filled_frac:0:1}  # Первая цифра после запятой
    
    # Плавные символы
    bar_chars=(" " "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█")
    
    bar=""
    for ((i=0; i<width; i++)); do
        if [ $i -lt $filled_int ]; then
            bar+="█"
        elif [ $i -eq $filled_int ]; then
            # Определяем символ для дробной части
            frac_index=$((filled_frac / 1))
            frac_index=$((frac_index > 8 ? 8 : frac_index))
            bar+="${bar_chars[$frac_index]}"
        else
            bar+="░"
        fi
    done
    
    # Процент и время
    percent=$(printf "%.1f" $(echo "$position / $duration * 100" | bc -l))
    pos_time=$(date -u -d @${position} +"%M:%S" 2>/dev/null || printf "%02d:%02d" $((position/60)) $((position%60)))
    
    echo "$icon $title - $artist"
    echo "$bar $percent% ($pos_time)"
else
    echo "$icon $title - $artist"
    echo "No progress data"
fi
