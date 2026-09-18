#!/usr/bin/env bash

generate_workspaces() {
    active_ws=$(hyprctl monitors -j | jq -r '.[0].activeWorkspace.id')
    
    # Генерируем yuck-разметку виджетов
    echo -n '(box :class "workspaces" :spacing 5 '
    for i in {1..10}; do
        if [ "$i" -eq "$active_ws" ]; then
            echo -n "(button :class \"ws-btn active\" :onclick \"hyprctl dispatch workspace $i\" \"$i\") "
        else
            echo -n "(button :class \"ws-btn\" :onclick \"hyprctl dispatch workspace $i\" \"$i\") "
        fi
    done
    echo ')'
}

# Первичный вывод
generate_workspaces

# Подписка на события Hyprland через UNIX-сокет
socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
    case "$line" in
        workspace*|focusedmon*)
            generate_workspaces
            ;;
    esac
done
