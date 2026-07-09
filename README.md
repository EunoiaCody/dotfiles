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

- **niri** - Wayland 合成器（平铺式窗口管理、模块化配置、IPC 集成）
- **quickshell** - 现代化桌面 Shell（状态栏、动态岛、锁屏、启动器、壁纸管理、侧边栏控制中心）
- **aerospace** - macOS 平铺窗口管理器配置
- **sketchybar** - macOS 状态栏配置

### 终端与 Shell

- **kitty** - 终端模拟器配置（Catppuccin Mocha 主题）
- **fish** - Fish shell 配置（Catppuccin 主题、自定义补全、Fisher 插件管理）
- **yazi** - 终端文件管理器（智能过滤插件、跨实例剪贴板同步）

### 编辑器与开发

- **neovide** - Neovim GUI 配置
- **nvim** - Neovim 编辑器配置（AI 辅助、LSP 补全、多光标、Git 集成）
- **vscode** - VSCode 光标样式配置

### 多媒体

- **mpv** - 媒体播放器配置（uosc 界面、弹幕支持、Anime4K 画质增强着色器、LXGW WenKai 字幕字体）

### 工具配置

- **bat** - Catppuccin 主题（Mocha, Macchiato, Frappe, Latte）
- **figlet** - ASCII 艺术字体

## 目录结构

```tree
dotfiles/
├── niri/                  # Niri Wayland 合成器配置
│   ├── config.kdl          #   主配置（启动项、环境变量）
│   ├── binds.kdl           #   快捷键绑定
│   ├── color.kdl           #   颜色规则
│   └── windows-rule.kdl    #   窗口规则
├── quickshell/            # QuickShell 桌面 Shell
│   ├── Modules/            #   功能模块（Bar、DynamicIsland、Lock、Launcher、Wallpaper 等）
│   ├── Services/           #   后端服务（蓝牙、网络、音量、壁纸、通知等）
│   ├── Widgets/            #   可复用 UI 组件
│   ├── Common/             #   共享工具（颜色、动画、尺寸常量）
│   ├── Components/         #   基础组件（图标等）
│   ├── scripts/            #   Python 辅助脚本（歌词、天气、日程）
│   ├── assets/             #   静态资源（着色器等）
│   └── start-quickshell.sh #   启动脚本
├── kitty/                 # Kitty 终端配置
├── fish/                  # Fish shell 配置
│   ├── conf.d/             #   模块化配置（主题、自动补全、键位绑定）
│   ├── completions/        #   自定义补全（bun、docker、kubectl 等）
│   ├── functions/          #   自定义函数和别名
│   └── themes/             #   Catppuccin 主题文件
├── yazi/                  # Yazi 文件管理器配置
│   └── plugins/            #   插件（smart-filter 等）
├── nvim/                  # Neovim 编辑器配置
│   └── lua/
│       ├── config/         #   核心配置（键位、LSP、Vue 等）
│       └── plugins/        #   插件配置（AI、补全、UI、格式化等）
├── neovide/               # Neovide GUI 配置
├── vscode/                # VSCode 光标样式配置
├── mpv/                   # MPV 播放器配置
│   ├── shaders/            #   Anime4K 着色器
│   ├── scripts/            #   uosc / uosc_danmaku 脚本
│   └── fonts/              #   界面字体
├── bat/                   # Bat 主题配置
├── figlet/                # Figlet 字体配置
├── aerospace/             # AeroSpace 窗口管理器配置（macOS）
├── sketchybar/             # SketchyBar 状态栏配置（macOS）
├── bootstrap.sh           # 引导安装脚本
├── install.py             # Python 安装脚本
├── restore-config.sh      # Linux/macOS 配置还原脚本
├── restore-config.ps1     # Windows 配置还原脚本
├── sync-config.sh         # Linux/macOS 配置同步脚本
├── sync-config.ps1        # Windows 配置同步脚本
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
cp -r niri quickshell kitty fish yazi nvim neovide mpv bat ~/.config/
cp -r vscode ~/.config/

# 手动复制 Aerospace 配置（仅 macOS）
cp aerospace/aerospace.toml ~/.aerospace.toml
```

### 在新设备上还原配置

如果你已经在 GitHub 上同步了配置文件，可以在新设备上直接还原：

```bash
# Linux / macOS
git clone https://github.com/EunoiaCody/dotfiles.git ~/dotfiles
cd ~/dotfiles
./restore-config.sh

# Windows
git clone https://github.com/EunoiaCody/dotfiles.git dotfiles
cd dotfiles
.\restore-config.ps1
```

脚本会自动备份旧配置（`.bak` 后缀），然后从仓库复制最新配置到对应位置。

## 依赖安装

### 主要软件

