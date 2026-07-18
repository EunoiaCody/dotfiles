#!/bin/bash
# wave_sys.sh — 实时输出系统音频音量 (0-60 整数) 到 stdout
# AudioContent.qml 通过 SplitParser 逐行读取
set -euo pipefail

SINK=$(pactl get-default-sink 2>/dev/null)
if [ -z "$SINK" ]; then
    while true; do echo "2"; sleep 0.05; done
    exit 0
fi

MONITOR="${SINK}.monitor"

# 检查 monitor source 是否存在
if ! pactl list short sources 2>/dev/null | grep -q "$MONITOR"; then
    while true; do echo "2"; sleep 0.05; done
    exit 0
fi

parec --device="$MONITOR" --format=s16le --rate=8000 --channels=1 2>/dev/null | \
    ffmpeg -hide_banner -loglevel error \
        -f s16le -ar 8000 -ac 1 -i pipe:0 \
        -af "asetnsamples=400,astats=reset=1:metadata=1,ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=-" \
        -f null /dev/null 2>/dev/null | \
    grep --line-buffered 'RMS_level=' | \
    while IFS='=' read -r _ db; do
        awk -v db="$db" 'BEGIN {
            v = (db + 60) * 60 / 60;
            if (v < 2) v = 2;
            if (v > 60) v = 60;
            printf "%d\n", int(v)
        }'
    done
