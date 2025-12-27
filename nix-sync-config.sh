#!/usr/bin/env fish

# 1. 自动定位到仓库根目录
set REPO_DIR (git rev-parse --show-toplevel 2>/dev/null)
if test -z "$REPO_DIR"
    echo (set_color red)"错误: 未能在当前或上级目录找到 Git 仓库"(set_color normal)
    exit 1
end

cd $REPO_DIR
echo (set_color green)"开始同步 dotfiles 流程 (先同步 Git，再应用配置)..."(set_color normal)

# 2. 清理可能的嵌入 git 仓库
echo (set_color cyan)"清理嵌套的 .git 目录..."(set_color normal)
find . -name ".git" -type d -not -path "./.git" -exec rm -rf {} + 2>/dev/null

# 拉取最新配置
git pull

# 3. 检查并处理 Git 变更
if not git diff --quiet; or not git diff --staged --quiet; or test -n (git ls-files --others --exclude-standard)
    echo (set_color yellow)"检测到本地变更，正在准备 Git 提交..."(set_color normal)
    
    git add .
    
    set timestamp (date '+%Y-%m-%d %H:%M:%S')
    set commit_msg "更新配置文件 - $timestamp\n\n自动同步 Nix 环境下的变更"
    
    git commit -m "$commit_msg"
    echo (set_color green)"✓ 本地提交成功"(set_color normal)
    
    read -l -P "是否推送到 GitHub? (Y/n) " confirm
    if test -z "$confirm"; or string match -qi "y" "$confirm"
        echo (set_color cyan)"正在推送到远程仓库..."(set_color normal)
        if git push
            echo (set_color green)"✓ 远程推送成功"(set_color normal)
        else
            echo (set_color red)"✕ 推送失败，请检查网络或冲突"(set_color normal)
        end
    end
else
    echo (set_color blue)"Git 状态干净，无需提交。"(set_color normal)
end

# 4. 自动识别系统并应用配置
set -l os_type (uname)

if test "$os_type" = "Darwin"
    # --- macOS 逻辑 ---
    set -l REBUILD_CMD (command -v darwin-rebuild; or echo "/run/current-system/sw/bin/darwin-rebuild")
    echo (set_color cyan)"检测到 macOS，正在应用 nix-darwin 配置..."(set_color normal)
    
    if sudo -E $REBUILD_CMD switch --flake .
        echo (set_color green)"✨ macOS 配置已同步完成！"(set_color normal)
    else
        echo (set_color red)"✕ 配置应用失败"(set_color normal); exit 1
    end

else if test -f /etc/NIXOS
    # --- NixOS 逻辑 ---
    echo (set_color cyan)"检测到 NixOS，正在应用 nixos-rebuild 配置..."(set_color normal)
    
    # 注意：NixOS 上我们习惯加上 --impure 来读取 OrbStack 的配置
    if sudo nixos-rebuild switch --flake .#nixos --impure
        echo (set_color green)"✨ NixOS 配置已同步完成！"(set_color normal)
    else
        echo (set_color red)"✕ 配置应用失败"(set_color normal); exit 1
    end

else
    echo (set_color red)"错误: 未能识别的系统类型 (非 macOS 且非 NixOS)"(set_color normal)
    exit 1
end
