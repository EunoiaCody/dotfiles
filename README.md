# Dotfiles

我的个人配置文件仓库，包含各种应用程序的配置文件。

## 包含的配置

- **kitty** - 终端模拟器配置
- **mpv** - 媒体播放器配置（包含 uosc 界面和 Anime4K 着色器）
- **neovide** - Neovim GUI 配置
- **nvim** - Neovim 编辑器配置
- **fish**

## 目录结构

```tree
dotfiles/
├── kitty/              # Kitty 终端配置
├── mpv/                # MPV 播放器配置
├── neovide/            # Neovide GUI 配置
├── nvim/               # Neovim 编辑器配置
├── fish/               # Fish shell 配置
├── restore-config.sh   # Linux/macOS 配置还原脚本
├── restore-config.ps1  # Windows 配置还原脚本
├── sync-config.sh      # Linux/macOS 配置同步脚本
├── sync-config.ps1     # Windows 配置同步脚本
└── README.md           # 说明文档
```

## 依赖安装

在使用这些配置文件之前，您需要安装相应的软件及其依赖。

### 基础软件安装

首先安装四个主要软件：

#### Kitty 终端模拟器

```bash
# Ubuntu/Debian
sudo apt install kitty

# Fedora/RHEL
sudo dnf install kitty

# Arch Linux
sudo pacman -S kitty

# macOS
brew install kitty

# Windows
# 从 https://sw.kovidgoyal.net/kitty/binary/ 下载安装包
```

#### MPV 媒体播放器

```bash
# Ubuntu/Debian
sudo apt install mpv

# Fedora/RHEL
sudo dnf install mpv

# Arch Linux
sudo pacman -S mpv

# macOS
brew install mpv

# Windows
# 从 https://mpv.io/installation/ 下载安装包
```

#### Neovim 编辑器

```bash
# Ubuntu/Debian (推荐使用 PPA 获取最新版本)
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt update
sudo apt install neovim

# Fedora/RHEL
sudo dnf install neovim

# Arch Linux
sudo pacman -S neovim

# macOS
brew install neovim

# Windows
# 使用 Chocolatey: choco install neovim
# 或从 https://github.com/neovim/neovim/releases 下载
```

#### Neovide GUI

```bash
# Ubuntu/Debian
# 从 GitHub releases 下载 deb 包
wget https://github.com/neovide/neovide/releases/latest/download/neovide.deb
sudo dpkg -i neovide.deb

# Fedora/RHEL
sudo dnf install neovide

# Arch Linux
sudo pacman -S neovide

# macOS
brew install neovide

# Windows
# 从 https://github.com/neovide/neovide/releases 下载安装包
```

#### Fish SHell

```bash
# Ubuntu/Debian
sudo apt install fish

# Fedora/RHEL
sudo dnf install fish

# Arch Linux
sudo pacman -S fish

# macOS
brew install fish

# Windows
# 使用 Chocolatey: choco install fish
```

### 必需的依赖项

#### Kitty 依赖

**JetBrains Mono 字体**：配置中指定的默认字体

```bash
# Ubuntu/Debian
sudo apt install fonts-jetbrains-mono

# Fedora/RHEL
sudo dnf install jetbrains-mono-fonts

# Arch Linux
sudo pacman -S ttf-jetbrains-mono

# macOS
brew install font-jetbrains-mono

# 手动安装（所有系统）
# 1. 访问 https://www.jetbrains.com/lp/mono/
# 2. 下载字体文件
# 3. 安装到系统字体目录
```

#### Neovim 插件依赖

**Node.js**：LSP 服务器和某些插件需要

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Fedora/RHEL
sudo dnf install nodejs npm

# Arch Linux
sudo pacman -S nodejs npm

# macOS
brew install node

# Windows
# 从 https://nodejs.org 下载安装包
```

**Python 3**：Python LSP 和插件支持

```bash
# Ubuntu/Debian
sudo apt install python3 python3-pip

# Fedora/RHEL
sudo dnf install python3 python3-pip

# Arch Linux
sudo pacman -S python python-pip

# macOS
brew install python

# Windows
# 从 https://python.org 下载安装包
```

**构建工具**：编译某些插件需要

```bash
# Ubuntu/Debian
sudo apt install build-essential cmake gcc g++

# Fedora/RHEL
sudo dnf groupinstall "Development Tools"
sudo dnf install cmake gcc gcc-c++

# Arch Linux
sudo pacman -S base-devel cmake gcc

# macOS
xcode-select --install
brew install cmake

# Windows
# 安装 Visual Studio Build Tools 或 MinGW-w64
```

**Git**：插件管理需要

```bash
# Ubuntu/Debian
sudo apt install git

