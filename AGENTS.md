# AGENTS.md

This file provides guidance to AI coding agents (pi, Copilot, Cursor, Claude) when working with this repository.

## Project Overview

Personal dotfiles repository by **@EunoiaCody** — a collection of configuration files for a Linux/macOS development environment. Covers the full desktop stack: Wayland compositor (niri), desktop shell (quickshell), terminal (kitty), shell (fish), file manager (yazi), editor (neovim), media player (mpv), AI agent (pi), and various CLI tools. Managed via copy-based sync scripts (not symlinks/GNU stow) so configs are directly viewable on GitHub.

## Tech Stack

| Layer | Technology | Config Language |
|-------|-----------|-----------------|
| Display server | Wayland (niri compositor) | KDL |
| Desktop shell | QuickShell (Qt6/QML) | QML, JavaScript |
| Terminal | Kitty | kitty.conf (INI-like) |
| Shell | Fish | Fish script |
| Editor | Neovim 0.12+ | Lua |
| Neovim GUI | Neovide | TOML |
| File manager | Yazi (Rust) | TOML |
| Media player | MPV | mpv.conf, Lua scripts |
| AI agent | pi | Config files in ~/.pi/ |
| macOS WM | AeroSpace | TOML |
| macOS bar | SketchyBar | Lua |
| Pager | bat | custom themes |
| Install/bootstrap | Python 3 + Bash | Python, Bash |

**Theme**: Catppuccin Mocha (primary), with Macchiato, Frappe, and Latte variants available for fish, bat, and kitty.

## Project Structure

```
dotfiles/
├── bootstrap.sh              # One-liner bootstrap: clones repo if needed, runs install.py
├── install.py                # Python installer with interactive TUI (component selection, package detection)
├── sync-config.sh            # Sync ~/.config/ + ~/ dotfiles → repo (Linux/macOS)
├── sync-config.ps1           # Sync %LOCALAPPDATA% + %USERPROFILE% → repo (Windows)
├── restore-config.sh         # Restore repo → ~/.config/ + ~/ with .bak backup (Linux/macOS)
├── restore-config.ps1        # Restore repo → %LOCALAPPDATA% + %USERPROFILE% with .bak backup (Windows)
│
├── config/                   # All ~/.config/ entries
│   ├── niri/                 #   Niri Wayland compositor (scrollable-tiling)
│   │   ├── config.kdl        #     Startup apps, outputs, environment, screenshots
│   │   ├── binds.kdl         #     Keybindings
│   │   ├── color.kdl         #     Catppuccin color rules
│   │   ├── animation.kdl     #     Spring-based window animations
│   │   ├── blur.kdl          #     Background blur settings
│   │   └── windows-rule.kdl  #     Per-window rules (opacity, corner radius)
│   ├── quickshell/           #   QuickShell desktop shell (Qt6/QML)
│   │   ├── Modules/          #     Feature modules: Bar, DynamicIsland, Lock, Launcher, Sidebars, Wallpaper
│   │   ├── Services/         #     Backend QML services: Audio, Bluetooth, Network, Media, Notifications, etc.
│   │   ├── Common/           #     Shared engines: LyricsSyncEngine, LyricsDaemon, ColorMap, Animations
│   │   ├── Components/       #     Reusable UI primitives: MaterialSymbol, SvgIcon
│   │   ├── Widgets/          #     Composite widgets: RollingDigit, SpringLyricView
│   │   ├── scripts/          #     Python helpers: lyrics_fetcher, weather, title_parser, parse_schedule
│   │   ├── assets/shaders/   #     GLSL wallpaper transition shaders (7 effects)
│   │   └── start-quickshell.sh #   Launch script invoked by niri
│   ├── kitty/                #   Kitty terminal (~2800 line kitty.conf + theme include)
│   ├── fish/                 #   Fish shell (conf.d, completions, functions, themes)
│   ├── yazi/                 #   Yazi file manager (smart-filter plugin, clipboard sync)
│   ├── nvim/                 #   Neovim 0.12+ editor (see nvim/CLAUDE.md for full details)
│   ├── neovide/              #   Neovide GUI (config.toml)
│   ├── mpv/                  #   MPV media player (uosc UI, danmaku, Anime4K shaders)
│   ├── bat/                  #   bat pager — Catppuccin .tmTheme files (4 variants)
│   ├── figlet/               #   ANSI-Shadow.flf font
│   ├── aerospace/            #   macOS AeroSpace WM — aerospace.toml
│   ├── sketchybar/           #   macOS SketchyBar — Lua configs
│   └── vscode/               #   VSCode — custom CSS/JS injection
│
├── home/                     # All ~/ (home directory) dotfiles
│   └── .pi/                  #   pi-agent configuration (~/.pi/)
│
└── dotfiles-scripts/         # (empty) Placeholder for additional scripts
```