| 软件 | Ubuntu/Debian | Fedora/RHEL | Arch Linux | macOS |
|------|---------------|-------------|------------|-------|
| **Niri** | [编译安装](https://github.com/YaLTeR/niri) | [编译安装](https://github.com/YaLTeR/niri) | `pacman -S niri` | N/A |
| **QuickShell** | [编译安装](https://github.com/quick-shell/QuickShell) | [编译安装](https://github.com/quick-shell/QuickShell) | `pacman -S quickshell` | N/A |
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

\* 需要 Neovim >= 0.12（使用 `vim.lsp.config()` API）。Ubuntu/Debian 推荐使用 PPA：`sudo add-apt-repository ppa:neovim-ppa/stable && sudo apt update`

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
| **wl-paste** | Fish 粘贴工具 | `apt install wl-clipboard` | `dnf install wl-clipboard` | `pacman -S wl-clipboard` | N/A |
| **Bun** | JavaScript 运行时 | [安装脚本](https://bun.sh) | [安装脚本](https://bun.sh) | `pacman -S bun` | `brew install bun` |
| **awww** | Wayland 壁纸服务 | [编译安装](https://github.com/awww-dev/awww) | [编译安装](https://github.com/awww-dev/awww) | `pacman -S awww` | N/A |

### Niri 额外依赖（Linux）

```bash
# Arch Linux
pacman -S wlr-output-management Ibus

# Ubuntu/Debian
apt install wlr-output-management ibus

# 或者直接安装 sway 相关的包
apt install sway swaybg swaylock swayidle
```

### QuickShell 额外依赖（Linux）

QuickShell 配置依赖自定义 **Clavis C++ 插件**（系统监控、Niri IPC、天气、媒体信息、键盘状态等），需安装到 `~/.local/share/qt6/qml/Clavis/` 目录。

```bash
# Python 辅助脚本依赖
pip install requests mutagen

# Clavis 插件编译（需要 Qt6 开发环境）
apt install qt6-base-dev qt6-declarative-dev cmake g++
# 或安装完整 Qt 环境
apt install qt6-base-dev qt6-wayland
```

## 配置说明

### Niri Wayland 合成器

- 模块化配置（`config.kdl` / `binds.kdl` / `color.kdl` / `windows-rule.kdl`）
- 平铺式窗口管理，Catppuccin 主题色彩
- 通过 IPC 与 QuickShell 集成（锁屏、启动器、壁纸切换、动态岛）
- 自动启动 QuickShell、Emby 播放脚本、微信、Telegram 等应用
- 窗口规则配置（圆角、透明度、层级）

### QuickShell 桌面 Shell

采用模块化架构，由 20+ 个后端服务和多个功能模块组成：

**核心模块：**
- **Bar** - 顶部状态栏：工作区切换、活动窗口、系统监控（CPU/内存/网络）、系统托盘、快捷设置、电源按钮
- **DynamicIsland** - macOS 风格动态岛：时钟、通知、媒体控制、歌词显示、天气（支持位置配置）、音量、壁纸预览、工具面板（取色器/截图/录屏）
- **Lock** - 锁屏界面，支持 PAM 认证，含天气、媒体、通知、系统信息等卡片
- **Launcher** - 应用启动器（替代 Rofi 部分功能），支持应用/窗口/壁纸页面
- **Right Sidebar** - 右侧控制中心：音频、网络、蓝牙、通知、快捷设置、电源管理
- **Wallpaper** - 壁纸系统，含 7 种 GLSL 着色器过渡效果（fade/wipe/disc/stripes 等）

**后端服务：**
BluetoothService、Network、Volume、Brightness、NotificationManager、MediaManager、WallpaperService、TrayService、ThemeService、Wlsunset 等

**Python 辅助脚本：**
- `lyrics_fetcher.py` - 歌词获取
- `weather.py` - 天气数据
- `parse_schedule.py` - 日程解析
- `overview.sh` - 系统概览

### Yazi 文件管理器

- 多标签文件浏览和预览
- smart-filter 智能过滤插件
- 跨实例剪贴板同步
- 自定义主题和快捷键（378 行 keymap）

### Neovim 编辑器

- **插件管理**：Lazy.nvim 插件管理，按需加载
- **AI 辅助**：CodeCompanion + Avante（OpenCode Go 后端），GitHub Copilot
- **智能补全**：blink.cmp 高性能补全引擎
- **LSP 支持**：Mason 管理 LSP，支持 Rust/Python/Lua/C++/TS/Vue 等
- **代码格式化**：conform.nvim 自动格式化（Stylua/Black/Rustfmt/Prettier）
- **界面增强**：Snacks dashboard、noice.nvim、markview 预览、smear-cursor 动画
- **编辑增强**：flash.nvim 跳转、multicursor 多光标、leap 移动
- **Git 集成**：lazygit.nvim、gitsigns
- **其他**：leetcode.nvim、code-runner、toggle-term 终端

### Fish Shell

- Catppuccin 主题（Mocha/Macchiato/Frappe）
- 模块化配置（`conf.d/` 下的主题、自动补全、键位绑定）
- 自定义函数：`fish_prompt`（发行版感知）、`yz`（Yazi 集成）、`gateway`（macOS NAT）等
- 丰富的补全支持（bun、docker、kubectl、orbctl、txget 等）
- Fisher 插件管理（autopair、catppuccin、bass）

### MPV 播放器

- uosc 现代化界面 + uosc_danmaku 弹幕支持
- Anime4K Mode A 着色器管线（Clamp → Restore → Upscale x2 → Upscale x2 S）
- LXGW WenKai 字幕字体，日语弹幕模式支持
- 硬件解码（auto），音频直通（ac3/eac3/dts-hd/truehd）
- yt-dlp 集成，Chrome cookies 支持

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