# Fedora/RHEL
sudo dnf install git

# Arch Linux
sudo pacman -S git

# macOS
brew install git

# Windows
# 从 https://git-scm.com 下载安装包
```

**Ripgrep**：文件搜索功能

```bash
# Ubuntu/Debian
sudo apt install ripgrep

# Fedora/RHEL
sudo dnf install ripgrep

# Arch Linux
sudo pacman -S ripgrep

# macOS
brew install ripgrep

# Windows
# 使用 Chocolatey: choco install ripgrep
```

#### MPV 可选依赖

**FFmpeg**：增强的格式支持（通常已包含在 MPV 中）

```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# Fedora/RHEL
sudo dnf install ffmpeg

# Arch Linux
sudo pacman -S ffmpeg

# macOS
brew install ffmpeg

# Windows
# 从 https://ffmpeg.org 下载或使用包管理器
```

### 安装后设置

安装完所有依赖后：

1. **重启终端**以确保所有路径更新
2. **启动 Neovim** 首次运行会自动安装插件：

   ```bash
   nvim
   ```

   插件将自动安装，可能需要几分钟时间。

3. **验证安装**：

   ```bash
   # 检查 Node.js
   node --version

   # 检查 Python
   python3 --version

   # 检查构建工具
   gcc --version
   cmake --version

   # 检查 Git
   git --version
   ```

## 使用方法

### Linux / macOS

#### 方式一：直接复制（推荐）

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

#### 方式二：创建符号链接（本地同步）

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

### Windows 10 / 11

#### 方式一：使用还原脚本（推荐）

本仓库提供了 PowerShell 脚本，用于在 Windows 上管理配置文件。配置文件将安装到 `%LOCALAPPDATA%`（用户主目录\AppData\Local\）。

```powershell
# 克隆仓库
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 运行还原脚本（需要以管理员权限或允许脚本执行）
.\restore-config.ps1
```

**注意**：如果遇到执行策略错误，可以临时允许脚本执行：

```powershell
# 临时允许执行脚本（当前 PowerShell 会话）
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 然后运行脚本
.\restore-config.ps1
```

还原脚本会：
1. 将配置文件从仓库复制到 `%LOCALAPPDATA%`
2. 自动备份现有配置（如果存在）为 `.bak` 后缀
3. 如果已存在 `.bak` 备份，会先删除旧备份

#### 方式二：手动复制

```powershell
# 克隆仓库
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles

# 手动复制配置文件到 %LOCALAPPDATA%
Copy-Item -Path kitty -Destination $env:LOCALAPPDATA\kitty -Recurse
Copy-Item -Path mpv -Destination $env:LOCALAPPDATA\mpv -Recurse
Copy-Item -Path neovide -Destination $env:LOCALAPPDATA\neovide -Recurse
Copy-Item -Path nvim -Destination $env:LOCALAPPDATA\nvim -Recurse
```

## 同步配置文件

本仓库提供了自动同步脚本，用于将本地配置文件的更改同步到 Git 仓库。

### Linux / macOS

#### 使用同步脚本

```bash
cd ~/dotfiles
./sync-config.sh
```

脚本会：

1. 将 `~/.config/` 中的配置文件复制到仓库
2. 检测文件变更并自动提交
3. 询问是否推送到 GitHub

#### 自动化同步（可选）

你可以设置定期任务来自动同步配置：

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天晚上 11 点同步）
0 23 * * * cd ~/dotfiles && ./sync-config.sh >/dev/null 2>&1
```

### Windows 10 / 11

#### 使用同步脚本

```powershell
cd dotfiles
.\sync-config.ps1
```

脚本会：

1. 将 `%LOCALAPPDATA%` 中的配置文件复制到仓库
2. 清理嵌入的 git 仓库（如果有）
3. 检测文件变更并自动提交
4. 询问是否推送到 GitHub

**注意**：如果遇到执行策略错误，可以临时允许脚本执行：

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\sync-config.ps1
```

#### 自动化同步（可选）

你可以使用任务计划程序来自动同步配置：

```powershell
# 创建一个批处理文件 sync-dotfiles.bat（将路径替换为你的 dotfiles 仓库位置）
@echo off
cd /d "%USERPROFILE%\dotfiles"
powershell.exe -ExecutionPolicy Bypass -File ".\sync-config.ps1"
```

然后在任务计划程序中创建定时任务运行此批处理文件。

**注意**：请根据实际克隆位置修改 `%USERPROFILE%\dotfiles` 路径。

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

### Neovide 图形界面

- Neovim 的 GUI 前端配置
- 包含字体和界面设置

### Neovim 编辑器配置

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
