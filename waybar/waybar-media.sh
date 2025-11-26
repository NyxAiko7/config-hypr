#!/bin/sh


status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)

    
    position_s=$(playerctl position 2>/dev/null)
    
   
    length_us=$(playerctl metadata mpris:length 2>/dev/null)
    
    
    format_time() {
        INPUT=$1
        IS_MICROSECONDS=0

        
        if [ "$INPUT" -gt 10000000 ] 2>/dev/null; then
            IS_MICROSECONDS=1
        fi

        
        if [ "$IS_MICROSECONDS" -eq 1 ]; then
            secs=$(echo "$INPUT / 1000000" | bc)
        else
            
            secs=$(echo "$INPUT / 1" | bc) 
        fi
        
        
        if [ -z "$secs" ] || [ "$secs" -le 0 ] 2>/dev/null; then
            echo "--:--"
            return
        fi
        
        
        minutes=$(echo "$secs / 60" | bc)
        seconds=$(echo "$secs % 60" | bc)
        
        printf "%02d:%02d" "$minutes" "$seconds"
    }

    
    position_formatted=$(format_time "$position_s")
    length_formatted=$(format_time "$length_us")

    
    if [ "$status" = "Playing" ]; then
        status_icon="▶"
    else
        status_icon="⏸"
    fi
    
    
    echo " ${status_icon} [${position_formatted}/${length_formatted}] ${artist} - ${title}"
else
    echo "No player"
fi
