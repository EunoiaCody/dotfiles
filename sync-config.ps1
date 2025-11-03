# 同步配置文件脚本
# 这个脚本会将 $env:LOCALAPPDATA 中的配置文件更新到 dotfiles 仓库

$ErrorActionPreference = "Stop"

Write-Host "开始同步配置文件到 dotfiles 仓库..." -ForegroundColor Green

# 进入 dotfiles 目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 配置文件夹列表
$ConfigDirs = @("kitty", "mpv", "neovide", "nvim")

# 同步每个配置文件夹
foreach ($dir in $ConfigDirs) {
    Write-Host "同步 $dir..." -ForegroundColor Cyan
    
    # 删除旧的文件夹（如果存在）
    $LocalDir = Join-Path $ScriptDir $dir
    if (Test-Path $LocalDir) {
        Remove-Item -Path $LocalDir -Recurse -Force
    }
    
    # 复制新的配置文件
    $SourceDir = Join-Path $env:LOCALAPPDATA $dir
    if (Test-Path $SourceDir) {
        Copy-Item -Path $SourceDir -Destination $LocalDir -Recurse
        Write-Host "✓ $dir 同步完成" -ForegroundColor Green
    } else {
        Write-Host "⚠ 警告: $SourceDir 不存在，跳过同步" -ForegroundColor Yellow
    }
}

# 清理可能的嵌入 git 仓库
Write-Host "清理嵌入的 git 仓库..." -ForegroundColor Cyan
Get-ChildItem -Path $ScriptDir -Filter ".git" -Recurse -Directory -Force | 
    Where-Object { $_.FullName -ne (Join-Path $ScriptDir ".git") } |
    ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }

# Git 操作
Write-Host "检查 Git 状态..." -ForegroundColor Cyan

$gitStatus = git status --porcelain
if ([string]::IsNullOrEmpty($gitStatus)) {
    Write-Host "没有检测到配置文件变更" -ForegroundColor Yellow
} else {
    Write-Host "检测到配置文件变更，正在提交..." -ForegroundColor Green
    git add .
    
    # 生成提交信息
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CommitMessage = @"
更新配置文件 - $Timestamp

自动同步 AppData\Local 中的配置文件到 dotfiles 仓库
"@
    
    git commit -m $CommitMessage
    
    Write-Host "提交完成！" -ForegroundColor Green
    
    # 询问是否推送到远程仓库
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
