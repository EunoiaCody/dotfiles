sketchybar --add item ram right \
           --set ram \
           icon=󰍛 icon.color=$YELLOW \
           label="0M (0%)" \
           label.color=$TEXT \
           background.color=$SURFACE0 \
           background.corner_radius=8 \
           background.border_width=1 \
           background.border_color=$YELLOW \
           update_freq=5 \
           script="$PLUGIN_DIR/ram.sh"
