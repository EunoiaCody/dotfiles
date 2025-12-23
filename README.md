# Dotfiles

我的个人配置文件仓库，包含各种应用程序的配置文件。

```
███████╗██╗   ██╗███╗   ██╗ ██████╗ ██╗ █████╗     ███████╗
██╔════╝██║   ██║████╗  ██║██╔═══██╗██║██╔══██╗    ██╔════╝
█████╗  ██║   ██║██╔██╗ ██║██║   ██║██║███████║    ███████╗
██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██║██╔══██║    ╚════██║
███████╗╚██████╔╝██║ ╚████║╚██████╔╝██║██║  ██║    ███████║
╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═╝    ╚══════╝
                                                           
██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```

## 包含的配置

- **kitty** - 终端模拟器配置
- **mpv** - 媒体播放器配置（包含 uosc 界面和 Anime4K 着色器）
- **neovide** - Neovim GUI 配置
- **nvim** - Neovim 编辑器配置
- **fish** - Fish shell 配置
- **aerospace** - macOS 平铺窗口管理器配置
- **sketchybar** - macOS 状态栏配置

## 目录结构

```tree
dotfiles/
├── kitty/              # Kitty 终端配置
├── mpv/                # MPV 播放器配置
├── neovide/            # Neovide GUI 配置
├── nvim/               # Neovim 编辑器配置
├── fish/               # Fish shell 配置
├── aerospace/          # AeroSpace 窗口管理器配置
├── sketchybar/         # SketchyBar 状态栏配置
├── restore-config.sh   # Linux/macOS 配置还原脚本
├── restore-config.ps1  # Windows 配置还原脚本
├── sync-config.sh      # Linux/macOS 配置同步脚本
├── sync-config.ps1     # Windows 配置同步脚本
└── README.md           # 说明文档
```

## 依赖安装

### 主要软件

