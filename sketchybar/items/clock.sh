sketchybar --add item clock right \
           --set clock update_freq=10 \
           icon= icon.color=$PEACH \
           label.color=$TEXT \
           background.color=$SURFACE0 \
           background.corner_radius=8 \
           background.border_width=1 \
           background.border_color=$PEACH \
           script="$PLUGIN_DIR/clock.sh"
