#!/usr/bin/env fish

# 自动定位到脚本所在目录（即仓库根目录）
set REPO_DIR (git rev-parse --show-toplevel 2>/dev/null)
if test -z "$REPO_DIR"
    echo (set_color red)"错误: 未能在当前或上级目录找到 Git 仓库"(set_color normal)
    exit 1
end

cd $REPO_DIR
echo (set_color green)"开始通过 Nix 应用配置并同步..."(set_color normal)

# 1. 应用配置 (把仓库里的修改同步到系统)
if command -v home-manager >/dev/null
    echo (set_color cyan)"正在执行 home-manager switch..."(set_color normal)
    # 使用 --flake . 自动寻找当前目录的配置
    if home-manager switch --flake .
        echo (set_color green)"✓ 配置已应用到系统"(set_color normal)
    else
        echo (set_color red)"✕ 配置应用失败，请检查错误"(set_color normal)
        exit 1
    end
end

# 2. 清理可能的嵌入 git 仓库 (保留你原有的清理逻辑)
echo (set_color cyan)"清理嵌入的 .git 目录..."(set_color normal)
find . -name ".git" -type d -not -path "./.git" -exec rm -rf {} + 2>/dev/null

# 3. Git 操作
echo (set_color cyan)"检查变更状态..."(set_color normal)

# 检查是否有未暂存、已暂存或未跟踪的文件
if not git diff --quiet; or not git diff --staged --quiet; or test -n (git ls-files --others --exclude-standard)
    echo (set_color yellow)"检测到配置文件变更，准备提交..."(set_color normal)
    git add .
    
    # 生成提交信息
    set timestamp (date '+%Y-%m-%d %H:%M:%S')
    set commit_msg "更新配置文件 - $timestamp\n\n自动应用并同步 Nix 配置"
    
    git commit -m "$commit_msg"
    echo (set_color green)"✓ 提交完成！"(set_color normal)
    
    # 询问是否推送
    read -l -P "是否推送到 GitHub? (Y/n) " confirm
    if test -z "$confirm"; or string match -qi "y" "$confirm"
        echo (set_color cyan)"推送到远程仓库..."(set_color normal)
        git push
        echo (set_color green)"✓ 推送成功！"(set_color normal)
    else
        echo (set_color yellow)"跳过推送。"(set_color normal)
    end
else
    echo (set_color yellow)"没有任何变更需要同步。"(set_color normal)
end

echo (set_color green)"✨ 同步任务圆满完成！"(set_color normal)nd
