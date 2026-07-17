# 同步配置文件脚本
# 这个脚本会将 ~/.config/ 和 ~/ 中的配置文件更新到 dotfiles 仓库
# ~/.config/<name> → config/<name>
# ~/<name>          → home/<name>   (name 以 . 开头，如 .pi)

$ErrorActionPreference = "Stop"

Write-Host "开始同步配置文件到 dotfiles 仓库..." -ForegroundColor Green

# 进入 dotfiles 目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# ~/.config/ 下的配置目录 (Windows: %LOCALAPPDATA%)
$ConfigDirs = @("kitty", "mpv", "neovide", "nvim", "fish", "yazi", "figlet", "bat", "vscode")

# ~/ 下的配置 (Windows: %USERPROFILE%)
$HomeNames = @(".pi")

# ── 同步 %LOCALAPPDATA% ──
foreach ($dir in $ConfigDirs) {
    Write-Host "同步 %LOCALAPPDATA%\$dir ..." -ForegroundColor Cyan

    $LocalDir = Join-Path $ScriptDir "config\$dir"
    if (Test-Path $LocalDir) {
        Remove-Item -Path $LocalDir -Recurse -Force
    }

    $SourceDir = Join-Path $env:LOCALAPPDATA $dir
    if (Test-Path $SourceDir) {
        Copy-Item -Path $SourceDir -Destination $LocalDir -Recurse
        Write-Host "✓ config/$dir 同步完成" -ForegroundColor Green
    } else {
        Write-Host "⚠ 警告: $SourceDir 不存在，跳过同步" -ForegroundColor Yellow
    }
}

# ── 同步 %USERPROFILE% ──
foreach ($name in $HomeNames) {
    Write-Host "同步 %USERPROFILE%\$name ..." -ForegroundColor Cyan

    $LocalPath = Join-Path $ScriptDir "home\$name"
    if ((Test-Path $LocalPath) -or (Test-Path $LocalPath -PathType Container)) {
        Remove-Item -Path $LocalPath -Recurse -Force
    }

    $SourcePath = Join-Path $env:USERPROFILE $name
    if ((Test-Path $SourcePath) -or (Test-Path $SourcePath -PathType Container)) {
        Copy-Item -Path $SourcePath -Destination $LocalPath -Recurse
        Write-Host "✓ home/$name 同步完成" -ForegroundColor Green
    } else {
        Write-Host "⚠ 警告: $SourcePath 不存在，跳过同步" -ForegroundColor Yellow
    }
}

# 清理可能的嵌入 git 仓库
Write-Host "清理嵌入的 git 仓库..." -ForegroundColor Cyan
Get-ChildItem -Path $ScriptDir -Filter ".git" -Recurse -Directory -Force |
    Where-Object { $_.FullName -ne (Join-Path $ScriptDir ".git") } |
    ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }

# Git 操作
Write-Host "检查 Git 状态..." -ForegroundColor Cyan

git diff --quiet
$hasUnstagedChanges = $LASTEXITCODE -ne 0
git diff --staged --quiet
$hasStagedChanges = $LASTEXITCODE -ne 0

if (-not $hasUnstagedChanges -and -not $hasStagedChanges) {
    Write-Host "没有检测到配置文件变更" -ForegroundColor Yellow
} else {
    Write-Host "检测到配置文件变更，正在提交..." -ForegroundColor Green
    git add .

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CommitMessage = @"
更新配置文件 - $Timestamp

自动同步 %LOCALAPPDATA% 和 %USERPROFILE% 中的配置文件到 dotfiles 仓库
"@

    git commit -m $CommitMessage

    Write-Host "提交完成！" -ForegroundColor Green

    $Response = Read-Host "是否推送到 GitHub? (Y/n)"
    if ($Response -match '^[Nn]$') {
        Write-Host "跳过推送，你可以稍后手动运行 'git push'" -ForegroundColor Yellow
    } else {
        Write-Host "推送到远程仓库..." -ForegroundColor Cyan
        git push
        Write-Host "✓ 推送完成！" -ForegroundColor Green
    }
}

Write-Host "配置文件同步完成！" -ForegroundColor Green
