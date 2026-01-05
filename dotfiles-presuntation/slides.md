---
theme: dracula
# background: https://cover.sli.dev
title: 我的 Dotfiles
info: |
  ## 我的 Dotfiles 演示
  展示我的开发环境配置。
class: text-center
drawings:
  persist: false
transition: slide-left
mdc: true
---

# 我的 Dotfiles

<div v-motion
  :initial="{ y: 50, opacity: 0 }"
  :enter="{ y: 0, opacity: 1, transition: { duration: 800 } }">
  探索我的个性化开发环境
</div>

<div class="pt-12" v-motion
  :initial="{ y: 50, opacity: 0 }"
  :enter="{ y: 0, opacity: 1, transition: { delay: 400, duration: 800 } }">
  <span @click="$slidev.nav.next" class="px-2 py-1 rounded cursor-pointer" hover="bg-white/10">
    按空格键翻页 <carbon:arrow-right class="inline"/>
  </span>
</div>

---

# 什么是 Dotfiles？

<v-clicks>

- **配置文件**：存储软件应用程序设置的文件。
- **隐藏文件**：通常以点 (`.`) 开头，例如 `.bashrc`, `.gitconfig`, `.vimrc`。
- **个性化**：它们定义了你的工具的外观和行为。
- **Unix/Linux 传统**：源自 Unix 系统，但现在在各平台都很常见。

</v-clicks>

---

# 为什么要管理 Dotfiles？

<div class="grid grid-cols-2 gap-4">

<div>

### 不管理的问题

<v-clicks>

- 😞 **配置丢失**：系统崩溃或重装意味着丢失多年的调整。
- 😫 **不一致**：不同机器上的设置不同（家庭 vs 工作）。
- 😕 **难以分享**：很难向他人展示你的酷炫设置。

</v-clicks>

</div>

<div>

### GitHub + 同步的好处

<v-clicks>

- 💾 **备份**：云端安全存储。
- 🔄 **同步**：保持所有机器同步。
- 📜 **版本控制**：跟踪更改，回滚错误。
- 🤝 **分享**：帮助社区并向他人学习。

</v-clicks>

</div>

</div>

---

# 我的 Neovim 配置

基于 **lazy.nvim** 的现代化、快速且美观的配置。

<div class="flex justify-center items-center h-60 gap-4">
  <div class="text-6xl" v-motion
    :initial="{ x: -50, opacity: 0 }"
    :enter="{ x: 0, opacity: 1, transition: { delay: 100 } }">🚀</div>
  <div class="text-6xl" v-motion
    :initial="{ y: 50, opacity: 0 }"
    :enter="{ y: 0, opacity: 1, transition: { delay: 300 } }">✨</div>
  <div class="text-6xl" v-motion
    :initial="{ x: 50, opacity: 0 }"
    :enter="{ x: 0, opacity: 1, transition: { delay: 500 } }">🎨</div>
</div>

---

# 核心特性

<div class="grid grid-cols-2 gap-4 text-sm">

<v-click>

### 📦 插件管理
使用 `lazy.nvim` 高效管理，支持按需加载以提高速度。

</v-click>

<v-click>

### 🎨 美观的 UI
集成 `Catppuccin (Mocha)` 主题，`lualine` 状态栏和 `barbar` 标签栏。

</v-click>

<v-click>

### 🧠 智能补全
高性能 `blink.cmp` 引擎，支持 LSP、Snippets 和 Copilot。

</v-click>

<v-click>

### 🤖 AI 辅助
深度集成 **GitHub Copilot** 和 **CodeCompanionChat**。

</v-click>

<v-click>

### 🛠️ LSP 与格式化
通过 `Mason` 和 `conform.nvim` 开箱即用支持 Rust, Python, Lua 等。

</v-click>

<v-click>

### 🏃 代码运行
使用 `code-runner.nvim` 一键运行代码。

</v-click>

</div>

---

# 文件结构

清晰且易于维护的结构。

```text {all|2|4-9|10-18}
~/.config/nvim
├── init.lua                # 入口文件
├── lazy-lock.json          # 锁定文件
├── lua
│   ├── config              # 核心配置
│   │   ├── keymap.lua      # 快捷键
│   │   ├── lazy.lua        # Lazy 配置
│   │   └── ...
│   └── plugins             # 插件
│       ├── ai.lua          # AI (Copilot)
│       ├── completion.lua  # blink.cmp
│       ├── lsp.lua         # LSP & Formatter
│       ├── ui.lua          # UI 插件
│       └── ...
└── snippets                # 自定义片段
```

---

# 快捷键

Leader 键: `Space`

<div class="grid grid-cols-2 gap-10">

<div v-click>

### 🖥️ 窗口管理

| 按键 | 描述 |
| --- | --- |
| `<C-h/j/k/l>` | 窗口导航 |
| `<C-Arrow>` | 调整窗口大小 |
| `<leader>to` | 切换终端 |

### 📁 文件

| 按键 | 描述 |
| --- | --- |
| `<leader>nto` | 打开 NvimTree |
| `<leader>l` | Lazy 管理器 |

</div>

<div v-click>

### 🏃 代码运行

| 按键 | 描述 |
| --- | --- |
| `<leader>rr` | 运行代码 |
| `<leader>rf` | 运行文件 |
| `<leader>rp` | 运行项目 |

### 🤖 AI

| 按键 | 描述 |
| --- | --- |
| `<leader>coc` | Copilot 对话 |

</div>

</div>

---
layout: center
class: text-center
---

# 谢谢！

在 GitHub 上查看我的 dotfiles。

[GitHub 仓库](https://github.com/yourusername/dotfiles)
