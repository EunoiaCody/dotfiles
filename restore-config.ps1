# 还原配置文件脚本（带本地备份，存在 .bak 先删除再备份）
# 将 dotfiles 仓库中的配置文件恢复到 %LOCALAPPDATA%（用户主目录\AppData\Local\），如有同名目录则本地重命名为 .bak（已存在则先删）

$ErrorActionPreference = "Stop"

Write-Host "从 GitHub 拉取配置文件..." -ForegroundColor Green

git pull

Write-Host "开始还原配置文件到 $env:LOCALAPPDATA ..." -ForegroundColor Green

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$ConfigDirs = @("kitty", "mpv", "neovide", "nvim", "fish")

foreach ($dir in $ConfigDirs) {
    $Src = Join-Path $ScriptDir $dir
    $Dest = Join-Path $env:LOCALAPPDATA $dir
    $Bak = "$Dest.bak"

    Write-Host "处理 $dir ..." -ForegroundColor Cyan

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
    Write-Host "✓ $dir 还原完成" -ForegroundColor Green
}

Write-Host "全部配置文件还原完成！" -ForegroundColor Green
