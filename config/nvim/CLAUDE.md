# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A modular Neovim configuration built on **lazy.nvim**, targeting **Neovim 0.12** (uses `vim.lsp.config()` / `vim.lsp.enable()` APIs). Optimized for web development (Vue/TypeScript) with Chinese-language UI descriptions. Theme: Catppuccin Mocha.

## Architecture

```
init.lua → requires in order:
  config.nvim-config    (vim options, leader/localleader: <space>)
  config.keymap         (keymaps, leader: <space>)
  config.neovide-config (GUI font/scaling)
  config.lazy           (lazy.nvim bootstrap, imports lua/plugins/*)
  config.lsp-config     (vim.lsp.config overrides, loaded before plugins)
  config.plugins-config (post-load: toggleterm, conform, lualine, notify)
  config.vue-config     (Vue/TS LSP forwarding via vtsls)
```

Each file in `lua/plugins/` is a lazy.nvim spec (auto-imported). Each returns a plugin table or list of tables. Add a new plugin by creating a new file there.

`lua/config/plugins-config.lua` handles setup for plugins that need imperative config (conform format-on-save, terminal keymaps, lualine, notify). Catppuccin setup is handled in `lua/plugins/colerscheme.lua` via lazy.nvim spec with a `config` function — `setup()` must be called before `colorscheme`.

## Key Technical Details

- **Completion**: blink.cmp (not nvim-cmp). Sources: LSP → path → snippets (LuaSnip) → buffer. Preset: `enter`. No copilot source (removed).
- **LSP**: Uses Neovim 0.12's `vim.lsp.config()` / `vim.lsp.enable()` API. Mason + mason-lspconfig + nvim-lspconfig provide defaults, automatic `vim.lsp.enable()` for installed servers. Vue/TS uses vtsls with `@vue/typescript-plugin` injection (`vue-config.lua`).
- **Mason must be `lazy = false`**: Mason is loaded at startup (not lazy) so that mason-lspconfig's `automatic_enable` can correctly scan installed servers. If Mason is lazy-loaded, LSP servers won't auto-enable on first file open.
- **LSP config flow**: `vim.lsp.config()` in `lsp-config.lua` / `vue-config.lua` only registers config overrides (safe to call early). `vim.lsp.enable()` is called by mason-lspconfig when a file is opened. Do **not** call `vim.lsp.enable()` manually for Mason-managed servers — mason-lspconfig handles it.
- **Formatting**: conform.nvim on `BufWritePre`. Formatters: stylua (Lua), black+isort (Python), rustfmt (Rust), prettierd (TS/JS), clang-format (C++). `:Format` command for manual range formatting.
- **Treesitter**: Custom injection directives in `plugins/treesitter.lua` for Neovim 0.12+ (`set-lang-from-mimetype!`, `set-lang-from-info-string!`, `downcase!`). Uses `unwrap_capture` pattern to handle 0.12 capture arrays. `highlight/indent` config removed from `configs.setup()` — handled natively by 0.12.
- **AI**: codecompanion.nvim (Chat) + avante.nvim (inline completion/edit, uses opencode go API). Avante provider: `opencode` via `__inherited_from = "openai"`, endpoint `https://opencode.ai/zen/go/v1`, model `glm-5.1`. API key env: `AVANTE_OPENCODE_API_KEY`.
- **Multi-cursor**: Custom `multicursor.nvim` config in `plugins/edit.lua` with mouse support and `<up>/<down>` cursor addition.
- **Terminal**: ToggleTerm. Exit via `<esc>` or `jk`. Window nav (`<C-h/j/k/l>`) works in terminal mode.
- **Code runner**: `<leader>rr/rf/rp/rc` — code-runner.nvim.
- **Avante keymaps**: `<leader>aa` (Ask), `<leader>ae` (Edit), `<leader>ar` (Refresh).
- **Markdown preview**: markview.nvim (not render-markdown.nvim, which was removed). Config in `plugins/markdown-preview.lua`. Must be `lazy = false` (per markview docs, it's already internally lazy-loaded). Supports hybrid mode in normal. File types: markdown, codecompanion, quarto. Avante.nvim depends on markview.nvim as its markdown renderer.
- **Noice**: nvim-cmp dependency removed. No `cmp.entry.get_documentation` override.
- **pumborder**: Set to `"rounded"` in nvim-config.lua (Neovim 0.12 feature).

## Conventions

- Keymap descriptions are in Chinese (简体中文).
- Plugin specs go in `lua/plugins/`, one file per concern.
- Colorscheme is set via lazy.nvim spec in `colerscheme.lua`: `catppuccin` plugin with `priority = 1000`, `lazy = false`, `config` function calls `setup()` then `colorscheme catppuccin-mocha`. Do NOT set colorscheme in `plugins-config.lua`.
- `lazy-lock.json` pins plugin versions — do not edit manually.
- `noice.nvim` does NOT depend on `hrsh7th/nvim-cmp` — this project uses blink.cmp.
- Leader key and localleader are both `<space>`, set in `nvim-config.lua` and `lazy.lua`.
- When adding new Mason LSP servers: just `:MasonInstall <server>`, restart Neovim. No manual `vim.lsp.enable()` needed — mason-lspconfig auto-enables installed servers.