# 逐字歌词支持工作计划 v2（修订版）

> **v2 修订说明**：修复了 v1 审查发现的 4 个严重问题：任务编号缺口（C1）、T5 类型不一致（C2）、position 单位验证缺失（C3）、格式过渡崩溃风险（C4）。同时修复了 4 个中等问题和 4 个小问题。详见文末 [Changelog](#changelog)。

## TL;DR

> **目标**: 为 Quickshell 的 DynamicIsland 歌词显示添加逐字歌词（karaoke 式）高亮支持，覆盖紧凑条带（42px）和展开面板（240px）两个 UI 面。
>
> **数据源**: 网易云 YRC + QQ音乐 QRC，降级到标准 LRC。
>
> **渲染**: Compact bar 用单行 `Row + Repeater + Text` 逐字变色；Expanded panel 用升级后的 `SpringLyricView`（移除 3D 倾斜，活跃行颜色改为 `Appearance.colors.colPrimary` / Catppuccin Lavender `#b4befe`）。
>
> **同步**: 统一 `LyricsSyncEngine`（QML `pragma Singleton`）——二分查找 + 字级进度 + 自适应 Timer（50ms/100ms）。
>
> **Estimated Effort**: Large
> **Parallel Execution**: YES — 5 Waves
> **Critical Path**: T0 (验证) → T1-T4 (Python) → T5 (Sync Engine) → T7-T8 (UI) → T9-T10 (边缘+优化) → Final QA

---

## Context

### Original Request
基于 SPlayer 歌词系统分析（`lyrics-analysis.md`），将当前 Quickshell 的纯行级歌词显示升级为逐字高亮（word-level karaoke highlighting）。

### Interview Summary
**Key Discussions**:
- UI 形态: **C — 两者都做**（compact bar 单行逐字 + expanded panel 多行逐字）
- 数据源: **YRC + QRC (Full)**（网易云 YRC + QQ音乐 QRC）
- Expanded panel: **一起升级**（SpringLyricView 改造后 Media.qml 自动受益）
- 活跃行颜色: **Catppuccin Mocha Lavender** (`#b4befe` = `Appearance.colors.colPrimary`)
- **不要 3D 倾斜**

### Research Findings
- `SpringLyricView` 已在 `Media.qml` 中使用（`lyricsContainer` 240px），不是未使用的资产
- `LyricsContent.qml`（compact bar，42px）使用 `StyledListView`，和 `Media.qml` 是两个独立的歌词消费者
- `Media.qml` 当前 sync 逻辑: 100ms Timer + `ListModel` + 线性扫描 `O(n)`；**position 未做单位转换**（直接比较 `player.position` 与秒级 `time`）
- `LyricsContent.qml` 当前 sync 逻辑: 100ms Timer + JS array + 线性扫描 `O(n)`；**有单位转换**（`rawPos > 100000 ? rawPos/1000000 : rawPos`）
- `SpringLyricView` 使用弹簧物理引擎（16ms Timer，`stepValue` 数值积分），支持 Y/Scale/Opacity 三维度动画 + 延迟级联

### Metis Review Gaps (all addressed)
- **Dimensional mismatch**: SpringLyricView 是多行滚动器，不能直接放入 42px compact bar。Plan 中 compact bar 使用独立的单行 `Row` delegate。
- **Text eliding**: `Row` 没有 `elide`。Plan 中 compact bar 使用上下文窗口截断（活跃字前后各 8 字 + "…"）。
- **Cache invalidation**: 旧缓存是 flat `[{time,text}]`。Plan 中引入 cache versioning (`v2/` 子目录)。
- **MPRIS position precision**: T0 验证单位后，T5 标准化为秒。
- **Two sync logics**: Plan 中统一到一个可复用的 `LyricsSyncEngine`（QML `pragma Singleton`）。
- **QML object proliferation**: Plan 中 compact bar 只渲染单行（~10-20 个 Text），expanded panel 渲染 12 行 × 平均 10 字 = ~120 个 Text。

---

## Work Objectives

### Core Objective
升级 Quickshell 歌词系统，支持从网易云 YRC 和 QQ音乐 QRC 获取逐字歌词，并在 compact bar（42px）和 expanded panel（240px）两个 UI 面上实现逐字高亮渲染。

### Concrete Deliverables
- `scripts/media/lyrics_fetcher.py` — 多源获取 + 多格式解析 + 统一输出 + 向后兼容过渡
- `Common/LyricsSyncEngine.qml` — `pragma Singleton`，二分查找 + 字级进度 + 自适应 Timer
- `Widgets/common/SpringLyricView.qml` — 移除 3D 倾斜 + 主题色 + 逐字 delegate
- `Modules/DynamicIsland/LyricsContent/LyricsContent.qml` — 数据模型升级 + 单行逐字 delegate
- `Modules/DynamicIsland/Media/Media.qml` — 数据模型升级 + 集成 LyricsSyncEngine

### Definition of Done
- [ ] 播放任意网易云/YRC 歌曲，compact bar 显示逐字高亮（已唱字 `#b4befe`，未唱字白色）
- [ ] 展开媒体面板，SpringLyricView 显示多行逐字高亮，活跃行 `#b4befe`
- [ ] 播放只有标准 LRC 的歌曲，两界面均正常降级为行级显示
- [ ] 快进/快退/暂停/恢复，歌词同步无跳变或漂移

### Must Have
- NetEase YRC 获取与解析
- QQ音乐 QRC 获取与解析
- 统一数据模型（`lines: [{text, time, words: [{word, startTime, endTime}]}]`）
- 二分查找歌词索引
- 字级进度计算
- Compact bar 单行逐字 delegate（上下文窗口截断策略）
- SpringLyricView 多行逐字 delegate
- 活跃字/行颜色 `#b4befe`
- 3D 倾斜完全移除
- 缓存版本控制（`v2/` 子目录）
- LRC 降级兼容
- 新旧格式过渡兼容（T4 输出同时含 `lines` 和 `_legacy` 字段）

### Must NOT Have (Guardrails)
- **不实现 TTML 解析** — 超出范围
- **不实现翻译/音译对齐显示** — 超出范围
- **不实现本地文件歌词扫描** — 超出范围
- **不修改 DynamicIsland 紧凑模式的高度** — compact bar 保持 42px
- **不引入新的 Python 依赖** — 只用标准库（`xml.etree.ElementTree` 是标准库，可用）
- **不修改 Media.qml 的封面/频谱/控制面板布局** — 只改歌词区域

---

## T0: 前置验证 — MPRIS Position 单位确认

> **在开始任何实现之前**，必须确认 `player.position` 的实际单位。这决定了后续所有 sync 逻辑的正确性。

**What to do**:
- 在 `Media.qml` 的 Timer 中添加临时 `console.log`：输出 `player.position` 的原始值
- 播放一首歌 5 秒，观察日志值：
  - 如果输出约 `5,000,000` → 微秒（需除以 1,000,000）
  - 如果输出约 `5.0` → 秒（无需转换）
  - 如果输出约 `5,000` → 毫秒（需除以 1,000）
- 同时在 `LyricsContent.qml` 中对比验证

**Output**: 记录确认后的单位，作为 T5 实现的依据。

**Evidence**: `.sisyphus/evidence/t0-position-unit.txt`

---

## Execution Strategy

### Task Renumbering (v2)

v1 存在 T8/T10 缺口。v2 重新编号为顺序 T1-T10：

| v1 ID | v2 ID | Description |
|-------|-------|-------------|
| T1 | T1 | NetEase YRC 获取 |
| T2 | T2 | YRC + LRC 增强解析 |
| T3 | T3 | QQ音乐 QRC 获取与解析 |
| T4 | T4 | 统一输出格式 + 缓存版本 + 向后兼容 |
| T5 | T5 | **LyricsSyncEngine** (QML `pragma Singleton`) |
| T6 | T6 | Python fetcher 集成测试 (e2e) |
| T7 | T7 | SpringLyricView 改造 + Media.qml 适配 |
| T9 | T8 | LyricsContent.qml compact bar 单行逐字 |
| T11 | T9 | 快进/暂停/恢复 边缘场景处理 |
| T12 | T10 | 性能调优 + eliding 策略完善 |

### Parallel Execution Waves

```
Wave 1 (Foundation — Python data layer, 4 parallel tasks):
├── T1: NetEase YRC 获取端点验证与请求
├── T2: YRC 解析器 + LRC 增强格式解析
├── T3: QQ音乐 QRC 获取与解析
└── T4: 统一输出格式 + 缓存版本控制 + 向后兼容过渡

Wave 2 (Core engine — sync logic, 2 parallel tasks):
├── T5: LyricsSyncEngine Singleton（二分查找 + 字级进度 + 自适应 Timer）
└── T6: Python fetcher 集成测试（end-to-end）

Wave 3 (Shared component — SpringLyricView + Media.qml):
└── T7: 移除 3D 倾斜 + 主题色 + 逐字 delegate + Media.qml 适配

Wave 4 (UI integration — compact bar):
└── T8: LyricsContent.qml compact bar 单行逐字

Wave 5 (Polish + integration, 2 parallel tasks):
├── T9: 快进/暂停/恢复 边缘场景处理
└── T10: 性能调优 + eliding 策略完善

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA (unspecified-high)
└── F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: T0 → T1-T4 → T5 → T7 → T8 → T9-T10 → F1-F4 → user okay
Parallel Speedup: ~55% faster than sequential
```

### Dependency Matrix (v2)

| Task | Blocked By | Blocks |
|------|-----------|--------|
| T0 | — | T5 (position 单位确认) |
| T1 | — | T2, T6 |
| T2 | T1 | T4, T6 |
| T3 | — | T4, T6 |
| T4 | T2, T3 | T5, T6, T7, T8 |
| T5 | T0, T4 | T7, T8, T9 |
| T6 | T1-T4 | — |
| T7 | T4, T5 | — |
| T8 | T4, T5 | — |
| T9 | T5, T7, T8 | — |
| T10 | T7, T8 | — |

### Agent Dispatch Summary

- **T0**: `quick` — 简单验证
- **Wave 1**: T1-T4 → `unspecified-high` (Python 开发)
- **Wave 2**: T5-T6 → `quick` (T5 QML) + `unspecified-high` (T6 e2e)
- **Wave 3**: T7 → `visual-engineering` (SpringLyricView + Media.qml)
- **Wave 4**: T8 → `visual-engineering` (LyricsContent compact bar)
- **Wave 5**: T9-T10 → `deep` (边缘) + `unspecified-high` (性能)
- **FINAL**: F1-F4 → `oracle`, `unspecified-high`, `unspecified-high`, `deep`

---

## TODOs

### T0. **MPRIS Position 单位验证**

**What to do**:
- 临时在 `Media.qml` Timer 中添加：`console.log("RAW POS:", root.player.position)`
- 启动 quickshell，播放歌曲，观察日志
- 同时在 `LyricsContent.qml` 中做同样验证
- 记录单位：微秒 (μs)、毫秒 (ms)、或秒 (s)

**Acceptance Criteria**:
- [ ] 确认 `player.position` 的实际单位
- [ ] 记录到 `.sisyphus/evidence/t0-position-unit.txt`

**Evidence to Capture**:
- [ ] 日志截图或输出

---

### T1. **NetEase YRC 端点验证与请求**

**What to do**:
- 测试两个候选 NetEase 端点：
  1. `http://music.163.com/api/song/lyric?os=pc&id={id}&lv=-1&kv=-1&tv=-1`（当前使用）
  2. `http://music.163.com/api/song/lyric?id={id}&lv=-1&tv=-1&yv=-1`（YRC 候选）
- 使用 `curl` 或 Python 测试 3-5 首不同歌曲（中文、日文、英文），确认 YRC 返回率和数据结构
- 如果以上端点均不返回 YRC，时间盒 30 分钟后暂停并向用户报告
- YRC 通常是 base64 编码的 JSON，需要先解码再解析
- 将 YRC 获取逻辑添加到 `fetch_netease()` 函数中

**Must NOT do**:
- 不要修改解析逻辑（留给 T2）
- 不要删除现有的 LRC 获取逻辑
- 不要引入 requests 等第三方库，只用 urllib

**Parallelization**:
- **Can Run In Parallel**: YES（与 T2, T3, T4 同属 Wave 1）
- **Blocks**: T2, T6
- **Blocked By**: None

**References**:
- `scripts/media/lyrics_fetcher.py:fetch_netease()` — 现有 NetEase LRC 获取逻辑

**Acceptance Criteria**:
- [ ] Python 脚本成功获取至少 3 首歌曲的 YRC 原始数据
- [ ] YRC 数据被 base64 解码并保存为可读的 JSON 字符串
- [ ] 当 YRC 不可用时，自动回退到现有 LRC 逻辑
- [ ] 脚本输出包含 `"source": "netease-yrc"` 或 `"source": "netease-lrc"` 标记

**QA Scenarios**:
```
Scenario: NetEase YRC fetch for Chinese pop song
  Tool: Bash (python3)
  Steps:
    1. Run: python3 scripts/media/lyrics_fetcher.py "晴天" "周杰伦"
    2. Inspect stdout JSON for "format" field
  Expected Result: "format" is "yrc" or "lrc", not error
  Evidence: .sisyphus/evidence/t1-netease-yrc.json

Scenario: NetEase fallback for song without YRC
  Tool: Bash (python3)
  Steps:
    1. Run: python3 scripts/media/lyrics_fetcher.py "未知歌曲" "未知艺术家"
    2. Inspect stdout JSON
  Expected Result: Returns valid LRC or empty array, no crash
  Evidence: .sisyphus/evidence/t1-netease-fallback.json
```

**Commit**: YES — `feat(lyrics): verify and fetch NetEase YRC endpoint` → `scripts/media/lyrics_fetcher.py`

---

### T2. **YRC 解析器 + LRC 增强格式解析**

**What to do**:
- 在 `lyrics_fetcher.py` 中实现 YRC JSON 解析器：将 YRC 格式（网易云逐字歌词 JSON）转换为统一 `LyricLine[]` 格式
- YRC 实际格式：`{"version":1,"lyric":"[0,1000]第(0,200)一(200,300)个(300,400)字"}` — 行头 `[start,duration]`，每字后跟 `(wordStart,wordDuration)`
- 实现 LRC 格式自动检测：标准行级、逐字 LRC (`[00:00]字[00:01]字`)、增强 LRC (`[00:00]<00:01>字<00:02>字`)
- 所有解析器输出统一格式（详见 T4）

**Must NOT do**:
- 不要实现 QRC 解析（留给 T3）
- 不要修改缓存逻辑（留给 T4）

**Parallelization**:
- **Can Run In Parallel**: YES（与 T1, T3, T4 同属 Wave 1）
- **Blocks**: T4, T6
- **Blocked By**: T1（需要 YRC 样本数据）

**References**:
- `scripts/media/lyrics_fetcher.py:parse_lrc()` — 现有解析器

**Acceptance Criteria**:
- [ ] YRC 解析器通过测试（至少 3 首真实歌曲的 YRC 数据）
- [ ] 逐字 LRC 解析器通过测试
- [ ] 增强 LRC 解析器通过测试
- [ ] 标准 LRC 仍正常工作（回归测试）
- [ ] 所有解析器输出结构一致的 JSON

**QA Scenarios**:
```
Scenario: YRC parse produces word-level output
  Tool: Bash (python3)
  Steps:
    1. Run parse function on YRC sample
    2. Check output has "words" array with >1 element per line
  Expected Result: At least 80% of lines have multiple words
  Evidence: .sisyphus/evidence/t2-yrc-parse.json

Scenario: Standard LRC still works
  Tool: Bash (python3)
  Steps:
    1. Run: python3 scripts/media/lyrics_fetcher.py "test" "test"
    2. Verify output format is valid and readable
  Expected Result: Output contains lines with single-word fallback
  Evidence: .sisyphus/evidence/t2-lrc-fallback.json
```

**Commit**: YES（与 T1 合批）— `feat(lyrics): add YRC and enhanced LRC parsers` → `scripts/media/lyrics_fetcher.py`

---

### T3. **QQ音乐 QRC 获取与解析**

**What to do**:
- 扩展 `fetch_qq()` 函数：在获取 LRC 的同时，尝试获取 QRC（逐字歌词）
- QRC 是 XML 格式：
  ```xml
  <lyric>
    <line startTime="0" duration="1000">字(0,200)字(200,300)</line>
  </lyric>
  ```
- 解析 QRC XML 为统一 `LyricLine[]` 格式（与 T2 输出一致）
- 如果 QRC 获取失败，回退到现有 LRC 逻辑
- QRC 通常也包含翻译和罗马音，但**只提取主歌词**

**Must NOT do**:
- 不要提取翻译/罗马音（超出范围）
- 不要修改 NetEase 获取逻辑
- 不要引入 xml.etree 以外的 XML 库（标准库即可）

**Parallelization**:
- **Can Run In Parallel**: YES（与 T1, T2, T4 同属 Wave 1）
- **Blocks**: T4, T6
- **Blocked By**: None

**References**:
- `scripts/media/lyrics_fetcher.py:fetch_qq()` — 现有 QQ 音乐获取逻辑

**Acceptance Criteria**:
- [ ] QRC 获取成功（至少 3 首歌曲测试）
- [ ] QRC 解析器输出统一格式，words 数组有多个元素
- [ ] QRC 失败时回退到 LRC
- [ ] 输出标记 `"source": "qq-qrc"` 或 `"source": "qq-lrc"`

**QA Scenarios**:
```
Scenario: QQ Music QRC fetch and parse
  Tool: Bash (python3)
  Steps:
    1. Run: python3 scripts/media/lyrics_fetcher.py "稻香" "周杰伦"
    2. Check stdout for "source" field
  Expected Result: "source" is "qq-qrc" or "qq-lrc"
  Evidence: .sisyphus/evidence/t3-qq-qrc.json
```

**Commit**: YES（与 T1-T2 合批）— `feat(lyrics): add QQ Music QRC fetcher and parser` → `scripts/media/lyrics_fetcher.py`

---

### T4. **统一输出格式 + 缓存版本控制 + 向后兼容过渡**

**What to do**:
- 统一所有解析器的输出为以下 JSON 结构：
  ```json
  {
    "format": "word" | "line",
    "source": "netease-yrc" | "netease-lrc" | "qq-qrc" | "qq-lrc",
    "lines": [
      {
        "time": 12.34,
        "text": "完整行文本",
        "words": [
          {"word": "字", "startTime": 12.34, "endTime": 12.56}
        ]
      }
    ],
    "_legacy": [
      {"time": 12.34, "text": "完整行文本"}
    ]
  }
  ```
- **关键：向后兼容** — 同时输出 `_legacy` 字段（flat 数组），确保旧的 QML 消费者在未更新前仍能解析：
  - 如果解析失败或只有行级数据，`words` 数组只包含一个元素（整行文本）
- 缓存版本控制：
  - 缓存目录改为 `/tmp/qs_lyrics_cache/v2/`
  - 旧缓存（根目录下的 `{hash}.json`）自动忽略，触发重新获取
- 在 `fetch_qq()` 和 `fetch_netease()` 的缓存读取逻辑中检查新格式：
  - **明确检测**：`if (Array.isArray(cached))` → 旧格式，忽略并重新获取
- 获取优先级：
  1. 检查 v2 缓存
  2. 尝试 NetEase YRC
  3. 尝试 QQ音乐 QRC
  4. 回退到 NetEase LRC
  5. 回退到 QQ音乐 LRC

**Must NOT do**:
- 不要删除旧缓存文件（保留兼容性，只是忽略）
- 不要改变命令行参数接口（保持 `title artist [playerName]`）

**Parallelization**:
- **Can Run In Parallel**: YES（与 T1, T2, T3 同属 Wave 1）
- **Blocks**: T5, T6, T7, T8
- **Blocked By**: T2, T3

**References**:
- `scripts/media/lyrics_fetcher.py` — 主文件

**Acceptance Criteria**:
- [ ] 所有来源（YRC/QRC/LRC）输出统一 JSON 结构
- [ ] `_legacy` 字段包含 flat 格式数组
- [ ] 新缓存文件使用 `v2/` 子目录
- [ ] 旧缓存被忽略，不导致解析错误
- [ ] 命令行接口不变

**QA Scenarios**:
```
Scenario: Unified output format with _legacy
  Tool: Bash (python3)
  Steps:
    1. Run fetcher with different songs
    2. Validate output has "format", "source", "lines", "_legacy" top-level keys
    3. Validate _legacy is a flat array of {time, text}
  Expected Result: 100% of outputs match schema
  Evidence: .sisyphus/evidence/t4-unified-format.json

Scenario: Cache versioning
  Tool: Bash
  Steps:
    1. Run fetcher twice for same song
    2. Check /tmp/qs_lyrics_cache/v2/ for cached file
    3. Verify second run reads from cache (faster)
  Expected Result: v2/ cache file created and reused
  Evidence: .sisyphus/evidence/t4-cache-version.txt
```

**Commit**: YES（与 T1-T3 合批）— `feat(lyrics): unify output format, cache versioning, backward-compat` → `scripts/media/lyrics_fetcher.py`

---

### T5. **LyricsSyncEngine — QML `pragma Singleton` 同步引擎**

> **修正（C2）**: 统一为 QML `pragma Singleton`（`Common/LyricsSyncEngine.qml`），不再使用 `.js` 模块。Singleton 可直接持有 Timer 并暴露 bindable 属性。

**What to do**:
- 创建 `Common/LyricsSyncEngine.qml`（`pragma Singleton` 组件）
- **全局注册**：在根 `qmldir` 中添加 `singleton LyricsSyncEngine Common/LyricsSyncEngine.qml`
- 输入接口（bindable properties）：
  - `property var lyricsData` — 歌词数据（来自 T4 的 `lines` 数组）
  - `property double playbackSeconds` — 当前播放位置（标准化为秒，基于 T0 验证结果）
  - `property bool isPlaying` — 播放状态
- 输出接口（bindable properties）：
  - `readonly property int activeLineIndex`
  - `readonly property int activeWordIndex`
  - `readonly property double activeWordProgress` (0.0–1.0)
  - `readonly property bool hasWordLevelData`
- **MPRIS position 标准化**（关键）：
  - 基于 T0 验证结果，统一转换为秒
  - 标准化逻辑：外部将 `player.position` 转换为秒后写入 `playbackSeconds`
- **二分查找** `findLineIndex(seconds)`：对 `lyricsData` 按 `time` 排序后二分查找，支持 300ms 提前量（`seconds + 0.3`）
- **字级进度** `findWordProgress(lineIndex, seconds)`：获取当前行的 `words` 数组，二分查找当前时间对应的字索引
- **自适应 Timer**：
  - `hasWordLevelData === true` → interval=50ms
  - `hasWordLevelData === false` → interval=100ms
  - `isPlaying === false` → Timer 暂停
- **快进/快退检测**：当 `playbackSeconds` 变化量 > 2s 时标记 `jumpDetected`，立即重置不插值
- **供给方模式**：
  - `LyricsContent.qml` 和 `Media.qml` 各自将 `player.position`（标准化为秒）写入 `playbackSeconds`
  - 各自绑定 `activeLineIndex` / `activeWordIndex` / `activeWordProgress` 到 UI

**Must NOT do**:
- 不要做弹簧物理动画（那是 SpringLyricView 的职责）
- 不要直接操作 UI（纯逻辑组件 + bindable 属性）

**Parallelization**:
- **Can Run In Parallel**: YES（与 T6 同属 Wave 2）
- **Blocks**: T7, T8, T9
- **Blocked By**: T0（需要 position 单位），T4（需要数据格式）

**References**:
- `Modules/DynamicIsland/LyricsContent/LyricsContent.qml:91-108` — 现有 100ms Timer + 线性扫描（含单位转换）
- `Modules/DynamicIsland/Media/Media.qml:110-122` — 现有 100ms Timer + 线性扫描（**无**单位转换）

**Acceptance Criteria**:
- [ ] 二分查找在 1000 行歌词上的时间 < 1ms
- [ ] 字级进度返回值在 [0, 1] 范围内
- [ ] 快进 10s 后 activeLineIndex 立即更新（无延迟）
- [ ] 暂停时 activeWordProgress 停止增加
- [ ] 作为 Singleton 可被两个消费者同时使用

**QA Scenarios**:
```
Scenario: Binary search accuracy
  Tool: quickshell + console.log
  Steps:
    1. 创建测试 lyricsData（100 行，times 0-100s）
    2. 设置 playbackSeconds = 50.5
  Expected Result: activeLineIndex = 50
  Evidence: .sisyphus/evidence/t5-binary-search.txt

Scenario: Word progress calculation
  Tool: quickshell + console.log
  Steps:
    1. 创建 line with words at 10.0-10.5s and 10.5-11.0s
    2. 设置 playbackSeconds = 10.75
  Expected Result: activeWordIndex=1, activeWordProgress=0.5
  Evidence: .sisyphus/evidence/t5-word-progress.txt
```

**Commit**: YES — `feat(lyrics): add LyricsSyncEngine singleton with binary search` → `Common/LyricsSyncEngine.qml`, 更新根 `qmldir`

---

### T6. **Python fetcher 集成测试（end-to-end）**

**What to do**:
- 运行扩展后的 `lyrics_fetcher.py` 对 10+ 首不同歌曲进行端到端测试
- 覆盖：中文流行、日文动漫、英文流行、纯音乐（无歌词）
- 验证输出 JSON 符合统一 schema（包含 `_legacy` 字段）
- 测量缓存命中率（第二次运行应该显著更快）
- 记录失败案例（哪些歌曲获取不到逐字歌词）

**Parallelization**:
- **Can Run In Parallel**: YES（与 T5 同属 Wave 2）
- **Blocked By**: T1-T4

**QA Scenarios**:
```
Scenario: End-to-end fetch test suite
  Tool: Bash
  Steps:
    1. Run fetcher for 10 songs
    2. Validate all outputs with python3 -m json.tool
    3. Check v2/ cache directory
  Expected Result: 100% valid JSON, >=30% word-level
  Evidence: .sisyphus/evidence/t6-e2e-results.txt
```

**Commit**: NO（testing only）

---

### T7. **SpringLyricView 改造 — 移除 3D 倾斜 + 主题色 + 逐字 delegate + Media.qml 适配**

**What to do**:
- **移除 3D 倾斜**:
  - 删除 `property real tiltAngle: 0`（`SpringLyricView.qml:30`）
  - 删除 `content` 的 `Rotation` transform（`SpringLyricView.qml:243-248`）
- **主题色配置**:
  - `activeColor` 默认值从 `"white"` 改为 `Appearance.colors.colPrimary`
  - 新增 `property bool wordLevelEnabled: false`
  - 新增 `property color wordActiveColor: Appearance.colors.colPrimary`
  - 新增 `property color wordInactiveColor: inactiveColor`
- **逐字 delegate 改造**（关键）：
  - 修改 delegate 的 property 声明：从 `required property string text` 改为 `required property var modelData`
  - 通过 `root.lyricAt(index)` 访问当前行的完整数据（包括 `words` 数组）
  - 当 `wordLevelEnabled: true` 且 `words.length > 1` 时：
    - Delegate 内部使用 `Row { Repeater { model: lyricData.words; Text { text: modelData.word; ... } } }` 渲染每个字
    - 每个字的 `color` 绑定到 `wordActiveColor`（活跃字）或 `wordInactiveColor`（非活跃字）
  - 否则：使用现有整行 `Text`（降级兼容）
- **Media.qml 适配**:
  - 替换旧的线性扫描 sync 逻辑，使用 `LyricsSyncEngine`
  - 将 `lyricsModel`（`ListModel`）改为 JS array `property var lyricsArray: []`
  - **先使用 `_legacy` 字段**填充数据，确保 T4→T7 的过渡期不崩溃
  - 传递 `activeWordIndex` / `activeWordProgress` 到 `SpringLyricView`
  - 移除旧的 100ms sync 代码，改为将标准化后的 position 写入 `LyricsSyncEngine.playbackSeconds`
  - **修复 position 单位**：基于 T0 验证结果，将 `player.position` 标准化为秒后再传给 sync 引擎

**Must NOT do**:
- 不要修改弹簧物理参数（`positionMass`, `baseStiffness` 等）
- 不要修改 `renderBefore` / `renderAfter` 默认值
- 不要改动 `stepValue` 数值积分算法
- 不要修改 `Media.qml` 的封面、频谱、控制面板布局
- 不要在 delegate 中添加新的动画（只有颜色切换，保持简单）

**Parallelization**:
- **Can Run In Parallel**: NO（单文件密集修改）
- **Parallel Group**: Wave 3
- **Blocked By**: T4, T5

**References**:
- `Widgets/common/SpringLyricView.qml:30` — tiltAngle property（待删除）
- `Widgets/common/SpringLyricView.qml:243-248` — Rotation transform（待删除）
- `Widgets/common/SpringLyricView.qml:255-369` — 现有 delegate
- `Widgets/common/SpringLyricView.qml:17-18` — activeColor / inactiveColor
- `Modules/DynamicIsland/Media/Media.qml:43-64` — lyricsModel + lyricsProc
- `Modules/DynamicIsland/Media/Media.qml:110-122` — 现有 sync Timer + position bug
- `Common/ColorMap.qml:68` — m3primary = "#b4befe"

**Acceptance Criteria**:
- [ ] Rotation transform 完全从代码中移除
- [ ] activeColor 默认值为 `Appearance.colors.colPrimary`
- [ ] Delegate 使用 `modelData` / `lyricAt(index)` 访问 words 数组
- [ ] wordLevelEnabled=false 时，现有行为 100% 不变
- [ ] wordLevelEnabled=true 时，逐字渲染正常工作
- [ ] Media.qml 的 sync 使用 LyricsSyncEngine，position 已标准化为秒
- [ ] Media.qml 歌词切换无延迟，快进无漂移
- [ ] 使用 `_legacy` 过渡期间不崩溃

**QA Scenarios**:
```
Scenario: No tilt + lavender color in SpringLyricView
  Tool: grep
  Steps:
    1. Search SpringLyricView.qml for "tiltAngle" and "Rotation"
    2. Check activeColor default value
  Expected Result: Zero tilt/Rotation matches; activeColor contains "colPrimary"
  Evidence: .sisyphus/evidence/t7-no-tilt-lavender.txt

Scenario: Word-level rendering in expanded panel
  Tool: quickshell (visual)
  Steps:
    1. Open expanded panel, toggle lyrics
    2. Observe lyrics display
  Expected Result: Active line words are #b4befe, others white/gray
  Evidence: .sisyphus/evidence/t7-expanded-word-level.png

Scenario: LRC fallback in SpringLyricView
  Tool: quickshell (visual)
  Steps:
    1. Play song with only LRC
    2. Open lyrics in expanded panel
  Expected Result: Line-level highlighting works, no crash
  Evidence: .sisyphus/evidence/t7-expanded-lrc-fallback.png
```

**Commit**: YES — `feat(lyrics): upgrade SpringLyricView with word-level delegate, catppuccin lavender, no tilt` → `Widgets/common/SpringLyricView.qml`, `Modules/DynamicIsland/Media/Media.qml`

---

### T8. **LyricsContent.qml compact bar 单行逐字**

**What to do**:
- 升级数据模型：
  - 从 `lyricsModel: []`（flat array）改为消费新的 `{lines, _legacy}` 格式
  - **先使用 `_legacy`**，等确认 stable 后切换到 `lines`
  - 使用 `LyricsSyncEngine` 替代现有的 100ms Timer + 线性扫描
- **Eliding 策略（最终方案 — 不在 T10 重新决定）**：
  - 上下文窗口截断：计算当前活跃字在整行中的位置，显示活跃字前后各 8 个字的窗口
  - 前后超出部分用 "…" 代替
  - 保证活跃字始终可见且在视觉中心附近
  - **禁止** `Row.scale`（会导致文字模糊）和字体缩放
- 改造 delegate：
  - 当当前行有 `words` 数组且长度 > 1 时：
    - 使用 `Row { Repeater { Text {} } }` 逐字渲染
    - 已唱字：`Appearance.colors.colPrimary` (#b4befe)
    - 未唱字：`"white"`
    - 平滑颜色过渡：`Behavior on color { ColorAnimation { duration: 100 } }`
  - 否则：使用单个 `Text { text: line.text }`（降级）
- **StyledListView 兼容性验证**：
  - 确认 `animateAppearance: false` + `animateMovement: false` 下 `Row+Repeater` delegate 正常工作
  - 验证 `onIsCurrentChanged` 中的 `currentTextWidth` 计算：需要测量 Row 的 implicitWidth 而非单个 Text
  - 测试场景：含有 15+ 字逐字数据的行 → 上下文窗口截断后宽度正确
- 保留现有布局：封面(26px) + 歌词(动态宽度) + 频谱(21px)
- 保留频谱条和自适应宽度引擎

**Must NOT do**:
- 不要修改 DynamicIsland.qml 的 `lyricsH`（保持 42px）
- 不要引入多行滚动（compact bar 仍是单行）
- 不要改变 `currentTextWidth` 自适应逻辑的核心（仅调整测量源）

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 4
- **Blocked By**: T4, T5

**References**:
- `Modules/DynamicIsland/LyricsContent/LyricsContent.qml` — 完整文件
- `Modules/DynamicIsland/DynamicIsland.qml:244-248` — lyricsH=42 约束
- `Common/LyricsSyncEngine.qml` — T5 输出
- `Widgets/common/StyledListView.qml` — 验证 delegate 兼容性

**Acceptance Criteria**:
- [ ] Compact bar 显示逐字高亮，已唱字为 #b4befe
- [ ] 超长歌词使用上下文窗口截断，不溢出
- [ ] 频谱条正常显示
- [ ] 宽度自适应仍工作（currentTextWidth 从 Row 测量）
- [ ] 只有 LRC 时正常显示整行白色文字
- [ ] StyledListView 的 highlight 在 Row+Repeater delegate 下正常

**QA Scenarios**:
```
Scenario: Compact bar word-level karaoke
  Tool: quickshell (visual)
  Steps:
    1. Middle-click DynamicIsland to open lyrics mode
    2. Observe compact bar
  Expected Result: Words light up one by one in #b4befe
  Evidence: .sisyphus/evidence/t8-compact-word-level.png

Scenario: Compact bar with long line (context window)
  Tool: quickshell (visual)
  Steps:
    1. Play song with very long lyric line (>20 chars)
    2. Observe compact bar
  Expected Result: Shows "…活跃字前后各8字…", no overflow
  Evidence: .sisyphus/evidence/t8-compact-long-line.png

Scenario: StyledListView currentTextWidth with Row delegate
  Tool: quickshell (visual)
  Steps:
    1. Play song with word-level lyrics, observe bar width
    2. Switch to LRC-only song, observe bar width change
  Expected Result: Width adapts to content, no sudden jumps
  Evidence: .sisyphus/evidence/t8-styledlistview-width.png
```

**Commit**: YES — `feat(lyrics): add word-level karaoke to compact bar` → `Modules/DynamicIsland/LyricsContent/LyricsContent.qml`

---

### T9. **快进/暂停/恢复 边缘场景处理**

**What to do**:
- 在 `LyricsSyncEngine` 中添加快进/快退检测：
  - 当 `playbackSeconds` 变化量 > 2s 时，标记 `jumpDetected`
  - `jumpDetected` 触发时，sync 立即重置，不插值
- 添加播放状态联动：
  - 当 MPRIS `player.playbackStatus` 变为 `Paused` 时，停止 Timer
  - 恢复 `Playing` 时，重置 Timer 并立即执行一次 sync
- 处理歌曲切换：
  - 当 `trackTitle` 变化时，立即重置 `activeLineIndex = -1`，清空旧进度
  - 在 `LyricsContent.qml` 和 `Media.qml` 中统一应用这些边缘场景处理
- 验证两个 UI 面（compact + expanded）的 seek 行为一致

**Parallelization**:
- **Can Run In Parallel**: YES（与 T10 同属 Wave 5）
- **Blocked By**: T5（LyricsSyncEngine）, T7, T8

**Acceptance Criteria**:
- [ ] 快进 10s 后歌词在 1 帧内跳到正确位置
- [ ] 暂停时活跃字颜色停止变化
- [ ] 恢复播放时颜色从正确位置继续
- [ ] 歌曲切换时旧歌词不残留
- [ ] Compact bar 和 expanded panel 的 seek 行为一致

**QA Scenarios**:
```
Scenario: Seek jump
  Tool: quickshell (visual)
  Steps:
    1. Play song with word-level lyrics
    2. Fast-forward 30s via media controls
  Expected Result: Lyrics immediately show correct line/word
  Evidence: .sisyphus/evidence/t9-seek-jump.png

Scenario: Pause and resume
  Tool: quickshell (visual)
  Steps:
    1. Pause during active word
    2. Wait 2s
    3. Resume
  Expected Result: Word color unchanged during pause, resumes correctly
  Evidence: .sisyphus/evidence/t9-pause-resume.png
```

**Commit**: YES — `fix(lyrics): handle seek, pause, resume edge cases` → `Common/LyricsSyncEngine.qml`, `Modules/DynamicIsland/LyricsContent/LyricsContent.qml`, `Modules/DynamicIsland/Media/Media.qml`

---

### T10. **性能调优 + 代码清理**

> **注意（M1 修正）**: T10 只做性能测量和代码清理。Eliding 策略已在 T8 最终确定，T10 仅验证其 60fps 性能。

**What to do**:
- **性能调优**：
  - 测量 `LyricsContent` 的 `Row + Repeater` 在 20 字/行时的渲染性能
  - 如果 frame time > 16ms，考虑将 `Repeater` 替换为 `ListView`（水平）或限制最大字数
  - 确保 `Timer` 在后台不运行（当 `active: false` 时停止）
  - 测量 `SpringLyricView` 在 word-level mode 下的性能（~120 个 Text）
- **代码清理**：
  - 删除 `LyricsContent.qml` 中旧的 sync Timer 代码（如果 T8 已完全替换）
  - 删除 `Media.qml` 中已废弃的 sync Timer 代码
  - 确保没有遗留的 `console.log` 调试代码
  - 清理 T0 添加的临时验证代码
- **过渡后清理**：
  - 确认 `_legacy` 字段不再被使用后，标记为 optional（或在 v3 中移除）

**Parallelization**:
- **Can Run In Parallel**: YES（与 T9 同属 Wave 5）
- **Blocked By**: T7, T8

**Acceptance Criteria**:
- [ ] Compact bar 在 60fps 下流畅运行
- [ ] Expanded panel 在 60fps 下流畅运行
- [ ] 无遗留调试代码
- [ ] 旧 sync 代码已清理

**QA Scenarios**:
```
Scenario: Performance check
  Tool: quickshell (visual)
  Steps:
    1. Play word-level song for 30s in compact mode
    2. Switch to expanded mode, play for 30s
    3. Observe for frame drops or stutter
  Expected Result: Smooth 60fps, no visible stutter in both modes
  Evidence: .sisyphus/evidence/t10-performance.log
```

**Commit**: YES — `refactor(lyrics): performance tuning and code cleanup` → `Modules/DynamicIsland/LyricsContent/LyricsContent.qml`, `Modules/DynamicIsland/Media/Media.qml`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists. For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `quickshell` (if available) or validate QML syntax. Review all changed files for: empty catches, console.log in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Build [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start quickshell. Play a song with NetEase YRC (e.g., 周杰伦). Verify:
  - Compact bar shows word-level highlighting
  - Expanded panel shows multi-line word-level highlighting
  - Active word/line color is `#b4befe`
  - No 3D tilt in SpringLyricView
  - Play a song with only LRC: verifies line-level fallback
  - **Compact bar context window truncation works** for long lyrics
  - Pause/resume: sync remains accurate
  - Fast-forward: sync jumps correctly without drift
  Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Detect cross-task contamination.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

- **Wave 1** (T1-T4): `feat(lyrics): add YRC/QRC fetcher with word-level parsing`
- **Wave 2** (T5): `feat(lyrics): add LyricsSyncEngine singleton with binary search`
- **Wave 3** (T7): `feat(lyrics): upgrade SpringLyricView for word-level + catppuccin theme`
- **Wave 4** (T8): `feat(lyrics): integrate word-level lyrics into compact bar`
- **Wave 5** (T9-T10): `refactor(lyrics): edge cases, performance, eliding, cleanup`

---

## Success Criteria

### Verification Commands
```bash
# 1. Python fetcher outputs valid word-level JSON (with _legacy)
python3 scripts/media/lyrics_fetcher.py "晴天" "周杰伦" | python3 -m json.tool > /dev/null && echo "VALID JSON"

# 2. quickshell launches without errors
./start-quickshell.sh &
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] Compact bar (42px) displays word-level highlighting correctly
- [ ] Expanded panel (240px) displays word-level highlighting correctly
- [ ] Active word/line color is `#b4befe`
- [ ] No 3D tilt transform in SpringLyricView
- [ ] Standard LRC songs fallback gracefully to line-level
- [ ] Cache versioning prevents old format crashes
- [ ] `_legacy` transitional field present, old consumers don't crash
- [ ] No new Python dependencies introduced
- [ ] LyricsSyncEngine is a proper QML `pragma Singleton`, not a `.js` module

---

## Changelog (v1 → v2)

### Critical Fixes
| Issue | Fix |
|-------|-----|
| **C1** 任务编号缺口 (T8/T10 缺失) | 重新编号为 T1-T10，删除所有幻影 T10 引用。旧映射表已提供。 |
| **C2** T5 类型不一致 (.js vs .qml) | 统一为 `Common/LyricsSyncEngine.qml`（`pragma Singleton`）。T5 明确要求全局注册到根 `qmldir`，暴露 bindable 属性（非纯函数）。 |
| **C3** Position 单位未验证 | 新增 **T0**：前置验证步骤。在 T5 实现前确认 `player.position` 实际单位。 |
| **C4** 格式过渡崩溃风险 | T4 添加 `_legacy` 字段（flat 数组），T7/T8 先使用 `_legacy`。过渡期后可在 T10 清理。 |

### Moderate Fixes
| Issue | Fix |
|-------|-----|
| **M1** Eliding 策略两次决策 | T8 最终确定策略（上下文窗口截断），T10 仅做性能验证。移除 T10 中的策略重讨论。 |
| **M2** 幻影 T10 引用 | 全部移除。依赖矩阵、Wave 描述、Agent Dispatch 均更新为 T1-T10。 |
| **M3** StyledListView 兼容性分析不足 | T8 添加专项测试场景：验证 Row delegate 下的 `currentTextWidth` 计算。 |
| **M4** Sync Engine 设计不明确 | T5 明确为 QML Singleton：拥有 Timer，暴露 bindable 属性，两个消费者各自写入 position 并绑定输出。 |

### Minor Fixes
| Issue | Fix |
|-------|-----|
| **m1** `Common/functions/` 目录不存在 | 改为 `Common/LyricsSyncEngine.qml`，无需创建子目录。 |
| **m2** NetEase API 风险 | T1 添加 30 分钟时间盒：如果端点探索超时，暂停并向用户报告。 |
| **m3** playerName 参数 | 保留现有用法，plan 中不再特殊处理。 |
| **m4** F3 QA 缺少 compact bar 步骤 | F3 明确添加 "Compact bar context window truncation works" 验证步骤。 |
