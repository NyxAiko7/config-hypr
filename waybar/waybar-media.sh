#!/bin/sh

# Проверяем статус медиаплеера
status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)

    # 1. Получаем позицию в СЕКУНДАХ (может быть с плавающей точкой)
    position_s=$(playerctl position 2>/dev/null)
    
    # 2. Получаем длину трека в МИКРОСЕКУНДАХ
    length_us=$(playerctl metadata mpris:length 2>/dev/null)
    
    # Функция для форматирования времени (принимает секунды или микросекунды)
    format_time() {
        INPUT=$1
        IS_MICROSECONDS=0

        # Определяем, что за число: если очень большое, то это микросекунды
        if [ "$INPUT" -gt 10000000 ] 2>/dev/null; then
            IS_MICROSECONDS=1
        fi

        # Конвертируем в секунды и округляем до целого числа (нужен bc!)
        if [ "$IS_MICROSECONDS" -eq 1 ]; then
            secs=$(echo "$INPUT / 1000000" | bc)
        else
            # Если это секунды (например, 29.16), используем bc для округления
            secs=$(echo "$INPUT / 1" | bc) 
        fi
        
        # Если время равно 0 или пусто, возвращаем --:--
        if [ -z "$secs" ] || [ "$secs" -le 0 ] 2>/dev/null; then
            echo "--:--"
            return
        fi
        
        # Форматирование MM:SS
        minutes=$(echo "$secs / 60" | bc)
        seconds=$(echo "$secs % 60" | bc)
        
        printf "%02d:%02d" "$minutes" "$seconds"
    }

    # Позицию форматируем как секунды, длину как микросекунды
    position_formatted=$(format_time "$position_s")
    length_formatted=$(format_time "$length_us")

    # Определяем иконку статуса
    if [ "$status" = "Playing" ]; then
        status_icon="▶"
    else
        status_icon="⏸"
    fi
    
    # Вывод
    echo " ${status_icon} [${position_formatted}/${length_formatted}] ${artist} - ${title}"
else
    echo "No player"
fi
