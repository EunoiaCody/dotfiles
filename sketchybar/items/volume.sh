sketchybar --add item volume right \
           --set volume \
           icon=󰕾 icon.color=$SAPPHIRE \
           label.color=$TEXT \
           background.color=$SURFACE0 \
           background.corner_radius=8 \
           background.border_width=1 \
           background.border_color=$SAPPHIRE \
           script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change mouse.scrolled \