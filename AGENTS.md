# AGENTS.md

Guidance for AI coding agents (pi, Copilot, Cursor, Claude) working in this repository.
General project info lives in [`README.md`](README.md); per-tool deep dives live in
`config/quickshell/AGENTS.md`, `config/quickshell/CLAUDE.md`, `config/nvim/CLAUDE.md`,
`config/kitty/CLAUDE.md`. **Read the relevant one before editing that subtree.**

## Project Overview

Personal dotfiles by **@EunoiaCody** — configuration for a full Linux Wayland desktop
(niri compositor + a Quickshell/Qt6 desktop shell named **Clavis**) plus macOS bits
(AeroSpace, SketchyBar) and cross-platform tools (kitty, fish, nvim, mpv, yazi).

Configs are **real copies**, not symlinks: the live tree (`~/.config/*`, `~/.*`) is the
working copy, and this repo is the archive of record, refreshed by `./sync-config.sh`.
That single fact drives most of the workflow rules below.

`config/quickshell/` is the largest subtree — a Quickshell shell config aligned to
upstream `StatIndet/quickshell` HEAD, and it is **GPL-3.0** (see [Licensing](#licensing)).

## Tech Stack

| Layer | Technology | Config format | Notes |
|-------|-----------|---------------|-------|
| Compositor | niri (Wayland) | KDL | scrollable-tiling; modular via `include` |
| Desktop shell | Quickshell 0.3.x on Qt 6.11 | QML, JavaScript | `config/quickshell/` (Clavis) |
| Shell plugins | Clavis C++ Qt plugins + M3Shapes | C++ / QML | built to `~/.local/share/qt6/qml-next/Clavis` |
| Terminal | kitty ≥0.38 | kitty.conf | ~2800-line `kitty.conf` + theme include |
| Shell | fish ≥3.0 | fish script | `conf.d/`, `functions/`, `completions/`, `themes/` |
| Editor | Neovim ≥0.12 | Lua | requires `vim.lsp.config()` API |
| Neovim GUI | Neovide | TOML | |
| File manager | yazi | TOML + Lua | `smart-filter` plugin |
| Media player | mpv | mpv.conf, Lua | uosc UI, danmaku, Anime4K shaders |
| Audio viz | cava | INI + GLSL | `config/cava/` |
| Image viewer | imv | INI | `config/imv/config` |
| Terminal mux | zellij | KDL | `config/zellij/config.kdl` |
| Pager | bat | tmTheme | 4 Catppuccin variants |
| AI agent | pi | JSON/TS | `home/.pi/agent/` |
| macOS WM / bar | AeroSpace, SketchyBar | TOML, Lua | macOS only |
| Install | Python 3 + Bash | — | stdlib-only installer |

**Theme**: fixed **Catppuccin Mocha + lavender**. Dynamic matugen theming exists
(`assets/matugen/templates`, `scripts/theme/*.sh`) but is **off by default** — the fixed
palette is bridged over upstream via `Common/ColorMap.qml` + `Common/Appearance.qml`.
Do not "fix" a component by re-introducing upstream matugen behaviour.

## Project Structure

```
dotfiles/
├── bootstrap.sh              # One-liner entry: clone if needed → install.py
├── install.py                # Interactive installer (stdlib only, dataclasses, argparse)
├── sync-config.sh            # ~/.config/* + ~/.* → repo, then commit (Linux/macOS)
├── restore-config.sh         # Repo → ~/.config/* + ~/.*, existing dirs backed up as .bak
├── AGENTS.md / README.md
│
├── config/                   # mirrors ~/.config/
│   ├── niri/                 #   niri compositor
│   │   ├── config.kdl        #     startup, outputs, input, environment
│   │   ├── binds.kdl         #     user keybindings (IPC-driven)
│   │   ├── color.kdl animation.kdl blur.kdl cursor.kdl windows-rule.kdl
│   │   └── clavis/           #     CLAVIS-MANAGED (generated): binds.kdl, effects.kdl, layer-rules.kdl
│   ├── quickshell/           #   Clavis desktop shell (GPL-3.0, 28 MB, 2752 files)
│   │   ├── AppShell.qml shell.qml qmldir   # shell root
│   │   ├── start-quickshell.sh              # launcher: sets plugin paths, execs quickshell
│   │   ├── Modules/          #     Bar, Keystone, Sidebars, ControlCenter, Lock, Dock,
│   │   │                     #     Launcher, PowerMenu, HotCorners, DesktopCards, Map,
│   │   │                     #     RegionSelector, FilePicker, SystemCards, QuickSettings, Wallpaper
│   │   ├── Services/         #     backend singletons (Bluetooth, Network, Volume, Brightness,
│   │   │                     #     Notifications, Media, Pipewire, PersonalizationConfig, …)
│   │   ├── Common/           #     ColorMap, Appearance, Fonts, Animations, Metrics, Sizes,
│   │   │                     #     KeystoneMotion, WidgetState, paths, settings-routes.json
│   │   ├── Widgets/          #     common/ (ActionButton, RippleButton, RollingClock, …),
│   │   │                     #     audio/ (VolumeSlider), weather/ (MeteoIcon, …)
│   │   ├── Components/       #     MaterialSymbol, SvgIcon, FileThemeIcon, ThemeIcon
│   │   ├── scripts/          #     Python helpers + dev tooling (see Build/Run/Test)
│   │   ├── assets/           #     fonts/ (Google Sans Flex), icons/, images/, shaders/
│   │   ├── i18n/             #     en_US / zh_CN / zh_TW .ts catalogues
│   │   ├── matugen/templates, licenses/    # third-party license texts (GPL/MIT/Apache/MPL)
│   │   ├── AGENTS.md CLAUDE.md LICENSE     # GPL-3.0 + agent guides
│   │   └── plan.md, PLAN_*.md, lyric-*.md # design notes in progress
│   ├── clavis/               #   USER SETTINGS consumed by quickshell
│   │   ├── config.json       #     wallpaper/theme/effects/keystone/bar/sidebar/hotCorners
│   │   ├── ui-preferences.json, dock.json, tray.json,
│   │   ├── idle-policy.json, quick-toggles.json
│   ├── kitty/                #   kitty.conf, current-theme.conf, themes/, CLAUDE.md
│   ├── mpv/                  #   mpv.conf, input.conf, conf.json, script-opts/uosc.conf,
│   │                         #   scripts/{uosc,uosc_danmaku}, shaders/ (Anime4K), fonts/
│   ├── nvim/                 #   init.lua, lua/{config,plugins}, lazy-lock.json, snippets/, CLAUDE.md
│   ├── fish/                 #   config.fish, conf.d/, functions/, completions/, themes/
│   ├── yazi/                 #   yazi.toml, keymap.toml, init.lua, plugins/
│   ├── cava/                 #   config, shaders/, themes/
│   ├── imv/                  #   config
│   ├── zellij/               #   config.kdl
│   ├── bat/                  #   config + themes/ (4 Catppuccin .tmTheme)
│   ├── neovide/config.toml
│   ├── figlet/ANSI-Shadow.flf
│   ├── aerospace/aerospace.toml        # macOS
│   └── sketchybar/                    # macOS
│
├── home/                     # mirrors ~/
│   └── .pi/agent/            #   pi-agent: extensions/*.ts, themes/, guard-allowlist.json
│
└── dotfiles-scripts/         # empty placeholder
```

### Two-repo reality (important)

`~/.config/quickshell` is **its own git repository** with real development history; this
repo only holds a synced copy of its working tree (nested `.git` is stripped by
`sync-config.sh`). So Clavis changes follow *edit live → commit in the fork → sync here*:

```bash
cd ~/.config/quickshell && git commit -am "..."   # 1. commit in the fork first
cd ~/Development/dotfiles && ./sync-config.sh      # 2. then archive into dotfiles
```

For every other tool there is only the live dir and this repo.

## Build, Run, Test

No build step — configs are interpreted. Nothing to compile except Clavis' C++ plugins,
which are built out-of-tree into `~/.local` (not part of this repo).

### Bootstrap / install
```bash
curl -fsSL https://raw.githubusercontent.com/EunoiaCody/dotfiles/main/bootstrap.sh | bash
git clone https://github.com/EunoiaCody/dotfiles.git && cd dotfiles && ./bootstrap.sh
python3 install.py                    # interactive component picker
python3 install.py --non-interactive --only kitty,nvim --dry-run
python3 install.py --mode link        # copy (default) or symlink
python3 install.py --skip quickshell
```
`install.py` flags: `--from-bootstrap` (internal), `--mode copy|link`, `--only`, `--skip`,
`--dry-run`, `--non-interactive`. Env from bootstrap: `DOTFILES_BOOTSTRAPPED`,
`DOTFILES_OS`, `DOTFILES_DISTRO`, `DOTFILES_PKG_MANAGER`, `DOTFILES_CLONE_DIR`.

### Sync / restore
```bash
./sync-config.sh      # live → repo, commits "更新配置文件 - <timestamp>", then prompts to push
./restore-config.sh   # repo → live; existing target dirs become <dir>.bak
```
Both iterate the same hardcoded lists — **`CONFIG_DIRS` in both scripts, `COMPONENT_SPECS`
in `install.py`** — so a new tool must be added in all three places (see [Known Gaps](#known-gaps--gotchas)).

### Reload after editing
```bash
systemctl --user restart quickshell-init.service   # Clavis / the shell
qs ipc reload                                      # gentler: reload config only
killall -SIGUSR1 kitty                              # kitty
exec fish                                           # fish
nvim --clean && :source ~/.config/nvim/init.lua    # nvim
niri msg action load-config-file                    # niri binds (auto-reloads anyway)
```

### Validate Clavis (run from `~/.config/quickshell`, its own repo)
```bash
./start-quickshell.sh                       # real launch; sets QML2_IMPORT_PATH etc.
QT_QPA_PLATFORM=offscreen ./start-quickshell.sh   # headless load test (catches QML errors)

./scripts/dev/check.sh                      # lint changed QML/JS/Python + build/CTest
./scripts/dev/check.sh --full               # everything, all files
./scripts/dev/lint-qml.sh                   # qmllint only
./scripts/dev/format-qml.sh                 # apply formatting
./scripts/dev/generate-search-catalog.py    # regenerate Common/generated/SearchCatalog.js
./scripts/build/compile-launcher-shaders.sh # assets/shaders/launcher/*.frag → .qsb (qsb)
./scripts/capture/lock_snapshot.sh out.png  # frame capture of the lock screen
./scripts/capture/record.sh start video|gif|audio_mic|audio_sys
./scripts/capture/screenshot_to_clipboard.sh <geometry>
```
Requires `qmllint`/`qmlformat`, `qmlls`, `shellcheck`, `clang`/`cmake` for `--native`.
CI equivalents for the fork live in `scripts/ci/{arch.sh,publish.sh}` (container-only).

### Tests
```bash
python3 -m pytest config/quickshell/scripts/media/test_title_parser.py   # unittest-style
python3 config/quickshell/scripts/media/title_parser.py                # interactive manual
python3 config/quickshell/scripts/media/lyrics_fetcher.py artist - title
python3 -m py_compile config/quickshell/scripts/system/niri_config.py  # syntax only
```

## Code Conventions

### Repo-wide
- **No symlinks** in the repo; `config/<x>` ≡ `~/.config/<x>`, `home/<.y>` ≡ `~/<.y>`.
- Never commit secrets. `.gitignore` covers `home/.pi/agent/{auth.json,models-store.json,
  settings.json}`, `home/.pi/agent/sessions/`, `**/.pi/plan*`, `*.bak` under quickshell.
- Keep generated/vendored blobs out of new commits; the tree already carries ~20 MB of
  vendored binaries (`mpv/scripts/uosc/bin/ziggy-*`, Google Sans Flex, i18n `.ts`).
- Comments: Chinese is common and fine; match the surrounding file's language.

### Bash (`bootstrap.sh`, `sync-config.sh`, `restore-config.sh`, quickshell scripts)
- `#!/usr/bin/env bash` (bootstrap/install scripts) or `#!/bin/bash`, plus `set -euo pipefail`.
- Colour gated on TTY and `NO_COLOR`; `SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"`.
- `shellcheck` clean; `scripts/dev/files.sh` holds shared file-selection helpers.
- install scripts use **tabs** for indentation; quickshell scripts use 4 spaces.

### Python (`install.py`, `quickshell/scripts/`)
- `install.py`: stdlib only, `from __future__ import annotations`, `dataclass` registry,
  tabs, PEP 8 naming, argparse for flags.
- `quickshell/scripts/`: `#!/usr/bin/env python3`, module docstring, stdlib-first.
  Third-party only where unavoidable: `requests` (lyrics/weather), `mutagen` (audio tags).
- KDL parsing is **vendored**: `scripts/system/vendor/kdl/` — do not add a dependency.
- Tests live beside the module as `test_<module>.py` using `unittest`.

### QML / JavaScript (quickshell)
- Every importable directory has a `qmldir` (`module qs.X`) **and** a matching entry — add
  new widgets to `Widgets/<area>/qmldir` or the import fails at runtime.
- Module prefixes: `import qs.Services`, `import qs.Common`, `import qs.Widgets.common`.
- Services and engines are **`QtObject` singletons**, not `Item`s.
- Business logic → `Common/functions/*.js` (`.pragma library`) or `Common/*.js`.
- User-facing strings → `qsTr()`, with translations in `i18n/clavis_*.ts` (3 languages).
- Sprite/scroll techniques used deliberately: `RollingClock` renders `0…9` stacked and
  animates `y` with `SpringAnimation`; keep `lineHeight: Text.FixedHeight`.
- **Event gotcha**: `WheelHandler` children do **not** receive wheel events on bar buttons —
  `RippleButton`'s `MouseArea` is the event target. Use the `RippleButton.wheelScrolled`
  signal instead (see `Modules/Bar/QuickSettings/{Brightness,Volume,Microphone}.qml`).
- Prefer shared components over duplicated styling: clock digits live in
  `Widgets/common/RollingClock.qml` and are used by both bar and lock screen.

### KDL (niri, zellij)
- `//` comments; `/-` to disable a node. niri splits by concern
  (`binds/color/animation/blur/cursor/windows-rule`) and `config.kdl` `include`s them.
- `config/niri/clavis/*.kdl` is **generated** by `scripts/system/niri_config.py` (header
  comment says so). Edit the generator or `config/niri/binds.kdl`, never the generated file.
- IPC spawns use `qs ipc call <target> ...` — **no `-c clavis`**; the shell runs as the
  default config, so a `-c` flag would target a non-existent instance.

### Fish
- `conf.d/*.fish` auto-sources in alphabetical order; no manual `source`.
- `fish_plugins` is Fisher-managed; `fish_variables` via `set -U`.
- Private helpers prefixed `_` (`_autopair_*`).

### Lua
- **nvim**: see `config/nvim/CLAUDE.md`. Specs in `lua/plugins/`, core in `lua/config/`,
  lazy.nvim, Neovim 0.12 `vim.lsp.config()`/`vim.lsp.enable()` APIs.
- **yazi**: `init.lua` bootstraps plugins; `keymap.toml` is the keymap source of truth.
- **sketchybar**: `init.lua` → `settings.lua` + `colors.lua` + `items/`.

### KDL/JSON/TOML
- JSON (`config/clavis/*.json`) is user-editable settings: keep keys backward compatible —
  every read goes through a normaliser with defaults (see `Services/PersonalizationConfig.qml`).
- TOML: aerospace, neovide, yazi, `lazy-lock.json`. No project-wide style enforced.

## Architecture Patterns

### Settings flow (single source of truth)
```
config/clavis/*.json          user edits (settings UI or by hand)
        ↓
Services/PersonalizationConfig.qml   normalises + exposes typed readonly properties
        ↓
Modules/… consume properties       (never read the JSON directly)
```
Adding a setting means: default in `PersonalizationConfig`, normaliser function, getter, and
a route entry in `Common/settings-routes.json` if it needs a settings page.

### niri ⇄ shell IPC contract
niri binds spawn `qs ipc call <target> [<function>] [args]`. Live targets:
`clipboard`, `control-center`, `island`, `keystone`, `launcher`, `lock`, `power-menu`,
`shortcut-map`, `sidebar`, `spotlight`, `wallpaper`.
Two sources of truth coexist by design: hand-written `config/niri/binds.kdl` and the
Clavis-managed `config/niri/clavis/binds.kdl` (included **last**, so it wins on conflict).
Renaming an IPC target requires updating both plus the generator.

### Theme bridge over upstream
The shell body is upstream Clavis/Quickshell code; only these files are local overrides:
`Common/ColorMap.qml`, `Common/Appearance.qml`, `Common/Fonts.qml`, `Common/Animations.qml`
(plus `start-quickshell.sh`). When pulling upstream changes, expect conflicts **only** here.
`Appearance.re-export`s `ColorMap`'s helpers (`mix`, `transparentize`, `clamp01`, …).

### Lyrics pipeline
```
window/media title → scripts/media/title_parser.py (is_likely_music?)
   → LyricsDaemon (QML) → scripts/media/lyrics_fetcher.py (AMLL / QQ / NetEase)
   → LyricsSyncEngine (QML, binary search on position) → word-level render
```

### Fonts
- UI font from `config/clavis/ui-preferences.json` (currently Maple Mono NF CN).
- Clock font is the **bundled variable font** `assets/fonts/google-sans-flex/` loaded via
  FontLoader in `Common/Fonts.qml`; `Fonts.systemClock`/`Fonts.expressive` point at it.
  Do not swap in a system font — the rolling-digit geometry depends on it.

### Screen model
Each bar/keystone is a `PanelWindow` variant per monitor; the bar's input mask is built
from `leadingInputRegionItem` / `trailingInputRegionItem` (see `Modules/Bar/BarContent.qml`).

## Entry Points

| Entry point | Path | Notes |
|-------------|------|-------|
| Bootstrap | `bootstrap.sh` | clones if needed, installs base pkgs, execs `install.py` |
| Installer | `install.py` | interactive TUI / CLI flags |
| Sync | `sync-config.sh` | live → repo + commit |
| Restore | `restore-config.sh` | repo → live with `.bak` |
| Shell root | `config/quickshell/shell.qml` → `AppShell.qml` | `ShellRoot`, module `qs` |
| Shell launcher | `config/quickshell/start-quickshell.sh` | exports plugin paths, `exec quickshell "$@"` |
| niri | `config/niri/config.kdl` | `spawn-at-startup systemctl --user start quickshell-init.service` |
| kitty | `config/kitty/kitty.conf` (+ `current-theme.conf`) | |
| fish | `config/fish/config.fish` | auto-sourced |
| nvim | `config/nvim/init.lua` | |
| mpv | `config/mpv/mpv.conf` | |
| yazi | `config/yazi/yazi.toml` + `init.lua` | |
| cava | `config/cava/config` | |
| pi agent | `home/.pi/agent/` | |

## Key Dependencies

### Linux desktop
| Package | Purpose |
|---------|---------|
| niri + wlroots | Wayland compositor |
| quickshell (Qt6/QML) | shell framework hosting Clavis |
| cava | audio spectrum feeds `Services/AudioSpectrum.qml` |
| mako | notification daemon — **masked**, Clavis owns `org.freedesktop.Notifications` |
| awww | wallpaper daemon |
| wl-clipboard (`wl-paste`, `wl-copy`) | screenshot/capture helpers, clipboard |
| slurp, wf-recorder, gifski, ffmpeg | `scripts/capture/record.sh` |
| grim | screenshots (used for visual verification) |
| JetBrains Mono Nerd Font, Maple Mono NF CN | terminal + UI fonts |

### Clavis C++ plugins (built to `~/.local`, not in this repo)
`Clavis.{DesktopCards,Files,Gamma,I18n,Keyboard,Lyrics,Media,Niri,Runtime,Weather,Cava,WeatherMap,WindowPreview}`
under `~/.local/share/qt6/qml-next/Clavis`, plus `M3Shapes`
(`soramanew/m3shapes`), `libcava` (0.10.7 `cavacore.c`), and QtKeychain (WeatherMap).
`start-quickshell.sh` puts `qml-next` **first** in `QML2_IMPORT_PATH` and adds each plugin
dir to `LD_LIBRARY_PATH`. A module that "stopped loading" usually means one of these moved.

### Cross-platform CLI
| Package | Purpose |
|---------|---------|
| neovim ≥0.12 | editor (`neovim-ppa/stable` on Ubuntu) |
| kitty ≥0.38 | terminal |
| fish, yazi, mpv, bat, figlet, imv, zellij | shell tooling |
| ripgrep, nodejs, clang/make/cmake | nvim LSP + build toolchain |
| `key` (key-cli, pipx) | Clavis task CLI: `key ipc`, `key clipboard`, `key sysmon` |
| qt6-lottie | **not built** → animated weather icons fall back to static SVG |

### Python
`requests` (lyrics/weather APIs), `mutagen` (audio metadata); everything else stdlib.

## Environment & Config

| Repo path | Local path |
|-----------|-----------|
| `config/niri/` | `~/.config/niri/` |
| `config/quickshell/` | `~/.config/quickshell/` (own git repo) |
| `config/clavis/` | `~/.config/clavis/` (user settings) |
| `config/{kitty,mpv,nvim,fish,yazi,cava,imv,zellij,bat,neovide,figlet}/` | `~/.config/<same>/` |
| `config/aerospace/aerospace.toml` | `~/.aerospace.toml` |
| `config/sketchybar/` | `~/.config/sketchybar/` |
| `home/.pi/` | `~/.pi/` |

Key env vars:
```bash
EDITOR=nvim                                   # fish/config.fish
BUN_INSTALL=$HOME/.bun                        # bun runtime path
AVANTE_OPENCODE_API_KEY                       # nvim avante.nvim provider (set in ~/.config, not committed)
QML2_IMPORT_PATH / LD_LIBRARY_PATH            # injected by start-quickshell.sh
DOTFILES_PKG_MANAGER                          # set by bootstrap.sh for install.py
```
Out-of-repo but required at runtime (currently **not** tracked in this repo):
`~/.config/systemd/user/clavis-clipboard.service` (`key clipboard watch`) and the
`mako.service` mask.

## Testing Strategy

- **Only automated test** in the repo: `config/quickshell/scripts/media/test_title_parser.py`
  (unittest; run with `pytest` or `python3 -m unittest`). No coverage target, no CI for dotfiles.
- **Clavis** has its own lint/format/build pipeline (`scripts/dev/check.sh`); run it from
  `~/.config/quickshell` after QML edits — it is the closest thing to a compile check.
- **Visual verification** for UI changes: restart `quickshell-init.service`, check
  `journalctl --user -u quickshell-init.service -b` for QML errors, then `grim` a crop.
  Pixel-histogram colour checks (`magick ... histogram:info:`) are a cheap way to assert a
  theme colour actually rendered.
- Per-tool self-validation: `kitty --debug-config`, `nvim --headless '+checkhealth'`,
  `niri msg outputs`, `python3 -m py_compile` for scripts.
- Expect the shell to log benign warnings (`qt.qpa.services` notification registration,
  missing `display-color.json`/`dock.json` on first run, geo-IP weather location).

## Deployment

- Target is a **single personal Arch Linux** machine (pacman preferred; apt/dnf fallbacks
  in `install.py`). `bootstrap.sh` is Linux-only; there are no Windows scripts any more.
- Deploy to a new machine: `./bootstrap.sh` (interactive) or `./restore-config.sh`
  (non-interactive, `.bak` backups). Verify the Clavis side separately — plugin binaries
  in `~/.local` are **not** part of this repo and must be rebuilt.
- The shell runs as a **systemd user unit** (`quickshell-init.service`) started from
  `config/niri/config.kdl`; it may race Wayland readiness on login, so it needs a restart
  on failure rather than a one-shot start.
- No Docker, no package publishing from this repo.

### Licensing
`README.md` states MIT, but `config/quickshell/` is derived from GPL-3.0 code: it carries
its own `LICENSE` (GPL-3.0) and `licenses/` holds GPL-3.0 / MIT / Apache-2.0 / MPL-2.0
third-party texts (caelestia-shell, HyDE, end-4-dots-hyprland, BreezyWeather, M3Shapes,
Meteocons, matugen-themes, qml-niri, Zen Browser, …). Treat the repo as **mixed
MIT / GPL-3.0**: any redistribution must keep `config/quickshell/LICENSE` and the
`licenses/` attributions intact. When adding third-party assets, add the license text to
`config/quickshell/licenses/` and document it in `licenses/README.md`.

## Known Gaps & Gotchas

1. **`home/.pi/agent/byok.json` is tracked and contains a non-empty `apiKey`.** Untrack it
   and rotate the key; add it to `.gitignore` (auth/models-store/settings/sessions already are).
2. **`sync-config.sh` deletes `config/<dir>` before checking the source exists.** Stale
   entries in `CONFIG_DIRS` (currently `vscode`, which no longer exists) silently delete
   repo content. Remove entries when a tool is dropped.
3. **`install.py` is missing `cava`, `imv`, `zellij`** although `sync-config.sh` /
   `restore-config.sh` handle them — the installer can't select them.
4. **`start-quickshell.sh` hardcodes `/home/eunoia`** in `QML2_IMPORT_PATH` and
   `CLAVIS_NEXT_DIR`; replace with `$HOME` before sharing the repo.
5. **`sync-config.sh` overwrites the repo copy wholesale** and then `git checkout`s only
   `.gitignore`; any hand-edit made directly in `config/` is lost on the next sync. Edit the
   live tree, not the repo copy.
6. Stray debugging artifacts are committed at the repo root (`110_spot.png`,
   `110_spot_s.png`, ~2 MB) — safe to delete.
7. Live-only runtime files that no repo tracks: the clipboard systemd unit, the mako mask,
   `~/.face` (avatar fallback), and the `~/.local` plugin builds.