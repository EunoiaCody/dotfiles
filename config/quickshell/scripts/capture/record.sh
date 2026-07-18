#!/bin/bash
set -euo pipefail

# ============================================================
# record.sh — 灵动岛工具箱 录屏 / GIF / 录音 统一控制
#
# 用法:
#   record.sh start video     # 开始录屏 (slurp 选区 → wf-recorder → MP4)
#   record.sh stop  video     # 停止录屏
#   record.sh start gif       # 开始录制 GIF (slurp 选区 → 临时 MP4)
#   record.sh stop  gif       # 停止 → ffmpeg + gifski 转 GIF → 落盘
#   record.sh start audio_mic # 开始录麦克风
#   record.sh start audio_sys # 开始录系统声音
#   record.sh stop  audio     # 停止录音
# ============================================================

ACTION="${1:-}"
MODE="${2:-}"

SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
RECORDINGS_DIR="$HOME/Videos/Recordings"
TMP_DIR="/tmp/niri-capture"
PID_DIR="$TMP_DIR/pids"

mkdir -p "$SCREENSHOTS_DIR" "$RECORDINGS_DIR" "$TMP_DIR" "$PID_DIR"

# --------------- 依赖检查 ---------------
check_dep() {
    if ! command -v "$1" &>/dev/null; then
        notify-send -a "录屏工具" "❌ 缺少依赖: $1" "请先安装: sudo pacman -S $1" -u critical
        exit 1
    fi
}

notify_ok() {
    notify-send -a "录屏工具" "$1" "$2" -i camera-photo
}

notify_err() {
    notify-send -a "录屏工具" "❌ $1" "$2" -u critical
}

# --------------- 停止旧实例 ---------------
stop_old_pid() {
    local pidfile="$PID_DIR/$1.pid"
    if [ -f "$pidfile" ]; then
        local old_pid
        old_pid=$(cat "$pidfile")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill -INT "$old_pid" 2>/dev/null || true
            sleep 0.3
            kill -KILL "$old_pid" 2>/dev/null || true
        fi
        rm -f "$pidfile"
    fi
}

# --------------- 录屏 ---------------
start_video() {
    check_dep wf-recorder
    check_dep slurp
    stop_old_pid "record-video"

    local geometry
    geometry=$(slurp -d -c "#b4befe44" -b "#1e1e2e66" -w 2) || {
        notify_err "录屏取消" "未选择区域"
        exit 0
    }

    local filename="$RECORDINGS_DIR/Recording from $(date '+%Y-%m-%d %H-%M-%S').mp4"
    wf-recorder -g "$geometry" -f "$filename" &
    local pid=$!
    echo "$pid" > "$PID_DIR/record-video.pid"
    notify_ok "🔴 录屏中..." "单击灵动岛红色按钮停止录制"
}

stop_video() {
    local pidfile="$PID_DIR/record-video.pid"
    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill -INT "$pid" 2>/dev/null || true
            sleep 0.5
            kill -KILL "$pid" 2>/dev/null || true
        fi
        rm -f "$pidfile"
        notify_ok "✅ 录屏已保存" "路径: $RECORDINGS_DIR"
    else
        notify_err "没有正在进行的录屏"
    fi
}

# --------------- GIF ---------------
start_gif() {
    check_dep wf-recorder
    check_dep slurp
    stop_old_pid "record-gif"

    local geometry
    geometry=$(slurp -d -c "#b4befe44" -b "#1e1e2e66" -w 2) || {
        notify_err "GIF 录制取消" "未选择区域"
        exit 0
    }

    local tmp_mp4="$TMP_DIR/gif_temp_$$.mp4"
    wf-recorder -g "$geometry" -f "$tmp_mp4" -c libx264 -p preset=ultrafast -p crf=18 &
    local pid=$!
    echo "$pid" > "$PID_DIR/record-gif.pid"
    echo "$tmp_mp4" > "$PID_DIR/record-gif.tmpfile"
    notify_ok "🔴 录制 GIF 中..." "单击红色按钮停止并生成 GIF"
}

