#!/usr/bin/env fish

set DOTFILES_DIR "$HOME/dotfiles"

# 在 Nix 模式下，我们不需要从 .config 复制回仓库
# 我们直接在仓库目录操作
cd $DOTFILES_DIR

# 检查更改
if git status --porcelain | string collect
    git add .
    git commit -m "Update configs: (date)"
    git push
else
    echo "没有检测到变更"
end
