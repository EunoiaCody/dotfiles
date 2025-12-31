# Restore config files script (with local backup, delete existing .bak before backing up)
# Restore config files from dotfiles repo to %LOCALAPPDATA% (user home\AppData\Local\), rename existing directories to .bak (delete if exists)

$ErrorActionPreference = "Stop"

Write-Host "从 GitHub 拉取配置文件..." -ForegroundColor Green

git pull

Write-Host "开始还原配置文件到 $env:LOCALAPPDATA ..." -ForegroundColor Green

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$ConfigDirs = @("mpv", "neovide", "nvim")

foreach ($dir in $ConfigDirs) {
    $Src = Join-Path $ScriptDir $dir
    $Dest = Join-Path $env:LOCALAPPDATA $dir
    $Bak = "$Dest.bak"

    Write-Host "Processing $dir ..." -ForegroundColor Cyan

    if (-not (Test-Path $Src)) {
        Write-Host "Warning: $Src not found in dotfiles repo, skipping restore" -ForegroundColor Yellow
        continue
    }

    if (Test-Path $Dest) {
        if (Test-Path $Bak) {
            Write-Host "→ Detected existing $Bak, deleting first" -ForegroundColor Gray
            Remove-Item -Path $Bak -Recurse -Force
        }
        Write-Host "→ Backing up $Dest as $Bak" -ForegroundColor Gray
        Move-Item -Path $Dest -Destination $Bak
    }

    Copy-Item -Path $Src -Destination $Dest -Recurse
    Write-Host "$dir restore completed" -ForegroundColor Green
}

Write-Host "All config files restored successfully!" -ForegroundColor Green
