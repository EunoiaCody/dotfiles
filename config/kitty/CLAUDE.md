# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Kitty terminal emulator configuration (`~/.config/kitty/`). Not a codebase — a dotfiles config directory.

## Files

- **`kitty.conf`** — Main config (~2800 lines). Ships as a full reference with most options commented out. Active (uncommented) settings are sparse: font family/size, cursor trail, window decorations, tab bar style, background opacity/blur, and OS tweaks. Uses vim fold markers (`{{{`/`}}}`) for section navigation.
- **`current-theme.conf`** — Catppuccin Mocha color theme. Auto-managed by `kitten themes`. The `# BEGIN_KITTY_THEME` / `# END_KITTY_THEME` block in `kitty.conf` includes this file.

## Editing Conventions

- Active settings sit directly below their section headers; everything else is commented-out reference text. To enable an option, uncomment the line — do not duplicate it.
- The file uses `# vim:fileencoding=utf-8:foldmethod=marker` — respect vim fold markers when navigating.
- Theme is managed via the `include current-theme.conf` directive at the top; do not hardcode colors into `kitty.conf`.

## Useful Commands

- Apply config changes: `killall -SIGUSR1 kitty` (or just close/reopen terminals)
- Theme switching: `kitten themes`
- Font picker: `kitten choose-fonts`
- Debug config: `kitty --debug-config` — shows all resolved settings including defaults
- Check a single option: `kitty @get-colors` / `kitty @ --help` (requires `allow_remote_control` enabled)