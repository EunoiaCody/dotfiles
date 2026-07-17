#!/bin/bash

# 还原配置文件脚本（带本地备份，存在 .bak 先删除再备份）
# 将 dotfiles 仓库中的配置文件恢复到 ~/.config/ 和 ~/
# config/<name> → ~/.config/<name>
# home/<name>   → ~/<name>   (name 以 . 开头，如 .pi)

set -e

echo "从 GitHub 拉取配置文件..."

git pull

echo "开始还原配置文件 ..."

cd "$(dirname "$0")"

# ~/.config/ 下的配置目录
CONFIG_DIRS=("kitty" "mpv" "neovide" "nvim" "fish" "aerospace" "sketchybar" "yazi" "figlet" "bat" "niri" "quickshell" "vscode")

# ~/ 下的配置（以 . 开头的文件/目录）
HOME_DIRS=(".pi")

# ── 还原 ~/.config/ ──
for dir in "${CONFIG_DIRS[@]}"; do
    SRC="config/$dir"
    DEST="$HOME/.config/$dir"
    BAK="$DEST.bak"

    echo "处理 ~/.config/$dir ..."

    if [ ! -d "$SRC" ]; then
        echo "⚠ 警告: dotfiles 仓库下未找到 $SRC，跳过还原"
        continue
    fi

    if [ -d "$DEST" ]; then
        if [ -d "$BAK" ]; then
            echo "→ 检测到 $BAK 已存在，先删除"
            rm -rf "$BAK"
        fi
        echo "→ 备份 $DEST 为 $BAK"
        mv "$DEST" "$BAK"
    fi

    cp -r "$SRC" "$DEST"
    echo "✓ ~/.config/$dir 还原完成"
done

# ── 还原 ~/ ──
for name in "${HOME_DIRS[@]}"; do
    SRC="home/$name"
    DEST="$HOME/$name"
    BAK="$DEST.bak"

    echo "处理 ~/$name ..."

    if [ ! -e "$SRC" ] && [ ! -d "$SRC" ]; then
        echo "⚠ 警告: dotfiles 仓库下未找到 $SRC，跳过还原"
        continue
    fi

    if [ -e "$DEST" ] || [ -d "$DEST" ]; then
        if [ -e "$BAK" ] || [ -d "$BAK" ]; then
            echo "→ 检测到 $BAK 已存在，先删除"
            rm -rf "$BAK"
        fi
        echo "→ 备份 $DEST 为 $BAK"
        mv "$DEST" "$BAK"
    fi

    cp -r "$SRC" "$DEST"
    echo "✓ ~/$name 还原完成"
done

echo "全部配置文件还原完成！"
