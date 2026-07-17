# 还原配置文件脚本（带本地备份，存在 .bak 先删除再备份）
# 将 dotfiles 仓库中的配置文件恢复到 %LOCALAPPDATA% 和 %USERPROFILE%
# config/<name> → %LOCALAPPDATA%/<name>
# home/<name>   → %USERPROFILE%/<name>   (name 以 . 开头，如 .pi)

$ErrorActionPreference = "Stop"

Write-Host "从 GitHub 拉取配置文件..." -ForegroundColor Green

git pull

Write-Host "开始还原配置文件 ..." -ForegroundColor Green

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# %LOCALAPPDATA% 下的配置目录
$ConfigDirs = @("kitty", "mpv", "neovide", "nvim", "fish", "yazi", "figlet", "bat", "vscode")

# %USERPROFILE% 下的配置（以 . 开头的文件/目录）
$HomeNames = @(".pi")

# ── 还原 %LOCALAPPDATA% ──
foreach ($dir in $ConfigDirs) {
    $Src = Join-Path $ScriptDir "config\$dir"
    $Dest = Join-Path $env:LOCALAPPDATA $dir
    $Bak = "$Dest.bak"

    Write-Host "处理 %LOCALAPPDATA%\$dir ..." -ForegroundColor Cyan

    if (-not (Test-Path $Src)) {
        Write-Host "⚠ 警告: dotfiles 仓库下未找到 $Src，跳过还原" -ForegroundColor Yellow
        continue
    }

    if (Test-Path $Dest) {
        if (Test-Path $Bak) {
            Write-Host "→ 检测到 $Bak 已存在，先删除" -ForegroundColor Gray
            Remove-Item -Path $Bak -Recurse -Force
        }
        Write-Host "→ 备份 $Dest 为 $Bak" -ForegroundColor Gray
        Move-Item -Path $Dest -Destination $Bak
    }

    Copy-Item -Path $Src -Destination $Dest -Recurse
    Write-Host "✓ %LOCALAPPDATA%\$dir 还原完成" -ForegroundColor Green
}

# ── 还原 %USERPROFILE% ──
foreach ($name in $HomeNames) {
    $Src = Join-Path $ScriptDir "home\$name"
    $Dest = Join-Path $env:USERPROFILE $name
    $Bak = "$Dest.bak"

    Write-Host "处理 %USERPROFILE%\$name ..." -ForegroundColor Cyan

    if (-not (Test-Path $Src)) {
        Write-Host "⚠ 警告: dotfiles 仓库下未找到 $Src，跳过还原" -ForegroundColor Yellow
        continue
    }

    if ((Test-Path $Dest) -or (Test-Path $Dest -PathType Container)) {
        if ((Test-Path $Bak) -or (Test-Path $Bak -PathType Container)) {
            Write-Host "→ 检测到 $Bak 已存在，先删除" -ForegroundColor Gray
            Remove-Item -Path $Bak -Recurse -Force
        }
        Write-Host "→ 备份 $Dest 为 $Bak" -ForegroundColor Gray
        Move-Item -Path $Dest -Destination $Bak
    }

    Copy-Item -Path $Src -Destination $Dest -Recurse
    Write-Host "✓ %USERPROFILE%\$name 还原完成" -ForegroundColor Green
}

Write-Host "全部配置文件还原完成！" -ForegroundColor Green
