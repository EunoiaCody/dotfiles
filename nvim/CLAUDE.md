# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A modular Neovim configuration built on **lazy.nvim**, targeting **Neovim ≥ 0.9.0** (uses 0.11+ APIs like `vim.lsp.config()`). Optimized for web development (Vue/TypeScript) with Chinese-language UI descriptions. Theme: Catppuccin Mocha.

## Architecture

```
init.lua → requires in order:
  config.nvim-config    (vim options, tab/indent settings)
  config.keymap         (leader: <space>, localleader: \)
  config.neovide-config (GUI font/scaling)
  config.lazy           (lazy.nvim bootstrap, imports lua/plugins/*)
  config.plugins-config (post-load: toggleterm, conform, lualine, catppuccin, notify)
  config.vue-config     (Vue/TS LSP forwarding via vtsls)
```

Each file in `lua/plugins/` is a lazy.nvim spec (auto-imported). Each returns a plugin table or list of tables. Add a new plugin by creating a new file there.

`lua/config/plugins-config.lua` handles setup for plugins that need imperative config (conform format-on-save, terminal keymaps, catppuccin, lualine, notify). Plugin specs with `config` functions handle their own setup in-tree.

## Key Technical Details

- **Completion**: blink.cmp (not nvim-cmp). Sources: copilot → LSP → path → snippets (LuaSnip) → buffer. Preset: `enter`.
- **LSP**: Mason + mason-lspconfig + nvim-lspconfig. Vue/TS uses vtsls with `@vue/typescript-plugin` injection (`vue-config.lua`).
- **Formatting**: conform.nvim on `BufWritePre`. Formatters: stylua (Lua), black+isort (Python), rustfmt (Rust), prettierd (TS/JS), clang-format (C++). `:Format` command for manual range formatting.
- **Treesitter**: Custom injection directives in `plugins/treesitter.lua` for Neovim 0.12+ (`set-lang-from-mimetype!`, `set-lang-from-info-string!`, `downcase!`).
- **Multi-cursor**: Custom `multicursor.nvim` config in `plugins/edit.lua` with mouse support and `<up>/<down>` cursor addition.
- **Terminal**: ToggleTerm. Exit via `<esc>` or `jk`. Window nav (`<C-h/j/k/l>`) works in terminal mode.
- **Code runner**: `<leader>rr/rf/rp/rc` — code-runner.nvim.

## Conventions

- Keymap descriptions are in Chinese (简体中文).
- Plugin specs go in `lua/plugins/`, one file per concern.
- Colorscheme is set twice: lazy.nvim install fallback (`habamax`) and runtime (`catppuccin-mocha` in plugins-config.lua).
- `lazy-lock.json` pins plugin versions — do not edit manually.