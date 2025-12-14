#!/bin/bash

# RAM usage monitor

# Get memory info using vm_stat
VM_STAT=$(vm_stat)

# Parse values (pages)
PAGES_FREE=$(echo "$VM_STAT" | grep "Pages free" | awk '{print $3}' | tr -d '.')
PAGES_ACTIVE=$(echo "$VM_STAT" | grep "Pages active" | awk '{print $3}' | tr -d '.')
PAGES_INACTIVE=$(echo "$VM_STAT" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
PAGES_SPECULATIVE=$(echo "$VM_STAT" | grep "Pages speculative" | awk '{print $3}' | tr -d '.')
PAGES_WIRED=$(echo "$VM_STAT" | grep "Pages wired down" | awk '{print $4}' | tr -d '.')
PAGES_COMPRESSED=$(echo "$VM_STAT" | grep "Pages occupied by compressor" | awk '{print $5}' | tr -d '.')

# Page size (usually 4096 bytes)
PAGE_SIZE=4096

# Calculate used and total memory (in bytes)
USED_MEM=$(( (PAGES_ACTIVE + PAGES_WIRED + PAGES_COMPRESSED) * PAGE_SIZE ))
TOTAL_MEM=$(sysctl -n hw.memsize)

# Calculate percentage
PERCENTAGE=$(echo "scale=0; $USED_MEM * 100 / $TOTAL_MEM" | bc)

# Format memory usage
function format_mem() {
  local mem=$1
  if [ "$mem" -gt 1073741824 ]; then
    printf "%.1fG" $(echo "scale=1; $mem/1073741824" | bc)
  else
    printf "%.0fM" $(echo "scale=0; $mem/1048576" | bc)
  fi
}

USED_FORMATTED=$(format_mem $USED_MEM)

sketchybar --set "$NAME" label="${USED_FORMATTED} (${PERCENTAGE}%)"
