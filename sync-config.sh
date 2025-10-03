#!/bin/bash

# 同步配置文件脚本
# 这个脚本会将 ~/.config/ 中的配置文件更新到 dotfiles 仓库

set -e

echo "开始同步配置文件到 dotfiles 仓库..."

# 进入 dotfiles 目录
cd "$(dirname "$0")"

# 配置文件夹列表
CONFIG_DIRS=("kitty" "mpv" "neovide" "nvim")

# 同步每个配置文件夹
for dir in "${CONFIG_DIRS[@]}"; do
    echo "同步 $dir..."
    
    # 删除旧的文件夹（如果存在）
    if [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
    
    # 复制新的配置文件
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir" .
        echo "✓ $dir 同步完成"
    else
        echo "⚠ 警告: ~/.config/$dir 不存在，跳过同步"
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

自动同步 ~/.config/ 中的配置文件到 dotfiles 仓库"
    
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