stop_gif() {
    local pidfile="$PID_DIR/record-gif.pid"
    local tmpfile_path="$PID_DIR/record-gif.tmpfile"
    local tmp_mp4

    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill -INT "$pid" 2>/dev/null || true
            sleep 0.5
            kill -KILL "$pid" 2>/dev/null || true
        fi
        rm -f "$pidfile"
    fi

    if [ -f "$tmpfile_path" ]; then
        tmp_mp4=$(cat "$tmpfile_path")
        rm -f "$tmpfile_path"
    fi

    if [ -z "${tmp_mp4:-}" ] || [ ! -f "$tmp_mp4" ]; then
        notify_err "GIF 录制失败" "临时文件不存在"
        exit 1
    fi

    # 转 GIF: ffmpeg → 调色板 → gifski
    check_dep ffmpeg
    check_dep gifski

    local palette="$TMP_DIR/gif_palette_$$.png"
    local output_gif="$RECORDINGS_DIR/GIF from $(date '+%Y-%m-%d %H-%M-%S').gif"

    ffmpeg -y -i "$tmp_mp4" -vf "fps=15,palettegen=stats_mode=diff" "$palette" 2>/dev/null
    ffmpeg -y -i "$tmp_mp4" -i "$palette" -lavfi "fps=15[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" \
        -f gif - 2>/dev/null | gifski -o "$output_gif" --fps 15 --quality 90 -

    rm -f "$tmp_mp4" "$palette"
    notify_ok "✅ GIF 已生成" "路径: $output_gif"
}

# --------------- 录音 ---------------
start_audio() {
    local submode="$1"  # audio_mic 或 audio_sys

    # 优先用 pw-record (PipeWire), 回退 parec (PulseAudio)
    if command -v pw-record &>/dev/null; then
        check_dep pw-record
        local recorder="pw-record"
    elif command -v parec &>/dev/null; then
        check_dep parec
        local recorder="parec"
    else
        notify_err "缺少录音工具" "请安装 pipewire 或 pulseaudio"
        exit 1
    fi

    stop_old_pid "record-audio"

    local source_name
    local filename="$RECORDINGS_DIR/Audio from $(date '+%Y-%m-%d %H-%M-%S')"

    if [ "$submode" = "audio_mic" ]; then
        # 默认麦克风
        if [ "$recorder" = "pw-record" ]; then
            source_name=$(pactl get-default-source 2>/dev/null || echo "@DEFAULT_SOURCE@")
            filename="${filename}.opus"
            pw-record --target "$source_name" "$filename" &
        else
            filename="${filename}.wav"
            parec --format=s16le --rate=44100 "$filename" &
        fi
    elif [ "$submode" = "audio_sys" ]; then
        # 系统声音 monitor
        if [ "$recorder" = "pw-record" ]; then
            local default_sink
            default_sink=$(pactl get-default-sink 2>/dev/null || echo "")
            if [ -n "$default_sink" ]; then
                source_name="${default_sink}.monitor"
            else
                notify_err "无法获取默认音频输出" "请检查 PipeWire 状态"
                exit 1
            fi
            filename="${filename}.opus"
            pw-record --target "$source_name" "$filename" &
        else
            notify_err "系统录音需要 PipeWire" "PulseAudio 不支持 monitor 源"
            exit 1
        fi
    else
        notify_err "未知录音模式: $submode"
        exit 1
    fi

    local pid=$!
    echo "$pid" > "$PID_DIR/record-audio.pid"
    echo "$filename" > "$PID_DIR/record-audio.filename"
    notify_ok "🎙️ 录音中..." "模式: ${submode}"
}

stop_audio() {
    local pidfile="$PID_DIR/record-audio.pid"
    local namefile="$PID_DIR/record-audio.filename"
    local filename=""

    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill -INT "$pid" 2>/dev/null || true
            sleep 0.5
            kill -KILL "$pid" 2>/dev/null || true
        fi
        rm -f "$pidfile"
    fi

    if [ -f "$namefile" ]; then
        filename=$(cat "$namefile")
        rm -f "$namefile"
    fi

    if [ -n "$filename" ]; then
        notify_ok "✅ 录音已保存" "路径: $filename"
    else
        notify_err "没有正在进行的录音"
    fi
}

# --------------- 主入口 ---------------
case "$ACTION" in
    start)
        case "$MODE" in
            video)     start_video ;;
            gif)       start_gif ;;
            audio_mic) start_audio "audio_mic" ;;
            audio_sys) start_audio "audio_sys" ;;
            *)
                notify_err "未知模式: start $MODE" "可用: video | gif | audio_mic | audio_sys"
                exit 1
                ;;
        esac
        ;;
    stop)
        case "$MODE" in
            video) stop_video ;;
            gif)   stop_gif ;;
            audio) stop_audio ;;
            *)
                notify_err "未知模式: stop $MODE" "可用: video | gif | audio"
                exit 1
                ;;
        esac
        ;;
    *)
        notify_err "用法错误" "可用: start|stop video|gif|audio_mic|audio_sys|audio"
        exit 1
        ;;
esac