| 软件 | Ubuntu/Debian | Fedora/RHEL | Arch Linux | macOS | Windows |
|------|---------------|-------------|------------|-------|---------|
| **Kitty** | `apt install kitty` | `dnf install kitty` | `pacman -S kitty` | `brew install kitty` | N/A |
| **MPV** | `apt install mpv` | `dnf install mpv` | `pacman -S mpv` | `brew install mpv` | [下载](https://mpv.io/installation/) |
| **Neovim** | `apt install neovim`* | `dnf install neovim` | `pacman -S neovim` | `brew install neovim` | `choco install neovim` 或 [下载](https://github.com/neovim/neovim/releases) |
| **Neovide** | [下载 deb](https://github.com/neovide/neovide/releases) | `dnf install neovide` | `pacman -S neovide` | `brew install neovide` | [下载](https://github.com/neovide/neovide/releases) |
| **Fish** | `apt install fish` | `dnf install fish` | `pacman -S fish` | `brew install fish` | N/A |
| **AeroSpace** | N/A | N/A | N/A | `brew install --cask nikitabobko/tap/aerospace` | N/A |
| **SketchyBar** | N/A | N/A | N/A | `brew tap FelixKratz/formulae && brew install sketchybar` | N/A |

\* Ubuntu/Debian 推荐使用 PPA：`sudo add-apt-repository ppa:neovim-ppa/stable && sudo apt update`

### 必需依赖

| 依赖 | 用途 | Ubuntu/Debian | Fedora/RHEL | Arch Linux | macOS | Windows |
|------|------|---------------|-------------|------------|-------|---------|
| **JetBrains Mono** | Kitty 字体 | `apt install fonts-jetbrains-mono` | `dnf install jetbrains-mono-fonts` | `pacman -S ttf-jetbrains-mono` | `brew install font-jetbrains-mono` | [下载](https://www.jetbrains.com/lp/mono/) |
| **Node.js** | Neovim LSP | `apt install nodejs` | `dnf install nodejs npm` | `pacman -S nodejs npm` | `brew install node` | [下载](https://nodejs.org) |
| **Python 3** | Neovim 插件 | `apt install python3 python3-pip` | `dnf install python3 python3-pip` | `pacman -S python python-pip` | `brew install python` | [下载](https://python.org) |
| **Git** | 插件管理 | `apt install git` | `dnf install git` | `pacman -S git` | `brew install git` | [下载](https://git-scm.com) |
| **Ripgrep** | 文件搜索 | `apt install ripgrep` | `dnf install ripgrep` | `pacman -S ripgrep` | `brew install ripgrep` | `choco install ripgrep` |
| **构建工具** | 插件编译 | `apt install build-essential cmake` | `dnf groupinstall "Development Tools" && dnf install cmake` | `pacman -S base-devel cmake` | `xcode-select --install && brew install cmake` | Visual Studio Build Tools |
| **FFmpeg** | MPV 格式支持（可选） | `apt install ffmpeg` | `dnf install ffmpeg` | `pacman -S ffmpeg` | `brew install ffmpeg` | [下载](https://ffmpeg.org) |

### 安装后设置

1. 重启终端以应用路径更新
2. 首次启动 Neovim 会自动安装插件：`nvim`（需几分钟）
3. 验证安装：`node --version && python3 --version && git --version`

## 使用方法

### Linux / macOS

#### 使用还原脚本（推荐）

```bash
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles
./restore-config.sh
```

脚本会将配置文件复制到 `~/.config/`（fish 配置到 `~/.config/fish/`，aerospace 配置到 `~/.aerospace.toml`）。

#### 手动安装

```bash
# 克隆仓库
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 复制配置
cp -r kitty mpv neovide nvim ~/.config/
cp -r fish ~/.config/fish/
cp aerospace/aerospace.toml ~/.aerospace.toml
cp -r sketchybar ~/.config/
```

#### 使用符号链接（实时同步）

```bash
git clone https://github.com/EunoiaCody/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 备份现有配置（可选）
mkdir -p ~/.config/backup
for dir in kitty mpv neovide nvim sketchybar; do
    [ -d ~/.config/$dir ] && mv ~/.config/$dir ~/.config/backup/
done

# 创建符号链接
for dir in kitty mpv neovide nvim sketchybar; do
    ln -sf ~/dotfiles/$dir ~/.config/$dir
done
ln -sf ~/dotfiles/fish ~/.config/fish
ln -sf ~/dotfiles/aerospace/aerospace.toml ~/.aerospace.toml
```

### Windows 10 / 11

#### 使用还原脚本（推荐）

```powershell
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 如遇执行策略错误，先运行：
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

.\restore-config.ps1
```

脚本功能：
- 将配置复制到 `%LOCALAPPDATA%`
- 自动备份现有配置（添加 `.bak` 后缀）
- 清理旧备份

#### 手动安装

```powershell
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 复制配置文件
Copy-Item -Path kitty,mpv,neovide,nvim,fish -Destination $env:LOCALAPPDATA -Recurse
```

**注意**：Windows 不支持 aerospace 和 sketchybar（仅限 macOS）。

## 同步配置文件

本仓库提供了自动同步脚本，用于将本地配置文件的更改同步到 Git 仓库。

### Linux / macOS

```bash
cd ~/dotfiles
./sync-config.sh
```

脚本功能：
1. 将 `~/.config/` 中的配置文件复制到仓库
2. 检测文件变更并自动提交
3. 询问是否推送到 GitHub

**自动化同步**（可选）：使用 crontab 定期同步

```bash
crontab -e
# 添加：每天 23:00 自动同步
0 23 * * * cd ~/dotfiles && ./sync-config.sh >/dev/null 2>&1
```

### Windows 10 / 11

```powershell
# 如遇执行策略错误，先运行：
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

cd dotfiles
.\sync-config.ps1
```

脚本功能：
1. 将 `%LOCALAPPDATA%` 中的配置文件复制到仓库
2. 清理嵌入的 git 仓库
3. 检测文件变更并自动提交
4. 询问是否推送到 GitHub

**自动化同步**（可选）：创建 `sync-dotfiles.bat`

```batch
@echo off
cd /d "%USERPROFILE%\dotfiles"
powershell.exe -ExecutionPolicy Bypass -File ".\sync-config.ps1"
```

然后在任务计划程序中创建定时任务运行此文件。

## 配置说明

### Kitty 终端

- 主题配置和快捷键设置
- 字体渲染优化
- 窗口管理配置

### MPV 播放器

- uosc 现代化界面
- uosc_danmaku 弹幕支持
- Anime4K 画质增强着色器
- 自定义快捷键和播放设置

### Neovide 图形界面

- Neovim GUI 前端配置
- 字体和界面设置

### Neovim 编辑器

- Lazy.nvim 插件管理
- LSP 支持和代码补全
- 多种开发工具和主题
- 支持多种编程语言

### Fish Shell

- Shell 环境配置
- 自定义函数和别名

### AeroSpace 窗口管理器（仅 macOS）

- 平铺窗口管理配置
- 快捷键绑定
- 工作区管理

### SketchyBar 状态栏（仅 macOS）

- Catppuccin Mocha 主题配置
- 自定义插件和组件
- 状态栏布局设置

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
