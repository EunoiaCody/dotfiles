# My Neovim Config

```

███╗   ██╗███████╗ ██████╗ ███╗   ██╗ ██████╗ ██╗ █████╗ 
████╗  ██║██╔════╝██╔═══██╗████╗  ██║██╔═══██╗██║██╔══██╗
██╔██╗ ██║█████╗  ██║   ██║██╔██╗ ██║██║   ██║██║███████║
██║╚██╗██║██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██║██╔══██║
██║ ╚████║███████╗╚██████╔╝██║ ╚████║╚██████╔╝██║██║  ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═╝

```

## 🚀 简介 (Introduction)

这是一个基于 [lazy.nvim](https://github.com/folke/lazy.nvim) 的现代化 Neovim 配置，旨在提供快速、美观且功能强大的开发环境。配置结构清晰，易于维护和扩展。

## ✨ 特性 (Features)

- 📦 **插件管理**: 使用 `lazy.nvim` 进行高效的插件管理，支持按需加载。
- 🎨 **美观 UI**: 集成 `Catppuccin` (Mocha) 主题，配合 `lualine` 状态栏和 `barbar` 标签栏，提供优雅的视觉体验。
- 🧠 **智能补全**: 使用高性能的 `blink.cmp` 引擎，替代传统的 nvim-cmp，支持 LSP、Snippets 和 Copilot 补全。
- 🤖 **AI 辅助**: 深度集成 GitHub Copilot 和 CodeCompanionChat，提供强大的 AI 编程助手和对话功能。
- 🌲 **文件浏览**: 使用 `nvim-tree` 进行高效的文件系统管理。
- 🛠️ **LSP 支持**: 通过 `Mason` 和 `nvim-lspconfig` 提供开箱即用的 LSP 支持 (Rust, Python, Lua, C++, TS/JS, Vue 等)。
- 💅 **代码格式化**: 使用 `conform.nvim` 自动格式化代码，支持多种语言 (Stylua, Black, Rustfmt, Prettier 等)。
- 🏃 **代码运行**: 集成 `code-runner.nvim`，支持一键运行多种语言代码。
- ⌨️ **快捷键**: 精心设计的快捷键映射，配合 `which-key` 提供按键提示。

## ⚡️ 依赖 (Requirements)

- Neovim >= 0.9.0
- Nerd Font (推荐 JetBrainsMono Nerd Font 或 Hack Nerd Font)
- Git
- Rippergrep (用于文件搜索)
- GCC/Clang (用于编译 Treesitter parsers)
- Node.js / Python / Cargo (用于安装各种 LSP 和 Formatter)

## 📂 目录结构 (File Structure)

```text
~/.config/nvim
├── init.lua                # 配置入口文件
├── lazy-lock.json          # 插件版本锁定文件
├── lua
│   ├── config              # 核心配置目录
│   │   ├── keymap.lua      # 通用快捷键映射
│   │   ├── lazy.lua        # 插件管理器配置
│   │   ├── nvim-config.lua # Neovim 基础选项 (行号, tab 等)
│   │   ├── neovide-config.lua # Neovide 专用配置
│   │   └── vue-config.lua  # Vue 开发相关配置
│   └── plugins             # 插件配置目录
│       ├── ai.lua          # AI 插件 (Copilot, CodeCompanion)
│       ├── completion.lua  # 补全插件 (blink.cmp)
│       ├── lsp.lua         # LSP & Formatter (Mason, Conform)
│       ├── ui.lua          # 界面插件 (Lualine, Barbar, Icons)
│       ├── treesitter.lua  # 语法高亮
│       ├── code-runner.lua # 代码运行
│       └── ...
└── snippets                # 自定义代码片段
```

## 🎹 常用快捷键 (Keymaps)

Leader Key: `Space`

### 🪟 窗口管理
| 快捷键 | 描述 |
| --- | --- |
| `<C-h/j/k/l>` | 在左/下/上/右窗口间导航 |
| `<C-Arrow>` | 调整窗口大小 |
| `<leader>to` | 打开/关闭浮动终端 (ToggleTerm) |

### 📁 文件与侧边栏
| 快捷键 | 描述 |
| --- | --- |
| `<leader>nto` | 打开文件树 (NvimTree) |
| `<leader>ntc` | 关闭文件树 |
| `<leader>l` | 打开 Lazy 插件管理器面板 |

### 🏃 代码运行
| 快捷键 | 描述 |
| --- | --- |
| `<leader>rr` | 运行当前代码 |
| `<leader>rf` | 运行当前文件 |
| `<leader>rft` | 在新标签页运行当前文件 |
| `<leader>rp` | 运行项目 |
| `<leader>rc` | 关闭运行窗口 |

### 🤖 AI 助手
| 快捷键 | 描述 |
| --- | --- |
| `<leader>coc` | 打开 Copilot Chat 对话框 |

### 📝 编辑操作
| 快捷键 | 描述 |
| --- | --- |
| `j/k` | 更好的多行移动 (支持自动换行) |
| `<C-c>` | 复制选中内容到系统剪贴板 |
| `<C-v>` | 从系统剪贴板粘贴 |

## 🧩 主要插件列表

### Core
- **lazy.nvim**: 现代化的插件管理器
- **plenary.nvim**: 许多 Lua 插件的依赖库
- **lazydev.nvim**: Neovim Lua 开发配置

### UI & Theme
- **catppuccin**: 默认主题 (Mocha flavor)
- **lualine.nvim**: 底部状态栏
- **barbar.nvim**: 顶部标签栏
- **nvim-web-devicons**: 文件图标支持
- **nvim-tree.lua**: 文件资源管理器
- **which-key.nvim**: 快捷键提示

### Coding
- **blink.cmp**: 高性能自动补全引擎
- **nvim-lspconfig**: LSP 配置集合
- **mason.nvim**: LSP/DAP/Linter/Formatter 安装器
- **conform.nvim**: 轻量级代码格式化工具
- **nvim-treesitter**: 语法高亮与解析
- **code-runner.nvim**: 代码运行工具
- **error-lens.nvim**: 行内错误显示

### AI
- **copilot.vim**: GitHub Copilot 官方插件
- **codecompanion.nvim**: AI 聊天与辅助工具
