#!/bin/bash

# Network speed monitor
# Shows upload and download speed

# Auto detect active interface
INTERFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
[ -z "$INTERFACE" ] && INTERFACE="en1"

# Get current bytes
function get_bytes() {
  netstat -ibn | grep -e "^$INTERFACE " -m 1 | awk '{print $7" "$10}'
}

# Cache file for storing previous values
CACHE_FILE="/tmp/sketchybar_network_cache"

# Read previous values
if [ -f "$CACHE_FILE" ]; then
  read -r PREV_DOWN PREV_UP PREV_TIME < "$CACHE_FILE"
else
  PREV_DOWN=0
  PREV_UP=0
  PREV_TIME=$(date +%s)
fi

# Get current values
CURRENT=$(get_bytes)
CURRENT_DOWN=$(echo "$CURRENT" | awk '{print $1}')
CURRENT_UP=$(echo "$CURRENT" | awk '{print $2}')
CURRENT_TIME=$(date +%s)

# Calculate time difference
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
[ "$TIME_DIFF" -eq 0 ] && TIME_DIFF=1

# Calculate speed (bytes per second)
DOWN_SPEED=$(( (CURRENT_DOWN - PREV_DOWN) / TIME_DIFF ))
UP_SPEED=$(( (CURRENT_UP - PREV_UP) / TIME_DIFF ))

# Prevent negative values
[ "$DOWN_SPEED" -lt 0 ] && DOWN_SPEED=0
[ "$UP_SPEED" -lt 0 ] && UP_SPEED=0

# Save current values
echo "$CURRENT_DOWN $CURRENT_UP $CURRENT_TIME" > "$CACHE_FILE"

# Format speed
function format_speed() {
  local speed=$1
  if [ "$speed" -gt 1073741824 ]; then
    printf "%.1fG" $(echo "scale=1; $speed/1073741824" | bc)
  elif [ "$speed" -gt 1048576 ]; then
    printf "%.1fM" $(echo "scale=1; $speed/1048576" | bc)
  elif [ "$speed" -gt 1024 ]; then
    printf "%.0fK" $(echo "scale=0; $speed/1024" | bc)
  else
    printf "%.0fB" "$speed"
  fi
}

DOWN_FORMATTED=$(format_speed $DOWN_SPEED)
UP_FORMATTED=$(format_speed $UP_SPEED)

sketchybar --set "$NAME" label="↓${DOWN_FORMATTED} ↑${UP_FORMATTED}"
