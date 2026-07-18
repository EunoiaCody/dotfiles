# 计划：修改 Mod+H/L 绑定为 consume-or-expel-window

> 创建时间：7/18/2026, 5:21:48 PM
> 批准时间：7/18/2026, 5:51:41 PM

## 任务
niri的Mod+h/l逻辑不对，应该是Mod+h/l使窗口加入左/右列

## Plan: 修改 Mod+H/L 绑定为 consume-or-expel-window

### Overview
将 `Mod+H` 和 `Mod+L`（以及对应的方向键绑定）从焦点移动操作 (`focus-column-left/right`) 改为窗口合并/分离操作 (`consume-or-expel-window-left/right`)。这样按 Mod+H 会将当前窗口合并到左侧列（或从左侧列分离），按 Mod+L 同理，实现用户期望的「窗口加入左/右列」行为。

### Affected Files
- `/home/eunoia/.config/niri/binds.kdl` — 修改 4 处 bind 的 action

### Step-by-Step Plan

#### Phase 1: 修改键盘绑定

**修改 HJKL 键绑定（第3行、第6行）**：
- [ ] `Mod+H` 从 `focus-column-left` 改为 `consume-or-expel-window-left`
- [ ] `Mod+L` 从 `focus-column-right` 改为 `consume-or-expel-window-right`

**修改方向键绑定（第9行、第12行）**：
- [ ] `Mod+Left` 从 `focus-column-left` 改为 `consume-or-expel-window-left`
- [ ] `Mod+Right` 从 `focus-column-right` 改为 `consume-or-expel-window-right`

**保持不变的绑定**：
- `Mod+J/K` (`focus-window-down/up`) — 列内垂直焦点移动，保持不变
- `Mod+Shift+H/L` (`move-column-left/right`) — 整列位置移动，保持不变
- `Mod+Shift+J/K` (`move-window-down/up`) — 列内窗口位置移动，保持不变

### 修改前后对比

| 按键 | 修改前 | 修改后 |
|------|--------|--------|
| `Mod+H` | `focus-column-left` | `consume-or-expel-window-left` |
| `Mod+L` | `focus-column-right` | `consume-or-expel-window-right` |
| `Mod+Left` | `focus-column-left` | `consume-or-expel-window-left` |
| `Mod+Right` | `focus-column-right` | `consume-or-expel-window-right` |

### 行为说明

- **Consume 方向**：当窗口是列中的活跃窗口（顶部位置），会将相邻列的窗口拉入当前列
- **Expel 方向**：当窗口在列底部，会将当前窗口踢出到相邻方向成为独立列
- 焦点始终跟随被操作的窗口，因此不影响后续操作

### Risks & Considerations

- **失去纯焦点移动能力**：修改后不再有仅移动焦点的列切换快捷键。如果需要，可以后续将 `focus-column-left/right` 绑定到其他按键（如 `Mod+Ctrl+H/L`），但不在此计划范围内
- **consume-or-expel 是双向操作**：它根据窗口在列中的位置决定是 consume 还是 expel，可能不完全等于「总是合并到左列」。如果实际使用中发现不符合预期，可以进一步调整为其他 action（如纯 `consume-window-into-column` 配合方向变体）

### Estimated Impact
- Files to modify: 1 (`binds.kdl`)
- Files to create: 0
- Files to delete: 0

---

PLAN COMPLETE