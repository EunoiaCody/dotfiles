#!/usr/bin/env fish

# 1. 自动定位到仓库根目录
set REPO_DIR (git rev-parse --show-toplevel 2>/dev/null)
if test -z "$REPO_DIR"
    echo (set_color red)"错误: 未能在当前或上级目录找到 Git 仓库"(set_color normal)
    exit 1
end

cd $REPO_DIR
echo (set_color green)"开始同步 dotfiles 流程 (先同步 Git，再应用配置)..."(set_color normal)

# 2. 清理可能的嵌入 git 仓库 (防止 Git 提交报错)
echo (set_color cyan)"清理嵌套的 .git 目录..."(set_color normal)
find . -name ".git" -type d -not -path "./.git" -exec rm -rf {} + 2>/dev/null

# 3. 检查并处理 Git 变更
# 检查是否有未暂存、已暂存或未跟踪的文件
if not git diff --quiet; or not git diff --staged --quiet; or test -n (git ls-files --others --exclude-standard)
    echo (set_color yellow)"检测到本地变更，正在准备 Git 提交..."(set_color normal)
    
    git add .
    
    # 获取当前日期和时间
    set timestamp (date '+%Y-%m-%d %H:%M:%S')
    set commit_msg "更新配置文件 - $timestamp\n\n自动同步 Nix 环境下的变更"
    
    git commit -m "$commit_msg"
    echo (set_color green)"✓ 本地提交成功"(set_color normal)
    
    # 推送到远程 (先确保 Git tree 是干净的，Nix 运行才不会有警告)
    read -l -P "是否推送到 GitHub? (Y/n) " confirm
    if test -z "$confirm"; or string match -qi "y" "$confirm"
        echo (set_color cyan)"正在推送到远程仓库..."(set_color normal)
        if git push
            echo (set_color green)"✓ 远程推送成功"(set_color normal)
        else
            echo (set_color red)"✕ 推送失败，请检查网络或冲突"(set_color normal)
            # 推送失败通常不影响本地 switch，所以继续执行
        end
    else
        echo (set_color yellow)"已跳过推送。"(set_color normal)
    end
else
    echo (set_color blue)"Git 状态干净，无需提交。"(set_color normal)
end
# 4. 最后应用配置 (使用 darwin-rebuild 统一管理系统和用户配置)
# 尝试定位 darwin-rebuild 命令（考虑到 PATH 可能还没完全刷新）
set -l DARWIN_REBUILD (command -v darwin-rebuild; or echo "/run/current-system/sw/bin/darwin-rebuild")

if test -x "$DARWIN_REBUILD"
    echo (set_color cyan)"正在应用最新的 nix-darwin 配置 (已注入代理 20122)..."(set_color normal)
    
    # 注入代理环境变量，确保 sudo 后的进程能联网
    # 同时手动指定清华镜像源，防止 nix.custom.conf 没生效
    if sudo -E $DARWIN_REBUILD switch --flake . 
            
        echo (set_color green)"✨ 系统与用户配置已同步完成！"(set_color normal)
    else
        echo (set_color red)"✕ 配置应用失败，请检查网络或 flake 代码"(set_color normal)
        exit 1
    end
else
    echo (set_color red)"错误: 未找到 darwin-rebuild 命令，请确认 nix-darwin 是否安装成功"(set_color normal)
    exit 1
end
