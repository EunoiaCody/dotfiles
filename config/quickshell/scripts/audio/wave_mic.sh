#!/bin/bash
# wave_mic.sh — 实时输出麦克风音量 (0-60 整数) 到 stdout
# AudioContent.qml 通过 SplitParser 逐行读取
set -euo pipefail

SOURCE=$(pactl get-default-source 2>/dev/null || echo "@DEFAULT_SOURCE@")

# 每 400 个样本(=50ms@8kHz)输出一次 RMS，映射到 0-60
parec --device="$SOURCE" --format=s16le --rate=8000 --channels=1 2>/dev/null | \
    ffmpeg -hide_banner -loglevel error \
        -f s16le -ar 8000 -ac 1 -i pipe:0 \
        -af "asetnsamples=400,astats=reset=1:metadata=1,ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=-" \
        -f null /dev/null 2>/dev/null | \
    grep --line-buffered 'RMS_level=' | \
    while IFS='=' read -r _ db; do
        # dB 映射到 0-60: -60dB→0, 0dB→60
        awk -v db="$db" 'BEGIN {
            v = (db + 60) * 60 / 60;
            if (v < 2) v = 2;
            if (v > 60) v = 60;
            printf "%d\n", int(v)
        }'
    done