## Build, Run, Test

This is a **dotfiles repo**, not a software project. There is no build step. Key operational commands:

### Bootstrap (fresh install)
```bash
git clone https://github.com/EunoiaCody/dotfiles.git
cd dotfiles
./bootstrap.sh           # wrapper: clones if needed, then runs install.py
# or directly:
python3 install.py       # interactive TUI with component checkboxes
```

### Sync (local edits → repo)
Copies from both `~/.config/` → `config/` and `~/.*` dotfiles → `home/`:
```bash
./sync-config.sh         # Linux/macOS
.\sync-config.ps1        # Windows
```

### Restore (repo → local, with backup)
Restores from `config/` → `~/.config/` and `home/` → `~/`:
```bash
./restore-config.sh      # Linux/macOS: backs up existing as .bak, copies repo → home
.\restore-config.ps1     # Windows: same, to %LOCALAPPDATA% / %USERPROFILE%
```

### Apply config changes (per-tool)
```bash
# Kitty: reload config
killall -SIGUSR1 kitty

# Niri: apply keyboard config
niri msg action do-screen-transition

# Fish: reload
exec fish

# Neovim: re-source
:source $MYVIMRC
```

### Testing
- `python3 -m pytest config/quickshell/scripts/media/test_title_parser.py` — Title parser unit tests
- `python3 config/quickshell/scripts/media/title_parser.py` — Manual title parsing test (interactive)
- `python3 config/quickshell/scripts/media/lyrics_fetcher.py` — Lyrics fetcher manual test

## Code Conventions

### General
- **No symlinks**: All configs are real files copied into the repo. Use `sync-config.sh` to pull changes back.
- **Two-source layout**: `config/` maps to `~/.config/`, `home/` maps to `~/`. Scripts handle both.
- **Theme**: Catppuccin Mocha everywhere by default. Theme variants in subdirectories (e.g., `fish/themes/`, `bat/themes/`).
- **File paths**: Configs assume `~/.config/<app>/` on Linux/macOS, `%LOCALAPPDATA%\<app>\` on Windows.

### Shell scripts (Bash)
- All start with `#!/usr/bin/env bash` and `set -euo pipefail` (or just `set -e`)
- Color output via terminal-detection (`[[ -t 1 ]]`)
- Script dir detection: `$( cd "$( dirname "${BASH_SOURCE[0]:-.}" )" && pwd )`

### Python (install.py, scripts)
- `install.py`: stdlib only (no pip deps required), uses dataclasses
- `quickshell/scripts/`: Python 3 with external deps (`requests`, `mutagen`) — see individual file imports
- No formatter config present; follow PEP 8 conventions

### Lua (nvim, yazi, sketchybar)
- **nvim**: See `config/nvim/CLAUDE.md` for full conventions. Key: plugin specs in `lua/plugins/`, config in `lua/config/`, lazy.nvim plugin manager, Neovim 0.12 `vim.lsp.config()` API.
- **yazi**: `init.lua` bootstraps plugin system; `keymap.toml` is 378 lines
- **sketchybar**: Lua config via `init.lua` → `settings.lua` + `colors.lua` + `items/*`

