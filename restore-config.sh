#!/bin/bash

# 还原配置文件脚本（带本地备份，存在 .bak 先删除再备份）
# 将 dotfiles 仓库中的配置文件恢复到 ~/.config/，如有同名目录则本地重命名为 .bak（已存在则先删）

set -e

echo "开始还原配置文件到 ~/.config/ ..."

cd "$(dirname "$0")"

CONFIG_DIRS=("kitty" "mpv" "neovide" "nvim")

for dir in "${CONFIG_DIRS[@]}"; do
    SRC="$dir"
    DEST="$HOME/.config/$dir"
    BAK="$DEST.bak"

    echo "处理 $dir ..."

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
    echo "✓ $dir 还原完成"
done

echo "全部配置文件还原完成！"