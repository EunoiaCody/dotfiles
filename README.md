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

### 窗口管理与桌面

- **niri** - Wayland 合成器（平铺式窗口管理）
- **quickshell** - 现代化桌面面板/状态栏
- **rofi** - 应用启动器和窗口切换器
- **aerospace** - macOS 平铺窗口管理器配置
- **sketchybar** - macOS 状态栏配置

### 终端与 Shell

- **kitty** - 终端模拟器配置
- **fish** - Fish shell 配置
- **yazi** - 终端文件管理器

### 编辑器与开发

- **neovide** - Neovim GUI 配置
- **nvim** - Neovim 编辑器配置
- **vscode** - VSCode 编辑器配置

### 多媒体

- **mpv** - 媒体播放器配置（包含 uosc 界面和 Anime4K 着色器）

### 工具配置

- **bat** - Catppuccin 主题（Mocha, Macchiato, Frappe, Latte）
- **figlet** - ASCII 艺术字体

## 目录结构

```tree
dotfiles/
├── niri/                  # Niri Wayland 合成器配置
├── quickshell/            # QuickShell 面板配置
├── rofi/                  # Rofi 启动器配置
├── kitty/                 # Kitty 终端配置
├── fish/                  # Fish shell 配置
├── yazi/                  # Yazi 文件管理器配置
├── nvim/                  # Neovim 编辑器配置
├── neovide/               # Neovide GUI 配置
├── vscode/                # VSCode 编辑器配置
├── mpv/                   # MPV 播放器配置
├── bat/                   # Bat 主题配置
├── figlet/                # Figlet 字体配置
├── aerospace/             # AeroSpace 窗口管理器配置（macOS）
├── sketchybar/             # SketchyBar 状态栏配置（macOS）
├── bootstrap.sh           # 引导安装脚本
├── install.py             # Python 安装脚本
├── restore-config.sh      # Linux/macOS 配置还原脚本
├── restore-config.ps1     # Windows 配置还原脚本
├── sync-config.sh         # Linux/macOS 配置同步脚本
└── README.md              # 说明文档
```

## 快速开始

### 使用引导脚本（推荐）

```bash
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles
./bootstrap.sh
```

或者使用 Python 安装脚本：

```bash
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles
python3 install.py
```

### 手动安装

```bash
# 克隆仓库
git clone https://github.com/EunoiaCody/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 复制配置到 ~/.config/
cp -r niri quickshell rofi kitty fish yazi nvim neovide mpv bat ~/.config/
cp -r vscode ~/.config/

# 手动复制 Aerospace 配置（仅 macOS）
cp aerospace/aerospace.toml ~/.aerospace.toml
```

## 依赖安装

### 主要软件

