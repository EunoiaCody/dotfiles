# 计划：Untitled Plan

> 创建时间：7/15/2026, 10:33:02 AM
> 批准时间：7/15/2026, 10:36:31 AM

## 任务
在确认一下

全部交叉验证通过。以下是最终确认总结：

---

## ✅ v2 计划 — 最终确认

### 三层接口验证（全部通过）

**层级 1: Python → QML 数据桥** (`lyrics_fetcher.py`)

| 当前状态 | 新状态 | 过渡方案 |
|----------|--------|---------|
| 输出 `[{time, text}]` flat array | 输出 `{format, source, lines: [...], _legacy: [{time, text}]}` | `_legacy` 字段保底，旧消费者不崩溃 |
| 仅 QQ LRC + NetEase LRC | + NetEase YRC + QQ QRC | 优先级链：v2缓存 → YRC → QRC → LRC |

**层级 2: Sync Engine** (`Common/LyricsSyncEngine.qml`)

| 消费者 | 写入 | 读取 |
|--------|------|------|
| `LyricsContent.qml` | `playbackSeconds`（标准化为秒） | `activeLineIndex`, `activeWordIndex`, `activeWordProgress` |
| `Media.qml` | `playbackSeconds`（标准化为秒） | 同上 + 传给 `SpringLyricView` |
| Engine 内部 | — | 二分查找 + 自适应 Timer (50ms/100ms) |

**层级 3: SpringLyricView delegate** (关键改动)

| 位置 | 当前代码 | 新代码 |
|------|---------|--------|
| 行 259 | `required property string text` | `required property var modelData` |
| 行 359 | `text: lyricItem.text` | 通过 `root.lyricAt(index)` 获取，条件渲染 `Row+Repeater` 或单 `Text` |
| 行 243-248 | `Rotation { angle: root.tiltAngle }` | **删除** |
| 行 17 | `activeColor: "white"` | `activeColor: Appearance.colors.colPrimary` (`#b4befe`) |

### 注册清单
- 根 `qmldir` 新增一行：`singleton LyricsSyncEngine Common/LyricsSyncEngine.qml`
- 无需创建新目录（`Common/` 已存在）

### 执行顺序
```
T0 → T1-T4 → T5 → T7 → T8 → T9-T10 → F1-F4
```

---

**PLAN COMPLETE.** v2 计划已写入 `lyric-word-level-v2.md`，所有 v1 审查发现的问题均已修复。可以 `/plan approve` 开始执行。