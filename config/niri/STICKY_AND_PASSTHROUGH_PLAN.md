# Plan: niri 窗口「固定最上层 + 鼠标穿透」分析与实施方案

## 概述

分析 niri compositor 是否支持窗口固定在最上层（always-on-top / sticky）以及鼠标穿透（click-through / input passthrough），并提供可行的实现路径。当前 niri 原生不支持这两个特性，但有多种方案可达成目标。

---

## 调研发现

### 🔴 窗口固定最上层 — 原生不支持，但有 PR 在开发中

niri FAQ 明确写道：
> "Can I make a window sticky / pinned / always on top / appear on all workspaces?"
> **"Not yet, follow/upvote this issue."**

**进行中的 PR**：[niri#3302](https://github.com/YaLTeR/niri/pull/3302) — `Add open-sticky window rule for sticky floating windows across workspaces`
- 作者：AtefR
- 状态：Open (in progress)，有 merge conflicts
- 功能：
  - `open-sticky` 窗口规则（自动隐含 `open-floating`）
  - `toggle-window-sticky` 绑定动作
  - `is-sticky` 匹配器（用于 window-rule）
  - sticky 窗口渲染在全屏窗口之上
  - 取消 sticky 时恢复原始位置/工作区
- 还有另一个 PR [#3205](https://github.com/YaLTeR/niri/pull/3205) 功能更全（支持非浮动窗口 pin）

### 🔴 鼠标穿透 — 对普通窗口不可能，对 layer-shell 可以

| 窗口类型 | 能否鼠标穿透 | 说明 |
|---------|------------|------|
| **普通窗口** (xdg-shell) | ❌ 不可能 | Wayland 协议不支持；niri 没有相关规则 |
| **layer-shell** (overlay/top层) | ✅ 可以 | 应用可通过 `zwlr_layer_surface_v1.set_keyboard_interactivity(0)` 设为 `none` 模式，实现鼠标穿透 |
| **backdrop 内的 layer** | ✅ 可以 | niri `layer-rule { place-within-backdrop true }` 会让该层忽略所有输入 |

---

## 受影响文件

- `~/.config/niri/config.kdl` — 主配置，可能需要添加 include 或规则
- `~/.config/niri/windows-rule.kdl` — 窗口规则，添加 sticky 相关规则
- `~/.config/niri/binds.kdl` — 快捷键绑定，添加 toggle-sticky 绑定
- `~/.config/niri/scripts/` — 可能新增 IPC 脚本
- （构建相关）niri 源码或 PKGBUILD

---

## 分阶段计划

### 阶段 1：实现「窗口固定最上层」

有三个子方案，按推荐度排序：

#### 方案 A（推荐）：自行编译含 sticky PR 的 niri

- [ ] 1.1 Clone niri 源码并切换到 PR #3302 分支
  ```bash
  git clone https://github.com/YaLTeR/niri
  cd niri
  git fetch origin pull/3302/head:pr-sticky-windows
  git checkout pr-sticky-windows
  ```
- [ ] 1.2 解决与 main 的 merge conflicts（已知 `src/layout/mod.rs` 和 `src/layout/monitor.rs` 有冲突）
- [ ] 1.3 编译安装（Arch: `cargo build --release` 或修改 PKGBUILD）
- [ ] 1.4 在 `windows-rule.kdl` 中添加规则：
  ```kdl
  window-rule {
      match app-id="your-app-id"
      open-sticky true
  }
  ```
- [ ] 1.5 在 `binds.kdl` 中添加切换快捷键：
  ```kdl
  Mod+Shift+P { toggle-window-sticky; }
  ```
- [ ] 1.6 测试：浮动窗口是否跨工作区保持可见

#### 方案 B（临时方案）：IPC 脚本模拟 sticky

- [ ] 1.7 编写 Python/Rust 脚本，监听 `niri msg event-stream`
- [ ] 1.8 监听 `WorkspacesChanged` 事件，当工作区切换时
- [ ] 1.9 通过 `niri msg action move-window-to-workspace` 将目标窗口移动到当前工作区
- [ ] 1.10 脚本放在 `~/.config/niri/scripts/sticky-follow.py`
- [ ] 1.11 在 `config.kdl` 中添加 `spawn-at-startup` 启动脚本

#### 方案 C：等待官方合并

- [ ] 1.12 订阅 PR #3302，等待合并到 main 并发布新版本
- [ ] 1.13 更新 niri 包后，使用方案 A 中的配置

### 阶段 2：实现「鼠标穿透」

根据使用场景，有两个子方案：

#### 方案 A：使用 layer-shell 程序（推荐用于壁纸/桌面组件等场景）

- [ ] 2.1 确认目标程序的类型：
  - 如果是壁纸/桌面组件 → 使用 `layer-rule` 配合 `place-within-backdrop true`
  - 如果是悬浮信息面板 → 需要程序自身创建 layer-shell surface 并设置 `keyboard_interactivity = None`
- [ ] 2.2 对于已有 layer-shell 程序，添加 niri 配置：
  ```kdl
  layer-rule {
      match namespace="^your-namespace$"
      place-within-backdrop true  // 放在 backdrop 里，自动忽略所有输入
  }
  ```
- [ ] 2.3 对于需要自定义的场景，编写一个简单的 layer-shell 客户端（使用 `wayland-client` + `wlr-layer-shell` 协议）

#### 方案 B：用透明 overlay 窗口（无法做到真正的鼠标穿透）

- [ ] 2.4 评估：Wayland 普通窗口不可能实现鼠标穿透，此方案只适用于 layer-shell
- [ ] 2.5 考虑替代方案：用 `opacity 0.01` + `open-focused false` 使窗口不可见且不抢焦点，但它仍会拦截鼠标事件

### 阶段 3：配置整合与验证

- [ ] 3.1 更新 `config.kdl`，确保 include 了新配置
- [ ] 3.2 重启 niri（`pkill niri` 或注销重新登录）
- [ ] 3.3 测试：
  - 目标窗口是否跨工作区保持最上层
  - 目标 layer 是否实现鼠标穿透
- [ ] 3.4 修正任何配置问题

---

## 风险与注意事项

| 风险 | 缓解措施 |
|------|---------|
| PR #3302 有 merge conflicts | 手动解决冲突；如太复杂则改用 IPC 脚本方案 |
| 自编译 niri 可能与系统包冲突 | 安装到 `/usr/local`，或用 `nix`/`cargo install` |
| IPC 脚本模拟 sticky 可能有延迟 | 事件流延迟通常在 1-2ms 内，可接受 |
| 鼠标穿透对普通窗口根本不可能 | 确认需求是否可用 layer-shell 替代；若不可行需放弃此需求 |
| niri 更新后自编译版本被覆盖 | 锁定包版本，或用自定义 PKGBUILD 跟踪 PR 分支 |
| PR #3302 的 sticky 窗口不能在全屏窗口之上（但最近更新已修复） | 已修复：sticky 窗口现在渲染在全屏之上 |

---

## 预计影响

- 新建文件：1-2 个（IPC 脚本、可能的 layer-shell 客户端）
- 修改文件：2-3 个（`windows-rule.kdl`、`binds.kdl`、可能 `config.kdl`）
- 构建：可能需要编译自定义 niri 版本

---

## 补充参考

- niri FAQ: https://github.com/YaLTeR/niri/wiki/FAQ
- niri Window Rules: https://github.com/YaLTeR/niri/wiki/Configuration:-Window-Rules
- niri Layer Rules: https://github.com/YaLTeR/niri/wiki/Configuration:-Layer-Rules
- PR #3302: https://github.com/YaLTeR/niri/pull/3302
- niri IPC 事件流: https://niri-wm.github.io/niri/IPC.html
- wlr-layer-shell 协议: https://wayland.app/protocols/wlr-layer-shell-unstable-v1