### KDL (niri)
- KDL format (https://kdl.dev) — not JSON/YAML
- `//` comments, `/-` to comment out nodes
- Modular: split by concern (binds, color, animation, blur, windows-rule)

### QML/JS (quickshell)
- Module structure: each functional area has its own subdirectory with `qmldir`
- Reusable components in `Widgets/`; shared singletons in `Common/` and `Services/`
- JavaScript helper functions in `Common/functions/`

### Fish Shell
- Config in `conf.d/` loads automatically (no `source` needed)
- `fish_plugins` managed by Fisher; `fish_variables` by `set -U`
- Custom completions in `completions/`, functions in `functions/`

### TOML
- Used by: aerospace, neovide, yazi, nvim/lazy-lock.json
- No project-wide TOML style enforced

## Architecture Patterns

### Copy-based dotfile management (not GNU stow)
Configs live **as real copies** in the repo under `config/` and `home/`, not symlinks. This means:
- `~/.config/kitty/` ≡ `dotfiles/config/kitty/`
- `~/.pi/` ≡ `dotfiles/home/.pi/`
- Run `sync-config.sh` to pull local changes back into the repo
- Run `restore-config.sh` to deploy repo → local system (old configs backed up as `.bak`)

### Modular config split
Several components use multi-file configs:
- **niri**: `config.kdl` includes `binds.kdl`, `color.kdl`, etc. via `import` directive
- **nvim**: `init.lua` → `require("config.*")` → `lua/plugins/*.lua` (auto-imported by lazy.nvim)
- **fish**: `conf.d/*.fish` auto-sourced by Fish in alphabetical order
- **quickshell**: `qmldir` files register QML modules for import

### Quickshell service architecture
Services (`Services/`) are singleton QML objects providing backend functionality (Bluetooth, Network, Media, Notifications, etc.). Modules (`Modules/`) consume these services for UI rendering. `Common/` holds cross-cutting engines (lyrics sync, daemon processes, color/theme maps, animation presets, size constants).

### Lyrics system data flow
```
Browser/player title → title_parser.py → is_likely_music? → extract artist/title
                                                              ↓
LyricsDaemon (QML) → spawns lyrics_fetcher.py → QQ/NetEase/AMLL API
                                                              ↓
LyricsSyncEngine (QML) → binary search position → word-level progress
                                                              ↓
DynamicIsland (LyricsContent) / Media (SpringLyricView) → render
```

## Entry Points

| Tool | Entry Point | Platform |
|------|------------|----------|
| niri | `niri --config ~/.config/niri/config.kdl` | Linux |
| quickshell | `~/.config/quickshell/start-quickshell.sh` (launched by niri) | Linux |
| kitty | `kitty --config ~/.config/kitty/kitty.conf` | Linux/macOS |
| fish | `~/.config/fish/config.fish` (auto-sourced) | Linux/macOS |
| nvim | `~/.config/nvim/init.lua` | Linux/macOS/Windows |
| neovide | `~/.config/neovide/config.toml` | Linux/macOS/Windows |
| mpv | `~/.config/mpv/mpv.conf` | Linux/macOS/Windows |
| yazi | `~/.config/yazi/yazi.toml` + `init.lua` | Linux/macOS/Windows |
| pi | `~/.pi/` (auto-detected by pi-agent) | Linux/macOS/Windows |
| aerospace | `~/.aerospace.toml` | macOS |
| sketchybar | `~/.config/sketchybar/sketchybarrc` | macOS |

## Key Dependencies

### Linux desktop
| Package | Purpose |
|---------|---------|
| niri | Wayland compositor (scrollable-tiling) |
| quickshell | Desktop shell (QML/Qt6) |
| wlroots | niri dependency |
| polkit-gnome | Authentication agent (started by niri) |
| awww | Wallpaper daemon (Wayland) |
| wl-clipboard | Clipboard utilities (wl-paste for fish) |
| JetBrains Mono Nerd Font | Terminal font |

### Cross-platform
| Package | Purpose |
|---------|---------|
| Kitty ≥0.38 | Terminal emulator |
| Fish ≥3.0 | Shell |
| Neovim ≥0.12 | Editor (requires `vim.lsp.config()` API) |
| Yazi | File manager (Rust, install via cargo) |
| MPV | Media player |
| bat | Syntax-highlighting pager |
| pi-agent | AI coding agent |
| Git | Version control |
| Ripgrep | File search (nvim telescope dependency) |
| Node.js | LSP servers, copilot |
| Bun | JavaScript runtime (fish completion) |

### macOS-only
| Package | Purpose |
|---------|---------|
| AeroSpace | Tiling window manager |
| SketchyBar | Status bar |
| Homebrew | Package manager |

### Python scripts (quickshell)
```
requests  — HTTP API calls (lyrics, weather)
mutagen   — Audio metadata parsing
```

### Neovim key plugins
See `config/nvim/CLAUDE.md` for full list. Core: lazy.nvim, blink.cmp, conform.nvim, mason.nvim, codecompanion.nvim, avante.nvim, snacks.nvim.

## Environment & Config

### Environment variables
```bash
EDITOR=nvim                    # Set in fish/config.fish
BUN_INSTALL=$HOME/.bun         # Bun runtime path
AVANTE_OPENCODE_API_KEY        # Required for avante.nvim AI features (opencode.ai)
```

### Config file locations (Linux/macOS)
| App | Repo Path | Local Config Path |
|-----|-----------|-------------------|
| niri | `config/niri/` | `~/.config/niri/` |
| quickshell | `config/quickshell/` | `~/.config/quickshell/` |
| kitty | `config/kitty/` | `~/.config/kitty/` |
| fish | `config/fish/` | `~/.config/fish/` |
| yazi | `config/yazi/` | `~/.config/yazi/` |
| nvim | `config/nvim/` | `~/.config/nvim/` |
| neovide | `config/neovide/` | `~/.config/neovide/` |
| mpv | `config/mpv/` | `~/.config/mpv/` |
| bat | `config/bat/` | `~/.config/bat/` |
| figlet | `config/figlet/` | `~/.config/figlet/` |
| vscode | `config/vscode/` | `~/.config/vscode/` |
| pi-agent | `home/.pi/` | `~/.pi/` |
| aerospace | `config/aerospace/` | `~/.aerospace.toml` |
| sketchybar | `config/sketchybar/` | `~/.config/sketchybar/` |

### macOS-specific notes
- Aerospace and SketchyBar configs are **only applicable on macOS**
- `install.py` auto-detects platform and offers only relevant components
- `fish/config.fish` has a macOS-specific `.local/bin` PATH entry (pipx)

## Testing Strategy

No automated CI/CD. Manual testing:

- **Title parser**: `python3 config/quickshell/scripts/media/test_title_parser.py` — pytest-based unit tests for `title_parser.py`
- **Lyrics fetcher**: Run `lyrics_fetcher.py` directly with artist/title args
- **Config validation**: Most tools validate their own config on startup (check logs/`:messages`)
- **Kitty**: `kitty --debug-config` shows resolved settings
- **Neovim**: `:checkhealth` for LSP/plugin diagnostics

## Deployment

### New machine setup
```bash
# Option 1: Bootstrap script
curl -fsSL https://raw.githubusercontent.com/EunoiaCody/dotfiles/main/bootstrap.sh | bash

# Option 2: Manual clone + install
git clone https://github.com/EunoiaCody/dotfiles.git ~/dotfiles
cd ~/dotfiles
python3 install.py      # interactive component selection
# or
./restore-config.sh     # non-interactive, backs up existing configs
```

### Syncing changes back
1. Edit configs in `~/.config/<app>/` or `~/.pi/` as normal
2. Run `./sync-config.sh` from repo root
3. Script copies `~/.config/*` → `config/`, `~/.*` → `home/`, commits, and optionally pushes

### Platform-specific configs
- `sync-config.ps1` / `restore-config.ps1` are **Windows-only** and use `%LOCALAPPDATA%` / `%USERPROFILE%` instead of `~/.config` / `~/`
- `install.py` auto-detects Linux/macOS and adjusts package manager commands
- The PowerShell scripts only cover a subset of tools (excludes Linux-only tools like niri/quickshell)

## Additional Notes

- **Sub-agent guides**: `config/nvim/CLAUDE.md` and `config/kitty/CLAUDE.md` provide detailed instructions for AI agents editing those specific configs. Always read these before modifying nvim or kitty files.
- **Neovim version constraint**: Config requires Neovim 0.12+ due to `vim.lsp.config()` / `vim.lsp.enable()` APIs and new treesitter injection directives. Ubuntu users need the `neovim-ppa/stable` PPA.
- **Arch Linux preferred**: `install.py` has native Arch (`pacman`) support with fallback to apt/dnf. QuickShell is noted as "Arch preferred."
- **pi-agent**: Config stored in `home/.pi/` (maps to `~/.pi/`). Not managed by system package manager — `install.py` handles it as a copy-only component.
- **dotfiles-scripts/**: Currently empty; placeholder for future script additions.
- **License**: MIT
