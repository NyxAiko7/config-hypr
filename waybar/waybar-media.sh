#!/bin/sh


if ! command -v bc &> /dev/null; then
    echo "ERROR: bc is not installed."
    exit 1
fi


format_time() {
    INPUT=$1
    if [ "$INPUT" -gt 10000000 ] 2>/dev/null; then
       
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
# -----------------------------------------------


ART_FILE="/tmp/waybar_album_art.png"
ART_TAG=""

if [ -s "$ART_FILE" ]; then
    
    ART_TAG="<img src='file://${ART_FILE}' class='album-art-icon'>"
fi
# -----------------------------------


status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)

    position_s=$(playerctl position 2>/dev/null)
    length_us=$(playerctl metadata mpris:length 2>/dev/null)
    
    length_s=$(echo "$length_us / 1000000" | bc)
    
    is_live=false
    
    if [ -z "$length_us" ] || [ "$length_us" -le 0 ] 2>/dev/null; then
        is_live=true
    fi

    if [ "$is_live" = true ]; then
        time_info="[LIVE]"
        PROGRESS_BAR=""
    else
        
        BAR_LENGTH=10
        progress_percent=$(echo "scale=0; ($position_s * 100) / $length_s" | bc)
        FILLED_CHARS=$(echo "scale=0; ($progress_percent * $BAR_LENGTH) / 100" | bc)
        EMPTY_CHARS=$((BAR_LENGTH - FILLED_CHARS))
        
        PROGRESS_BAR=""
        for i in $(seq 1 $FILLED_CHARS); do PROGRESS_BAR="${PROGRESS_BAR}■"; done
        for i in $(seq 1 $EMPTY_CHARS); do PROGRESS_BAR="${PROGRESS_BAR}□"; done
        
        
        position_formatted=$(format_time "$position_s")
        length_formatted=$(format_time "$length_us")
        time_info="[${position_formatted}/${length_formatted}]"
    fi

    
    if [ "$status" = "Playing" ]; then
        status_icon="▶"
    else
        status_icon="⏸"
    fi
    
    
    echo "${ART_TAG}  ${status_icon} ${time_info} ${artist} - ${title} ${PROGRESS_BAR}"
else
    
    echo "No player"
fi
