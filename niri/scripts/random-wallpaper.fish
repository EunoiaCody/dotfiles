#!/usr/bin/env fish

# 1. 记录环境变量 (调试用)
env >/tmp/niri-wallpaper-env.log

set WALLPAPER_DIR "$HOME/Wallpapers"

# 2. 获取当前壁纸路径 (增强健壮性)
# swww query 输出可能包含多行或尾随空格，这里强制提取第一个匹配的绝对路径
set CURRENT (swww query | string match -r '/home/.*?\.(jpg|jpeg|png)' | head -n 1 | string trim)

# 3. 获取所有图片 (排除 webp)
set ALL_IMAGES $WALLPAPER_DIR/**/*.{jpg,jpeg,png}

# 4. 筛选下一张壁纸 (排除当前)
if test -n "$CURRENT"
    # 使用 string match -v -e (完全匹配模式) 排除
    set CANDIDATES (printf "%s\n" $ALL_IMAGES | string match -v -e "$CURRENT")

    # 调试信息：如果觉得候选列表有问题可以取消注释下面这行
    # echo "Candidates count: " (count $CANDIDATES)

    set NEXT (random choice $CANDIDATES)
else
    set NEXT (random choice $ALL_IMAGES)
end

# 5. 兜底逻辑
if test -z "$NEXT" -a -n "$CURRENT"
    set NEXT "$CURRENT"
end

if test -z "$NEXT"
    set_color red
    echo "Error: 在 $WALLPAPER_DIR 中未发现有效的图片文件"
    set_color normal
    exit 1
end

# --- 调试输出 ---
# set_color cyan
# echo "Current:  " (set_color white; echo "$CURRENT")
# echo "Selected: " (set_color yellow; echo "$NEXT")
# set_color normal
# ----------------

# 6. 执行切换
echo "$NEXT" >/tmp/niri-wallpaper.log
swww img "$NEXT" --transition-type any --transition-bezier ".17,.67,.83,.67" --transition-step 90 --transition-fps 120 >>/tmp/niri-wallpaper.log 2>&1
