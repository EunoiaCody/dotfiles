#!/usr/bin/env bash

# 1. 准备目录
cache_dir="$HOME/.cache/wallpaper_rofi"
mkdir -p "$cache_dir"

# 2. 从 swww 获取当前壁纸
current_wall=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -n1 | tr -d '[:space:]')
last_wall_file="$cache_dir/last_wallpaper"

# 目标尺寸 (根据您的 Rofi 窗口调整)
# dummywall width=37em, window height=33em => 大约 600x530 px
TARGET_SIZE="600x530"

# 3. 检查逻辑：是否需要更新
need_update=false
last_wall=""

# 读取上次记录的壁纸路径
if [ -f "$last_wall_file" ]; then
    last_wall=$(cat "$last_wall_file")
fi

# 如果：
# (a) 缓存图片文件不存在
# (b) 上次记录不存在
# (c) 当前壁纸变了
if [ ! -f "$cache_dir/current" ] || [ -z "$last_wall" ] || [ "$current_wall" != "$last_wall" ]; then
    need_update=true
fi

# 4. 执行更新
if [ "$need_update" = true ] && [ -n "$current_wall" ] && [ -f "$current_wall" ]; then
    # 使用 magick 裁剪并居中 (resize ^ + gravity center + extent)
    # ^ 符号表示缩放时填满最小边
    magick "$current_wall" \
        -resize "${TARGET_SIZE}^" \
        -gravity center \
        -extent "$TARGET_SIZE" \
        "$cache_dir/current"
    
    # 将裁剪后的同款图片链接给 blurred，防止主题依然调用它
    # (有些主题的 mode-switcher 还在使用 url("~/.cache/.../blurred") )
    ln -sf "$cache_dir/current" "$cache_dir/blurred"
    
    # 保存当前的壁纸路径，供下次比对
    echo "$current_wall" > "$last_wall_file"
fi

# 5. 启动 Rofi
rofi -show drun -theme ~/.config/rofi/config.rasi