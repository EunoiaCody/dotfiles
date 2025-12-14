sketchybar --add item network right \
           --set network \
           icon=󰛳 icon.color=$TEAL \
           label="↓0K ↑0K" \
           label.color=$TEXT \
           background.color=$SURFACE0 \           background.corner_radius=8 \
           background.border_width=1 \
           background.border_color=$TEAL \           update_freq=2 \
           script="$PLUGIN_DIR/network.sh"
