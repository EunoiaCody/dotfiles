# Dotfiles

我的个人配置文件仓库，包含各种应用程序的配置文件。

## 包含的配置

- **kitty** - 终端模拟器配置
- **mpv** - 媒体播放器配置（包含 uosc 界面和 Anime4K 着色器）
- **neovide** - Neovim GUI 配置
- **nvim** - Neovim 编辑器配置

## 目录结构

```
dotfiles/
├── kitty/          # Kitty 终端配置
├── mpv/            # MPV 播放器配置
├── neovide/        # Neovide GUI 配置
├── nvim/           # Neovim 编辑器配置
├── sync-config.sh  # 配置同步脚本
└── README.md       # 说明文档
```

## 使用方法

### 方式一：直接复制（推荐）

将配置文件复制到对应的配置目录：

```bash
# 克隆仓库
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 复制配置文件到 ~/.config/
cp -r kitty ~/.config/
cp -r mpv ~/.config/
cp -r neovide ~/.config/
cp -r nvim ~/.config/
```

### 方式二：创建符号链接（本地同步）

如果你想要本地配置文件与仓库保持实时同步：

```bash
# 克隆仓库到合适的位置
git clone https://github.com/EunoiaCody/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 备份现有配置（可选）
mkdir -p ~/.config/backup
mv ~/.config/kitty ~/.config/backup/ 2>/dev/null || true
mv ~/.config/mpv ~/.config/backup/ 2>/dev/null || true
mv ~/.config/neovide ~/.config/backup/ 2>/dev/null || true
mv ~/.config/nvim ~/.config/backup/ 2>/dev/null || true

# 创建符号链接
ln -sf ~/dotfiles/kitty ~/.config/kitty
ln -sf ~/dotfiles/mpv ~/.config/mpv
ln -sf ~/dotfiles/neovide ~/.config/neovide
ln -sf ~/dotfiles/nvim ~/.config/nvim
```

## 同步配置文件

本仓库提供了一个自动同步脚本 `sync-config.sh`，用于将本地配置文件的更改同步到 Git 仓库。

### 使用同步脚本

```bash
cd ~/dotfiles
./sync-config.sh
```

脚本会：

1. 将 `~/.config/` 中的配置文件复制到仓库
2. 检测文件变更并自动提交
3. 询问是否推送到 GitHub

### 自动化同步（可选）

你可以设置定期任务来自动同步配置：

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天晚上 11 点同步）
0 23 * * * cd ~/dotfiles && ./sync-config.sh >/dev/null 2>&1
```

## 配置说明

### Kitty 终端

- 包含主题配置和快捷键设置
- 支持字体渲染优化
- 包含窗口管理配置

### MPV 播放器

- 集成 uosc 现代化界面
- 包含弹幕支持 (uosc_danmaku)
- 配置 Anime4K 画质增强着色器
- 自定义快捷键和播放设置

### Neovide GUI

- Neovim 的 GUI 前端配置
- 包含字体和界面设置

### Neovim 编辑器

- 基于 Lazy.nvim 的插件管理
- LSP 支持和代码补全
- 包含各种开发工具和主题
- 支持多种编程语言

## 版本控制说明

**重要**: 这个仓库包含配置文件的实际内容，而不是符号链接。这样做的好处是：

1. ✅ GitHub 上可以直接查看配置文件内容
2. ✅ 支持在线编辑和版本对比
3. ✅ 方便在不同设备间同步配置
4. ❌ 需要手动或通过脚本来同步本地更改

如果你需要本地配置与仓库实时同步，请使用符号链接方式，但需要注意 GitHub 上只会显示链接路径。

## 贡献

如果你发现任何问题或有改进建议，欢迎提交 issue 或 pull request。

## 许可证

这些配置文件按 MIT 许可证分发，你可以自由使用、修改和分发。