| 软件 | Ubuntu/Debian | Fedora/RHEL | Arch Linux | macOS |
|------|---------------|-------------|------------|-------|
| **Niri** | [编译安装](https://github.com/YaLTeR/niri) | [编译安装](https://github.com/YaLTeR/niri) | `pacman -S niri` | N/A |
| **QuickShell** | [编译安装](https://github.com/quick-shell/QuickShell) | [编译安装](https://github.com/quick-shell/QuickShell) | `pacman -S quickshell` | N/A |
| **Rofi** | `apt install rofi` | `dnf install rofi` | `pacman -S rofi` | `brew install rofi` |
| **Kitty** | `apt install kitty` | `dnf install kitty` | `pacman -S kitty` | `brew install kitty` |
| **Fish** | `apt install fish` | `dnf install fish` | `pacman -S fish` | `brew install fish` |
| **Yazi** | `cargo install --locked yazi` | `cargo install --locked yazi` | `pacman -S yazi` | `brew install yazi` |
| **Neovim** | `apt install neovim`* | `dnf install neovim` | `pacman -S neovim` | `brew install neovim` |
| **Neovide** | [下载](https://github.com/neovide/neovide/releases) | `dnf install neovide` | `pacman -S neovide` | `brew install neovide` |
| **MPV** | `apt install mpv` | `dnf install mpv` | `pacman -S mpv` | `brew install mpv` |
| **VSCode** | [下载](https://code.visualstudio.com/) | [下载](https://code.visualstudio.com/) | `pacman -S code` | `brew install --cask visual-studio-code` |
| **Bat** | `apt install bat` | `dnf install bat` | `pacman -S bat` | `brew install bat` |
| **AeroSpace** | N/A | N/A | N/A | `brew install --cask nikitabobko/tap/aerospace` |
| **SketchyBar** | N/A | N/A | N/A | `brew install sketchybar` |

\* Ubuntu/Debian 推荐使用 PPA：`sudo add-apt-repository ppa:neovim-ppa/stable && sudo apt update`

### 必需依赖

| 依赖 | 用途 | Ubuntu/Debian | Fedora/RHEL | Arch Linux | macOS |
|------|------|---------------|-------------|------------|-------|
| **JetBrains Mono** | 终端字体 | `apt install fonts-jetbrains-mono` | `dnf install jetbrains-mono-fonts` | `pacman -S ttf-jetbrains-mono` | `brew install font-jetbrains-mono` |
| **Node.js** | LSP/插件 | `apt install nodejs` | `dnf install nodejs` | `pacman -S nodejs` | `brew install node` |
| **Python 3** | 插件/脚本 | `apt install python3` | `dnf install python3` | `pacman -S python` | `brew install python` |
| **Git** | 版本控制 | `apt install git` | `dnf install git` | `pacman -S git` | `brew install git` |
| **Ripgrep** | 文件搜索 | `apt install ripgrep` | `dnf install ripgrep` | `pacman -S ripgrep` | `brew install ripgrep` |
| **Cargo/Rust** | Yazi 编译 | `apt install cargo` | `dnf install cargo` | `pacman -S rust` | `brew install rust` |
| **FFmpeg** | MPV 支持 | `apt install ffmpeg` | `dnf install ffmpeg` | `pacman -S ffmpeg` | `brew install ffmpeg` |
| **wlroots** | Niri 依赖 | N/A | N/A | `pacman -S wlroots` | N/A |
| **polkit** | 权限认证 | `apt install polkit-gnome` | `dnf install polkit-gnome` | `pacman -S polkit` | N/A |

### Niri 额外依赖（Linux）

```bash
# Arch Linux
pacman -S wlr-output-management Ibus

# Ubuntu/Debian
apt install wlr-output-management ibus

# 或者直接安装 sway 相关的包
apt install sway swaybg swaylock swayidle
```

### QuickShell 额外依赖

```bash
# 运行时依赖
apt install libqt5quick5 libqt5svg5 libqt5waylandclient
# 或者安装完整 Qt 环境
apt install qtbase5-dev qtwayland5
```

## 配置说明

### Niri Wayland 合成器

- 平铺式窗口管理
- 启动随机壁纸（awww）
- 自动启动应用（Emby 播放脚本、微信、Fluffychat）
- 窗口规则配置
- 快捷键绑定

### QuickShell 面板

- 系统监控（CPU、内存、网络）
- 音量控制
- 蓝牙管理
- 通知区域
- 歌词显示（lyrics_fetcher）
- 工作区切换
- 电源菜单

### Rofi 启动器

- 动态壁纸背景
- 自定义主题和颜色
- 应用启动和窗口切换

### Yazi 文件管理器

- 快速文件浏览
- 预览支持
- 智能过滤插件
- 自定义快捷键

### Neovim 编辑器

- Lazy.nvim 插件管理
- LSP 支持和代码补全
- Snacks  dashboard
- Toggle-term 终端集成
- Tree-sitter 语法高亮
- Catppuccin 主题

### Fish Shell

- Catppuccin 主题
- 自定义函数和别名
- 自动补全
- Fisher 插件管理

### MPV 播放器

- uosc 现代化界面
- uosc_danmaku 弹幕支持
- Anime4K 画质增强着色器
- 自定义快捷键

## 同步配置文件

### Linux / macOS

```bash
cd ~/dotfiles
./sync-config.sh
```

脚本功能：
1. 将 `~/.config/` 中的配置文件同步到仓库
2. 检测文件变更并自动提交
3. 询问是否推送到 GitHub

### Windows

```powershell
cd dotfiles
.\sync-config.ps1
```

## 版本控制说明

这个仓库包含配置文件的实际内容，而不是符号链接。这样做的好处是：

1. ✅ GitHub 上可以直接查看配置文件内容
2. ✅ 支持在线编辑和版本对比
3. ✅ 方便在不同设备间同步配置
4. ❌ 需要手动或通过脚本来同步本地更改

## 许可证

这些配置文件按 MIT 许可证分发，你可以自由使用、修改和分发。
