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

# 我的工具箱

构建高效工作流的核心工具

<div class="grid grid-cols-2 gap-4 text-sm pt-4">

<v-click>

### 🐚 Shell & Terminal
- **Fish**: 智能提示，自动补全。
- **Kitty**: GPU 加速，极其流畅体验。

</v-click>

<v-click>

### 🖥️ 系统增强 (macOS)
- **Aerospace**: 类似 i3 的平铺式窗口管理器。
- **Sketchybar**: 高度可定制的状态栏。

</v-click>

<v-click>

### 📂 文件管理
- **Yazi**: 极速的终端文件管理器，支持图片预览和 Lua 插件。

</v-click>

<v-click>

### 🔧 其它
- **Nix**: 声明式包管理，确保环境一致性。
- **Bat**: `cat` 的现代化替代品，支持语法高亮。

</v-click>

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

# 为什么选择 Lazy.nvim?

<div class="grid grid-cols-2 gap-8 items-center">

<div>

- 🚀 **极速启动**：只在需要时加载插件（按键触发、命令触发、事件触发）。
- 📦 **强大的 UI**：直观的界面管理插件更新、安装和性能分析。
- 🔒 **锁定文件**：`lazy-lock.json` 确保团队或多设备间的插件版本一致。

</div>

<div class="bg-surface0 p-4 rounded-lg">

```lua
-- 示例：按需加载
{
  "nvim-neorg/neorg",
  ft = "norg", -- 仅在打开 .norg 文件时加载
  cmd = "Neorg", -- 或在执行 :Neorg 命令时加载
  config = true,
}
```

</div>

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

# 🎥 现场演示环节

让我们深入 Neovim，体验现代化的编辑工作流。

---

# 1. 启动与管理 (Startup & Management)

展示 Lazy.nvim 的极速启动和插件管理能力。

<div class="grid grid-cols-2 gap-8 mt-8">

<div>

### 🎯 关注点
- **启动时间**: 是否在 50ms - 100ms 级别？
- **插件概览**: 所有插件是否都正确加载或延迟加载？
- **更新日志**: UI 是否直观？

</div>

<div class="bg-black/20 p-4 rounded-lg border border-gray-700/50">

### ⌨️ 操作指引

1. 在终端运行 `nvim`。
2. 观察 **Dashboard** 底部显示的启动时间。
3. 按下 `<leader>l` 打开 **Lazy** 面板。
4. 按 `P` 查看 Profile (性能分析)。

</div>

</div>

---

# 2. 智能编码体验 (Intelligent Coding)

体验 LSP 和 blink.cmp 带来的流畅编写感。

<div class="grid grid-cols-2 gap-8 mt-8">

<div>

### 🎯 关注点
- **补全速度**: blink.cmp 的即时响应。
- **来源丰富**: LSP, Snippet, Buffer, Path 混合。
- **文档提示**: 悬停查看文档。

</div>

<div class="bg-black/20 p-4 rounded-lg border border-gray-700/50">

### ⌨️ 操作指引

1. 打开一个 Lua 文件 (如 `lua/plugins/ui.lua`)。
2. 输入 `local` 或插件名，观察补全列表。
3. 移动光标到变量上，按 `K` 查看文档悬停。
4. 故意写错语法，展示 LSP 实时诊断。

</div>

</div>

---

# 3. AI 赋能开发 (AI Powered)

与 GitHub Copilot 和 Chat 进行结对编程。

<div class="grid grid-cols-2 gap-8 mt-8">

<div>

### 🎯 关注点
- **Ghost Text**: 预测你的下一步代码。
- **Chat 上下文**: AI 能否理解当前文件内容。
- **代码解释**: 帮助理解复杂逻辑。

</div>

<div class="bg-black/20 p-4 rounded-lg border border-gray-700/50">

### ⌨️ 操作指引

1. 新起一行写注释 `-- Create a function to ...`，等待 Copilot 补全实现。
2. 选中一段代码。
3. 按 `<leader>coc` 打开 **Copilot Chat**。
4. 输入 `/explain` 让 AI 解释这段代码。

</div>

</div>

---

# 4. 高效导航 (Efficient Navigation)

在文件和窗口间如闪电般穿梭。

<div class="grid grid-cols-2 gap-8 mt-8">

<div>

### 🎯 关注点
- **文件树**: 直观的项目视图。
- **模糊查找**: 快速定位文件。
- **窗口移动**: 无需鼠标的流畅切换。

</div>

<div class="bg-black/20 p-4 rounded-lg border border-gray-700/50">

### ⌨️ 操作指引

1. 按 `<leader>nto` 侧边打开/关闭文件树。
2. (如果有) 使用 Telescope `<leader>ff` 查找文件。
3. 使用 `<leader>v` 或 `:vsp` 垂直拆分窗口。
4. 使用 `<C-h/l>` 在左右窗口间快速切换。

</div>

</div>

---
layout: center
class: text-center
---

# 谢谢！

在 GitHub 上查看我的 dotfiles。

[GitHub 仓库](https://github.com/yourusername/dotfiles)
