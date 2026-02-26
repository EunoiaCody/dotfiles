#!/bin/sh
env > /tmp/niri-wallpaper-env.log

WALLPAPER_DIR="$HOME/Wallpapers"
CURRENT=$(swww query | grep path | awk '{print $2}')
ALL_IMAGES=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
if [ -n "$CURRENT" ]; then
    NEXT=$(echo "$ALL_IMAGES" | grep -vF "$CURRENT" | shuf -n 1)
else
    NEXT=$(echo "$ALL_IMAGES" | shuf -n 1)
fi
if [ -z "$NEXT" ]; then
    NEXT="$CURRENT"
fi
if [ -z "$NEXT" ]; then
    echo "No wallpaper found in $WALLPAPER_DIR"
    exit 1
fi
echo "$NEXT" > /tmp/niri-wallpaper.log
swww img "$NEXT" --transition-type center --transition-step 90 --transition-fps 120 >> /tmp/niri-wallpaper.log 2>&1
