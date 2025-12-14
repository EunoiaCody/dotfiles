#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

update_icon() {
  case "$1" in
    [6-9][0-9]|100) ICON="󰕾"
    ;;
    [3-5][0-9]) ICON="󰖀"
    ;;
    [1-9]|[1-2][0-9]) ICON="󰕿"
    ;;
    *) ICON="󰖁"
  esac
  sketchybar --set "$NAME" icon="$ICON" label="$1%"
}

case "$SENDER" in
  "volume_change")
    update_icon "$INFO"
    ;;
  "mouse.scrolled")
    # Get current volume
    VOLUME=$(osascript -e "output volume of (get volume settings)")
    # Scroll up = increase, scroll down = decrease
    if [ "$SCROLL_DELTA" -gt 0 ]; then
      VOLUME=$((VOLUME + 5))
    else
      VOLUME=$((VOLUME - 5))
    fi
    # Clamp volume between 0 and 100
    [ "$VOLUME" -lt 0 ] && VOLUME=0
    [ "$VOLUME" -gt 100 ] && VOLUME=100
    # Set volume
    osascript -e "set volume output volume $VOLUME"
    update_icon "$VOLUME"
    ;;
esac
