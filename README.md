# Dotfiles

我的个人配置文件备份仓库

## 🔗 符号链接结构

本仓库使用**符号链接（symlinks）**的方式来管理配置文件，这意味着：

- ✅ 当你修改 `~/.config/` 中的配置文件时，仓库中的文件会**自动同步更新**
- ✅ 无需手动复制文件，始终保持最新状态
- ✅ 便于版本控制和备份管理

## 包含的配置文件

### 📺 Kitty

终端模拟器配置文件

- `kitty/kitty.conf` - 主要配置文件
- `kitty/current-theme.conf` - 当前主题配置

### 🎮 Neovide

Neovim 图形界面客户端配置

- `neovide/config.toml` - Neovide 配置文件

### ⚡ Neovim

现代化的 Vim 编辑器配置

- `nvim/init.lua` - 主要配置文件
- `nvim/lua/` - Lua 配置模块
- `nvim/snippets/` - 代码片段
- `nvim/lazy-lock.json` - 插件锁定文件

### 🎬 MPV

多媒体播放器配置

- `mpv/mpv.conf` - 主要配置文件
- `mpv/input.conf` - 键盘快捷键配置
- `mpv/scripts/` - 脚本文件
- `mpv/shaders/` - 着色器文件
- `mpv/fonts/` - 字体文件

## 使用方法

### 方法 1：恢复配置（推荐）

如果你想要使用这些配置，直接克隆仓库并创建符号链接：

```bash
git clone https://github.com/EunoiaCody/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 备份现有配置（如果存在）
mv ~/.config/kitty ~/.config/kitty.bak 2>/dev/null || true
mv ~/.config/neovide ~/.config/neovide.bak 2>/dev/null || true
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
mv ~/.config/mpv ~/.config/mpv.bak 2>/dev/null || true

# 创建符号链接
ln -sf ~/dotfiles/kitty ~/.config/kitty
ln -sf ~/dotfiles/neovide ~/.config/neovide
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/mpv ~/.config/mpv
```

### 方法 2：传统复制方式

如果你只是想要复制配置文件：

```bash
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 复制到 ~/.config/ 目录
cp -r kitty ~/.config/
cp -r neovide ~/.config/
cp -r nvim ~/.config/
cp -r mpv ~/.config/
```

## 备份日期

最后更新：2025 年 10 月 2 日

---

💡 **提示**: 在应用这些配置之前，请备份你现有的配置文件。
