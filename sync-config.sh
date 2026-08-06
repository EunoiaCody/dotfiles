#!/bin/bash

# 同步配置文件脚本
# 这个脚本会将 ~/.config/ 和 ~/ 中的配置文件更新到 dotfiles 仓库
# ~/.config/<name> → config/<name>
# ~/<name>          → home/<name>   (name 以 . 开头，如 .pi)

set -e

echo "开始同步配置文件到 dotfiles 仓库..."

# 进入 dotfiles 目录
cd "$(dirname "$0")"

# ~/.config/ 下的配置目录
CONFIG_DIRS=("kitty" "mpv" "neovide" "nvim" "fish" "aerospace" "sketchybar" "yazi" "figlet" "bat" "niri" "quickshell" "vscode" "cava" "imv")

# ~/ 下的配置（以 . 开头的文件/目录）
HOME_DIRS=(".pi")

# ── 同步 ~/.config/ ──
for dir in "${CONFIG_DIRS[@]}"; do
    echo "同步 ~/.config/$dir ..."

    # 删除旧的目录（如果存在）
    if [ -d "config/$dir" ]; then
        rm -rf "config/$dir"
    fi

    # 复制新的配置文件
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir/." "config/$dir/"
        # 从 git 恢复 .gitignore（源目录可能没有）
        git checkout -- "config/$dir/.gitignore" 2>/dev/null || true
        echo "✓ config/$dir 同步完成"
    else
        echo "⚠ 警告: ~/.config/$dir 不存在，跳过同步"
    fi
done

# ── 同步 ~/ ──
for name in "${HOME_DIRS[@]}"; do
    echo "同步 ~/$name ..."

    if [ -e "home/$name" ] || [ -d "home/$name" ]; then
        rm -rf "home/$name"
    fi

    if [ -e "$HOME/$name" ]; then
        cp -r "$HOME/$name/." "home/$name/"
        # 从 git 恢复 .gitignore（源目录可能没有）
        git checkout -- "home/$name/.gitignore" 2>/dev/null || true
        echo "✓ home/$name 同步完成"
    else
        echo "⚠ 警告: ~/$name 不存在，跳过同步"
    fi
done

# 清理可能的嵌入 git 仓库
echo "清理嵌入的 git 仓库..."
find . -name ".git" -type d -not -path "./.git" -exec rm -rf {} + 2>/dev/null || true

# Git 操作
echo "检查 Git 状态..."
if git diff --quiet && git diff --staged --quiet; then
    echo "没有检测到配置文件变更"
else
    echo "检测到配置文件变更，正在提交..."
    git add .

    # 生成提交信息
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "更新配置文件 - $TIMESTAMP

自动同步 ~/.config/ 和 ~/ 中的配置文件到 dotfiles 仓库"

    echo "提交完成！"

    # 询问是否推送到远程仓库
    read -p "是否推送到 GitHub? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "跳过推送，你可以稍后手动运行 'git push'"
    else
        echo "推送到远程仓库..."
        git push
        echo "✓ 推送完成！"
    fi
fi

echo "配置文件同步完成！"
