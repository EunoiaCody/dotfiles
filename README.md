# Dotfiles

我的个人配置文件备份仓库

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

克隆此仓库并将配置文件复制到相应的配置目录：

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

最后更新：2025年10月2日

---

💡 **提示**: 在应用这些配置之前，请备份你现有的配置文件。
