# 计划：Untitled Plan

> 创建时间：7/18/2026, 3:44:07 PM
> 状态：审阅中

## 任务
我找到一个quickshell仓库，想要用他的配置来优化我的quicksell的AppLauncher，主要有以下几点：

1. 首次打开AppLauncher时，不会按打开APP的频率排序，要第二次打开才行
2. AppLauncher 不支持鼠标滚动，一页一页翻很费劲
3. AppLauncher 搜索没有动画

可能的解决方案：

1. 你来解决
2. 直接抄我说的仓库
3. 直接抄我说的仓库

仓库位置: `/home/eunoia/Development/caelestia-shell`

## ✅ PLAN COMPLETE

计划已写入 `PLAN_AppLauncher_Fixes.md`。以下是核心要点：

### 三个问题的根因总结

| # | 问题 | 根因 | 修复思路 |
|---|------|------|----------|
| 1 | 首次打开不按频率排序 | `LaunchTracker` 的 `frequencies` 通过异步 `FileView` 从磁盘加载，但 `AppPage` 不等它准备好就开始排序 — 此时频率全为 0 | 给 `LaunchTracker` 加 `ready` 信号，`AppPage` 的轮询 Timer 同时等待 `LaunchTracker.ready` |
| 2 | 不支持鼠标滚轮 | 三个 ListView 都写了 `interactive: false` + `smoothWheelEnabled: false` — **实际上 `StyledListView` 早就有完整的滚轮处理代码** | 移除这两个限制，启用已有的 `handleWheel()` 逻辑 |
| 3 | 搜索无动画 | `animateAppearance: false` + `animateMovement: false` 禁用了所有过渡。`StyledListView` 本来就定义了 `add`/`remove`/`move` 过渡 | 启用 + 参考 caelestia-shell 加一个 search→browse 状态切换的 crossfade |

### 文件改动量

- **修改 4 个文件**：`LaunchTracker.qml`、`AppPage.qml`、`WindowPage.qml`、`WallpaperPage.qml`
- **可能微调**：`StyledListView.qml`
- **净增 ~60 行代码**
- **不新建/不删除任何文件**

### 关键策略

- 不照搬 caelestia-shell（它用 C++ SQLite 插件同步加载，架构不同）
- 利用项目**已有的基础设施**（`StyledListView` 的滚轮处理、`ElementMoveAnimation`、`Appearance.animation.*` 令牌）
- 最小改动原则

请审阅计划。批准后我将进入执行模式，按 Phase 1→2→3→4 顺序实施。