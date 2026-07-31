# 逐字歌词支持工作计划

## TL;DR

> **目标**: 为 Quickshell 的 DynamicIsland 歌词显示添加逐字歌词（karaoke 式）高亮支持，覆盖紧凑条带（42px）和展开面板（240px）两个 UI 面。
>
> **数据源**: 网易云 YRC + QQ音乐 QRC，降级到标准 LRC。
>
> **渲染**: Compact bar 用单行 `Row + Repeater + Text` 逐字变色；Expanded panel 用升级后的 `SpringLyricView`（移除 3D 倾斜，活跃行颜色改为 `Appearance.colors.colPrimary` / Catppuccin Lavender `#b4befe`）。
>
> **同步**: 50ms Timer + 二分查找 + 字级进度计算，降级到 100ms 行级。
>
> **Estimated Effort**: Large
> **Parallel Execution**: YES — 5 Waves
> **Critical Path**: T1-T4 (Python) → T5 (Sync Engine) → T8-T9 (SpringLyricView) → T10 (Compact) → Final QA

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
- `Media.qml` 当前 sync 逻辑: 100ms Timer + `ListModel` + 线性扫描 `O(n)`
- `LyricsContent.qml` 当前 sync 逻辑: 100ms Timer + JS array + 线性扫描 `O(n)`
- `SpringLyricView` 使用弹簧物理引擎（16ms Timer，`stepValue` 数值积分），支持 Y/Scale/Opacity 三维度动画 + 延迟级联

### Metis Review
**Identified Gaps** (addressed in plan):
- **Dimensional mismatch**: SpringLyricView 是多行滚动器，不能直接放入 42px compact bar。Plan 中 compact bar 使用独立的单行 `Row` delegate，不引入 SpringLyricView。
- **Text eliding**: `Row` 没有 `elide` 属性。Plan 中 compact bar 使用自定义宽度计算 + `clip` + 字体缩放策略。
- **Cache invalidation**: 旧缓存是 flat `[{time,text}]`。Plan 中引入 cache versioning (`v2_` prefix)。
- **MPRIS position precision**: 50ms Timer 可能得不到更平滑的 position 数据。Plan 中使用 timer backoff（有 word-level 数据时 50ms，否则 100ms）。
- **Two sync logics**: Plan 中统一到一个可复用的 `LyricsSyncEngine`（QML singleton 或 JS 模块）。
- **QML object proliferation**: Plan 中 compact bar 只渲染单行（~10-20 个 Text），expanded panel 渲染 12 行 × 平均 10 字 = ~120 个 Text，在可接受范围。

---

## Work Objectives

### Core Objective
升级 Quickshell 歌词系统，支持从网易云 YRC 和 QQ音乐 QRC 获取逐字歌词，并在 compact bar（42px）和 expanded panel（240px）两个 UI 面上实现逐字高亮渲染。

### Concrete Deliverables
- `scripts/media/lyrics_fetcher.py` — 多源获取 + 多格式解析 + 统一输出
- `Common/LyricsSyncEngine.qml` — 二分查找 + 字级进度计算（可复用组件）
- `Widgets/common/SpringLyricView.qml` — 移除 3D 倾斜 + 主题色 + 逐字 delegate
- `Modules/DynamicIsland/LyricsContent/LyricsContent.qml` — 数据模型升级 + 单行逐字 delegate
- `Modules/DynamicIsland/Media/Media.qml` — 数据模型升级 + 集成 SpringLyricView 逐字

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
- Compact bar 单行逐字 delegate
- SpringLyricView 多行逐字 delegate
- 活跃字/行颜色 `#b4befe`
- 3D 倾斜完全移除
- 缓存版本控制
- LRC 降级兼容

### Must NOT Have (Guardrails)
- **不实现 TTML 解析** — 超出范围
- **不实现翻译/音译对齐显示** — 超出范围
- **不实现本地文件歌词扫描** — 超出范围
- **不修改 DynamicIsland 紧凑模式的高度** — compact bar 保持 42px
- **不引入新的 Python 依赖** — 只用标准库
- **不修改 Media.qml 的封面/频谱/控制面板布局** — 只改歌词区域

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO（无单元测试框架）
- **Automated tests**: NO
- **Agent-Executed QA**: YES — 所有任务包含手动 QA scenarios

### QA Policy
Every task MUST include agent-executed QA scenarios:
- **Frontend/UI**: 启动 quickshell，播放 MPRIS 音乐，观察歌词高亮行为
- **API/Backend**: Python 脚本独立运行，验证输出 JSON 格式
- **Each scenario**: exact steps, concrete test data, expected results, evidence path

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — Python data layer, 4 parallel tasks):
├── T1: NetEase YRC 获取端点验证与请求
├── T2: YRC 解析器 + LRC 增强格式解析
├── T3: QQ音乐 QRC 获取与解析
└── T4: 统一输出格式 + 缓存版本控制

Wave 2 (Core engine — sync logic, 2 parallel tasks):
├── T5: LyricsSyncEngine 组件（二分查找 + 字级进度）
└── T6: Python fetcher 集成测试（end-to-end）

Wave 3 (Shared component — SpringLyricView + Media.qml):
└── T7: 移除 3D 倾斜 + 主题色 + 逐字 delegate + Media.qml 适配

Wave 4 (UI integration — compact bar):
└── T9: LyricsContent.qml compact bar 单行逐字

Wave 5 (Polish + integration, 2 parallel tasks):
├── T11: 快进/暂停/恢复 边缘场景处理
└── T12: 性能调优 + eliding 策略完善

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── F1: Plan compliance audit (oracle)
├── F2: Code quality review (unspecified-high)
├── F3: Real manual QA (unspecified-high)
└── F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: T1 → T2-T4 → T5 → T7 → T9 → T11-T12 → F1-F4 → user okay
Parallel Speedup: ~55% faster than sequential
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| T1 | — | T2, T6 |
| T2 | T1 | T4, T6 |
| T3 | — | T4, T6 |
| T4 | T2, T3 | T5, T6, T7, T9 |
| T5 | — | T7, T9 |
| T6 | T1-T4 | — |
| T7 | T4, T5 | — |
| T9 | T4, T5 | — |
| T11 | T7, T9 | — |
| T12 | T7, T9 | — |

### Agent Dispatch Summary

- **Wave 1**: T1-T4 → `unspecified-high` (Python/QML integration)
- **Wave 2**: T5-T6 → `quick` (T5 JS module) + `unspecified-high` (T6 e2e)
- **Wave 3**: T7 → `visual-engineering` (SpringLyricView + Media.qml)
- **Wave 4**: T9 → `visual-engineering` (LyricsContent compact bar)
- **Wave 5**: T11-T12 → `deep` (edge cases) + `unspecified-high` (perf)
- **FINAL**: F1-F4 → `oracle`, `unspecified-high`, `unspecified-high`, `deep`

---

## TODOs

- [x] T1. **NetEase YRC 端点验证与请求**

  **What to do**:
  - 验证当前 `lyrics_fetcher.py` 的 NetEase 端点 `http://music.163.com/api/song/lyric?os=pc&id={id}&lv=-1&kv=-1&tv=-1` 是否返回 `yrc` 字段
  - 使用 `curl` 或 Python 测试 3-5 首不同歌曲（中文、日文、英文），确认 YRC 返回率和数据结构
  - 如果该端点不返回 YRC，找到正确的 YRC 端点（可能是 `yrc` 参数或不同路径）
  - 将 YRC 获取逻辑添加到 `lyrics_fetcher.py` 的 `fetch_netease()` 函数中
  - YRC 通常是 base64 编码的 JSON，需要先解码再解析

  **Must NOT do**:
  - 不要修改解析逻辑（留给 T2）
  - 不要删除现有的 LRC 获取逻辑
  - 不要引入 requests 等第三方库，只用 urllib

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - Reason: 需要 Python HTTP 请求调试和 API 端点探索

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T2, T3, T4)
  - **Blocks**: T2, T6
  - **Blocked By**: None

  **References**:
  - `scripts/lyrics_fetcher.py:fetch_netease()` — 现有 NetEase LRC 获取逻辑
  - `Development/SPlayer/src/core/player/LyricManager.ts:adoptLRC()` — SPlayer 的 YRC 获取策略
  - `Development/SPlayer/src/utils/lyric/lyricParser.ts:parseSmartLrc()` — 格式检测逻辑参考

  **Important Note (Momus Review)**:
  - NetEase YRC 可能需要 `yv=-1` 参数而非当前使用的 `lv=-1&kv=-1&tv=-1`。T1 必须测试两种端点。
  - 验证 `http://music.163.com/api/song/lyric?id={id}&lv=-1&tv=-1&yv=-1` 是否返回 `yrc` 字段。

  **Acceptance Criteria**:
  - [ ] Python 脚本成功获取至少 3 首歌曲的 YRC 原始数据
  - [ ] YRC 数据被 base64 解码并保存为可读的 JSON 字符串
  - [ ] 当 YRC 不可用时，自动回退到现有 LRC 逻辑
  - [ ] 脚本输出包含 `"source": "netease-yrc"` 或 `"source": "netease-lrc"` 标记

  **QA Scenarios**:
  ```
  Scenario: NetEase YRC fetch for Chinese pop song
    Tool: Bash (python3)
    Preconditions: None
    Steps:
      1. Run: python3 scripts/media/lyrics_fetcher.py "晴天" "周杰伦"
      2. Inspect stdout JSON for "format" field
    Expected Result: "format" is "yrc" or "lrc", not error
    Evidence: .sisyphus/evidence/t1-netease-yrc.json

  Scenario: NetEase fallback for song without YRC
    Tool: Bash (python3)
    Preconditions: None
    Steps:
      1. Run: python3 scripts/media/lyrics_fetcher.py "未知歌曲" "未知艺术家"
      2. Inspect stdout JSON
    Expected Result: Returns valid LRC or empty array, no crash
    Evidence: .sisyphus/evidence/t1-netease-fallback.json
  ```

  **Evidence to Capture**:
  - [ ] YRC response samples for 3 songs
  - [ ] Decoded YRC JSON structure

  **Commit**: YES
  - Message: `feat(lyrics): verify and fetch NetEase YRC endpoint`
  - Files: `scripts/lyrics_fetcher.py`

- [x] T2. **YRC 解析器 + LRC 增强格式解析**

  **What to do**:
  - 在 `lyrics_fetcher.py` 中实现 YRC JSON 解析器：将 YRC 格式（网易云逐字歌词 JSON）转换为统一 `LyricLine[]` 格式
  - YRC 实际格式：`{"version":1,"lyric":"[0,1000]第(0,200)一(200,300)个(300,400)字"}` — 行头 `[start,duration]`，每字后跟 `(wordStart,wordDuration)`
  - 实现 LRC 格式自动检测：标准行级、逐字 LRC (`[00:00]字[00:01]字`)、增强 LRC (`[00:00]<00:01>字<00:02>字`)
  - 所有解析器输出统一格式：
    ```json
    {"format": "word", "source": "netease-yrc", "lines": [
      {"time": 12.34, "text": "完整行文本", "words": [
        {"word": "完", "startTime": 12.34, "endTime": 12.56},
        {"word": "整", "startTime": 12.56, "endTime": 12.78}
      ]}
    ]}
    ```
  - 如果解析失败或只有行级数据，`words` 数组只包含一个元素（整行文本）

  **Must NOT do**:
  - 不要实现 TTML / QRC 解析（留给 T3）
  - 不要修改缓存逻辑（留给 T4）
  - 不要添加翻译/音译对齐

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - Reason: Python 文本解析，参考 SPlayer TypeScript 解析器移植到 Python

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T3, T4)
  - **Blocks**: T4, T6
  - **Blocked By**: T1 (需要 YRC 样本数据)

  **References**:
  - `Development/SPlayer/src/utils/lyric/lyricParser.ts:parseWordByWordLrc()` — 逐字 LRC 解析逻辑
  - `Development/SPlayer/src/utils/lyric/lyricParser.ts:parseEnhancedLrc()` — 增强 LRC 解析逻辑
  - `Development/SPlayer/src/utils/lyric/parseLrc.ts:parseLrc()` — 标准 LRC 解析逻辑
  - `scripts/lyrics_fetcher.py:parse_lrc()` — 现有解析器

  **Acceptance Criteria**:
  - [ ] YRC 解析器通过单元测试（至少 3 首真实歌曲的 YRC 数据）
  - [ ] 逐字 LRC 解析器通过测试（构造测试输入）
  - [ ] 增强 LRC 解析器通过测试（构造测试输入）
  - [ ] 标准 LRC 仍正常工作（回归测试）
  - [ ] 所有解析器输出结构一致的 JSON

  **QA Scenarios**:
  ```
  Scenario: YRC parse produces word-level output
    Tool: Bash (python3)
    Preconditions: T1 completed, YRC sample saved
    Steps:
      1. Run parse function on YRC sample
      2. Check output has "words" array with >1 element per line
    Expected Result: At least 80% of lines have multiple words
    Evidence: .sisyphus/evidence/t2-yrc-parse.json

  Scenario: Standard LRC still works
    Tool: Bash (python3)
    Preconditions: None
    Steps:
      1. Run: python3 scripts/media/lyrics_fetcher.py "test" "test"
      2. Verify output format is valid and readable
    Expected Result: Output contains lines with single-word fallback
    Evidence: .sisyphus/evidence/t2-lrc-fallback.json
  ```

  **Evidence to Capture**:
  - [ ] Parsed output for YRC, word-by-word LRC, enhanced LRC, standard LRC

  **Commit**: YES (groups with T1)
  - Message: `feat(lyrics): add YRC and enhanced LRC parsers`
  - Files: `scripts/lyrics_fetcher.py`

- [x] T3. **QQ音乐 QRC 获取与解析**

  **What to do**:
  - 扩展 `lyrics_fetcher.py` 的 `fetch_qq()` 函数：在获取 LRC 的同时，尝试获取 QRC（逐字歌词）
  - QRC 是 XML 格式，结构类似于：
    ```xml
    <lyric>
      <line startTime="0" duration="1000">字(0,200)字(200,300)</line>
    </lyric>
    ```
  - 解析 QRC XML 为统一 `LyricLine[]` 格式（与 T2 输出一致）
  - 如果 QRC 获取失败，回退到现有 LRC 逻辑
  - QRC 通常也包含翻译和罗马音，但**只提取主歌词**，忽略翻译/罗马音（超出范围）

  **Must NOT do**:
  - 不要提取翻译/罗马音（超出范围）
  - 不要修改 NetEase 获取逻辑
  - 不要引入 xml.etree 以外的 XML 库（标准库即可）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - Reason: Python HTTP + XML 解析

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T2, T4)
  - **Blocks**: T4, T6
  - **Blocked By**: None

  **References**:
  - `Development/SPlayer/src/utils/lyric/lyricParser.ts:parseQRCContent()` — QRC 解析逻辑
  - `Development/SPlayer/src/utils/lyric/lyricParser.ts:parseQRCLyric()` — QRC 主入口
  - `scripts/lyrics_fetcher.py:fetch_qq()` — 现有 QQ 音乐获取逻辑

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

  **Evidence to Capture**:
  - [ ] QRC XML samples + parsed output

  **Commit**: YES (groups with T1-T2)
  - Message: `feat(lyrics): add QQ Music QRC fetcher and parser`
  - Files: `scripts/lyrics_fetcher.py`

- [x] T4. **统一输出格式 + 缓存版本控制**

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
      ]
    }
    ```
  - 实现缓存版本控制：
    - 缓存目录改为 `/tmp/qs_lyrics_cache/v2/`
    - 或文件名加 `v2_` 前缀：`v2_{hash}.json`
    - 旧缓存（`{hash}.json`）自动忽略，触发重新获取
  - 在 `fetch_qq()` 和 `fetch_netease()` 的缓存读取逻辑中检查新格式：
    - **明确检测**：`if (Array.isArray(cached))` → 旧格式，忽略并重新获取
    - 如果缓存是新格式但解析失败，重新获取
  - 实现获取优先级：
    1. 检查新格式缓存
    2. 尝试 NetEase YRC
    3. 尝试 QQ音乐 QRC
    4. 回退到 NetEase LRC
    5. 回退到 QQ音乐 LRC

  **Must NOT do**:
  - 不要删除旧缓存文件（保留兼容性，只是忽略）
  - 不要改变命令行参数接口（保持 `title artist [playerName]`）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - Reason: 主要是代码整合和格式标准化

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with T1, T2, T3)
  - **Blocks**: T5, T6, T9, T10
  - **Blocked By**: T2, T3

  **References**:
  - `scripts/lyrics_fetcher.py` — 主文件
  - `Development/SPlayer/src/types/lyric.d.ts` — SongLyric 接口定义

  **Acceptance Criteria**:
  - [ ] 所有来源（YRC/QRC/LRC）输出统一 JSON 结构
  - [ ] 新缓存文件使用 v2 命名
  - [ ] 旧缓存被忽略，不导致解析错误
  - [ ] 命令行接口不变

  **QA Scenarios**:
  ```
  Scenario: Unified output format
    Tool: Bash (python3)
    Steps:
      1. Run fetcher with different songs
      2. Validate each output has "format", "source", "lines" top-level keys
      3. Validate each line has "time", "text", "words"
    Expected Result: 100% of outputs match schema
    Evidence: .sisyphus/evidence/t4-unified-format.json

  Scenario: Cache versioning
    Tool: Bash
    Steps:
      1. Run fetcher twice for same song
      2. Check /tmp/qs_lyrics_cache/ for v2_ prefixed file
      3. Verify second run reads from cache (faster)
    Expected Result: v2_ cache file created and reused
    Evidence: .sisyphus/evidence/t4-cache-version.txt
  ```

  **Commit**: YES (groups with T1-T3)
  - Message: `feat(lyrics): unify output format and add cache versioning`
  - Files: `scripts/lyrics_fetcher.py`

- [x] T5. **LyricsSyncEngine JS 模块（二分查找 + 字级进度 + MPRIS 标准化）**

  **What to do**:
  - 创建 `Common/functions/lyricsSync.js`（JS 模块，非 QML Singleton）作为可复用的歌词同步引擎
  - 实现接口：输入 `lyricsData`, `playbackSeconds`；输出 `activeLineIndex`, `activeWordIndex`, `activeWordProgress`, `hasWordLevelData`
  - **MPRIS position 标准化**（关键修复）：
    - 当前 `Media.qml` 存在 bug：直接将 `player.position`（微秒）与秒级 `time` 比较
    - 标准化逻辑：`if (pos > 100000) pos /= 1000000; else if (pos > 1000) pos /= 1000;`
    - `LyricsContent.qml` 已有类似逻辑但分散，统一到此模块
  - 二分查找实现 (`findLineIndex(seconds)`): 对 `lyricsData.lines` 按 `time` 排序后二分查找，支持 300ms 提前量（`seconds + 0.3`）
  - 字级进度实现 (`findWordProgress(lineIndex, seconds)`): 获取当前行的 `words` 数组，二分查找当前时间对应的字索引，计算字内进度 `(currentTime - wordStartTime) / (wordEndTime - wordStartTime)`
  - Timer 策略：当 `hasWordLevelData` 为 true 时 interval=50ms，否则 100ms
  - 快进/快退检测：当 `playbackSeconds` 变化量 > 2s 时标记 `immediate=true`，同步引擎立即重置不插值

  **Must NOT do**:
  - 不要做弹簧物理动画（那是 SpringLyricView 的职责）
  - 不要直接操作 UI（纯 JS/QML 逻辑组件）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - Reason: 纯 JS 逻辑模块，无 QML UI 开销，更轻量且可测试

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with T6)
  - **Blocks**: T9, T10
  - **Blocked By**: None

  **References**:
  - `Modules/DynamicIsland/LyricsContent/LyricsContent.qml:91-108` — 现有 100ms Timer + 线性扫描
  - `Modules/DynamicIsland/Media/Media.qml:110-130` — 现有 100ms Timer + 线性扫描
  - `Development/SPlayer/src/utils/calc.ts:calculateLyricIndex()` — SPlayer 二分查找逻辑

  **Acceptance Criteria**:
  - [ ] 二分查找在 1000 行歌词上的时间 < 1ms
  - [ ] 字级进度返回值在 [0, 1] 范围内
  - [ ] 快进 10s 后 activeLineIndex 立即更新（无延迟）
  - [ ] 暂停时 activeWordProgress 停止增加

  **QA Scenarios**:
  ```
  Scenario: Binary search accuracy
    Tool: Bash (node or qml)
    Steps:
      1. Create test lyrics with 100 lines, times 0-100s
      2. Query findLineIndex at 50.5s
    Expected Result: Returns index 50
    Evidence: .sisyphus/evidence/t5-binary-search.txt

  Scenario: Word progress calculation
    Tool: Bash (node or qml)
    Steps:
      1. Create line with words at 10.0-10.5s and 10.5-11.0s
      2. Query at 10.75s
    Expected Result: activeWordIndex=1, activeWordProgress=0.5
    Evidence: .sisyphus/evidence/t5-word-progress.txt
  ```

  **Commit**: YES
  - Message: `feat(lyrics): add LyricsSyncEngine with binary search and word progress`
  - Files: `Common/LyricsSyncEngine.qml`

- [x] T6. **Python fetcher 集成测试（end-to-end）**

  **What to do**:
  - 运行扩展后的 `lyrics_fetcher.py` 对 10+ 首不同歌曲进行端到端测试
  - 覆盖：中文流行、日文动漫、英文流行、纯音乐（无歌词）
  - 验证输出 JSON 符合统一 schema
  - 测量缓存命中率（第二次运行应该显著更快）
  - 记录失败案例（哪些歌曲获取不到逐字歌词）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with T5)
  - **Blocked By**: T1-T4

  **QA Scenarios**:
  ```
  Scenario: End-to-end fetch test suite
    Tool: Bash
    Steps:
      1. Run fetcher for 10 songs
      2. Validate all outputs with python3 -m json.tool
      3. Check cache directory for v2_ files
    Expected Result: 100% valid JSON, >=30% word-level
    Evidence: .sisyphus/evidence/t6-e2e-results.txt
  ```

  **Commit**: NO (testing only)

- [ ] T7. **SpringLyricView 改造 — 移除 3D 倾斜 + 主题色 + 逐字 delegate + Media.qml 适配**

  **What to do**:
  - **移除 3D 倾斜**:
    - 删除 `property real tiltAngle: 0`
    - 删除 `content` 的 `Rotation` transform
  - **主题色配置**:
    - `activeColor` 默认值从 `"white"` 改为 `Appearance.colors.colPrimary`
    - `inactiveColor` 保持 `"#99ffffff"`
    - 新增 `property bool wordLevelEnabled: false`
    - 新增 `property color wordActiveColor: Appearance.colors.colPrimary`
    - 新增 `property color wordInactiveColor: inactiveColor`
  - **逐字 delegate 改造**（关键）：
    - 当 `wordLevelEnabled: true` 且 lyric line 有 `words` 数组且 `words.length > 1` 时：
      - Delegate 内部使用 `Row { Repeater { Text {} } }` 渲染每个字
      - 每个字的 `color` 绑定到 `wordActiveColor`（如果该字是当前活跃字）或 `wordInactiveColor`
    - 否则：使用现有整行 `Text`（降级兼容）
    - **修改 delegate property 声明**：从 `required property string text` 改为 `required property var modelData`，通过 `lyricAt(index)` 访问 `words` 数组（Momus 发现：JS array model 不自动暴露 `text` role）
  - **Media.qml 适配**:
    - 替换旧的线性扫描 sync 逻辑，使用 `LyricsSyncEngine`
    - 将 `lyricsModel`（`ListModel`）改为 JS array `property var lyricsArray: []`
    - 传递 `activeWordIndex` / `activeWordProgress` 到 `SpringLyricView`
    - 移除旧的 100ms Timer 中的 sync 代码（保留 Timer 用于 position 更新）
    - **修复 position 单位 bug**：标准化 `player.position` 为秒后再传给 sync 引擎

  **Must NOT do**:
  - 不要修改弹簧物理参数（`positionMass`, `baseStiffness` 等）
  - 不要修改 `renderBefore` / `renderAfter` 默认值
  - 不要改动 `stepValue` 数值积分算法
  - 不要修改 `Media.qml` 的封面、频谱、控制面板布局
  - 不要在 delegate 中添加新的动画（只有颜色切换，保持简单）

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []
  - Reason: UI 组件改造 + delegate 重构 + 多文件集成

  **Parallelization**:
  - **Can Run In Parallel**: NO（单文件密集修改）
  - **Parallel Group**: Wave 3
  - **Blocks**: T10
  - **Blocked By**: T4, T5

  **References**:
    - `Widgets/common/SpringLyricView.qml:30` — tiltAngle property
    - `Widgets/common/SpringLyricView.qml:243-248` — Rotation transform
    - `Widgets/common/SpringLyricView.qml:255-369` — 现有 delegate
    - `Widgets/common/SpringLyricView.qml:17-18` — activeColor / inactiveColor
    - `Modules/DynamicIsland/Media/Media.qml:43-64` — lyricsModel + lyricsProc
    - `Modules/DynamicIsland/Media/Media.qml:110-130` — 现有 sync Timer + position bug
    - `Common/ColorMap.qml:68` — m3primary = "#b4befe"

  **Acceptance Criteria**:
  - [ ] Rotation transform 完全从代码中移除
  - [ ] activeColor 默认值为 `Appearance.colors.colPrimary`
  - [ ] Delegate 使用 `modelData` / `lyricAt(index)` 访问 words 数组
  - [ ] wordLevelEnabled=false 时，现有行为 100% 不变
  - [ ] wordLevelEnabled=true 时，逐字渲染正常工作
  - [ ] Media.qml 的 sync 使用 LyricsSyncEngine，position 已标准化为秒
  - [ ] Media.qml 歌词切换无延迟，快进无漂移

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

  **Commit**: YES
  - Message: `feat(lyrics): upgrade SpringLyricView with word-level delegate, catppuccin lavender, no tilt`
  - Files: `Widgets/common/SpringLyricView.qml`, `Modules/DynamicIsland/Media/Media.qml`

- [ ] T9. **LyricsContent.qml compact bar 单行逐字**

  **What to do**:
  - 升级 `LyricsContent.qml` 的数据模型：
    - 从 `lyricsModel: []`（flat array）改为消费新的 `{lines: [...]}` 格式
    - 使用 `LyricsSyncEngine` 替代现有的 100ms Timer + 线性扫描
  - 改造 delegate：
    - 当当前行有 `words` 数组且长度 > 1 时：
      - 使用 `Row { Repeater { Text {} } }` 逐字渲染
      - 已唱字：`Appearance.colors.colPrimary`
      - 未唱字：`"white"`
      - 平滑颜色过渡：`Behavior on color { ColorAnimation { duration: 100 } }`
    - 否则：使用单个 `Text { text: line.text }`（降级）
  - 处理超长歌词的 eliding 策略（Momus 建议）：
    - **推荐方案**：计算活跃字的位置，显示活跃字前后各 N 个字的上下文窗口（如前后各 8 字），超出部分用 "…" 截断
    - 备选方案：当 `Row.implicitWidth > currentTextWidth` 时缩小 `font.pixelSize`（最小 11px）
    - **禁止**：`Row.scale` 会导致文字模糊，不可使用
  - 验证 `StyledListView` 兼容性：确保自定义 delegate（Row + Repeater）不会被 `StyledListView` 的过渡动画干扰
  - 保留现有布局：封面(26px) + 歌词(动态宽度) + 频谱(21px)
  - 保留频谱条和自适应宽度引擎

  **Must NOT do**:
  - 不要修改 DynamicIsland.qml 的 `lyricsH`（保持 42px）
  - 不要引入多行滚动（compact bar 仍是单行）
  - 不要改变 `currentTextWidth` 自适应逻辑

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with T10)
  - **Blocked By**: T4, T5

  **References**:
  - `Modules/DynamicIsland/LyricsContent/LyricsContent.qml` — 完整文件
  - `Modules/DynamicIsland/DynamicIsland.qml:244-248` — lyricsH=42 约束
  - `Common/functions/lyricsSync.js` — T5 输出
  - `Widgets/common/StyledListView.qml` — 验证 delegate 兼容性

  **Acceptance Criteria**:
  - [ ] Compact bar 显示逐字高亮，已唱字为 #b4befe
  - [ ] 超长歌词不溢出，有合理的截断/缩放策略
  - [ ] 频谱条正常显示
  - [ ] 宽度自适应仍工作（currentTextWidth 随内容变化）
  - [ ] 只有 LRC 时正常显示整行白色文字

  **QA Scenarios**:
  ```
  Scenario: Compact bar word-level karaoke
    Tool: quickshell (visual)
    Steps:
      1. Middle-click DynamicIsland to open lyrics mode
      2. Observe compact bar
    Expected Result: Words light up one by one in #b4befe
    Evidence: .sisyphus/evidence/t9-compact-word-level.png

  Scenario: Compact bar with long line
    Tool: quickshell (visual)
    Steps:
      1. Play song with very long lyric line
      2. Observe compact bar
    Expected Result: No overflow, text fits within bar
    Evidence: .sisyphus/evidence/t9-compact-long-line.png
  ```

  **Commit**: YES
  - Message: `feat(lyrics): add word-level karaoke to compact bar`
  - Files: `Modules/DynamicIsland/LyricsContent/LyricsContent.qml`

- [ ] T11. **快进/暂停/恢复 边缘场景处理**

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

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
  - Reason: 需要仔细处理状态和时序的边界条件

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with T12)
  - **Blocked By**: T9, T10

  **Acceptance Criteria**:
  - [ ] 快进 10s 后歌词在 1 帧内跳到正确位置
  - [ ] 暂停时活跃字颜色停止变化
  - [ ] 恢复播放时颜色从正确位置继续
  - [ ] 歌曲切换时旧歌词不残留

  **QA Scenarios**:
  ```
  Scenario: Seek jump
    Tool: quickshell (visual)
    Steps:
      1. Play song with word-level lyrics
      2. Fast-forward 30s via media controls
    Expected Result: Lyrics immediately show correct line/word
    Evidence: .sisyphus/evidence/t11-seek-jump.png

  Scenario: Pause and resume
    Tool: quickshell (visual)
    Steps:
      1. Pause during active word
      2. Wait 2s
      3. Resume
    Expected Result: Word color unchanged during pause, resumes correctly
    Evidence: .sisyphus/evidence/t11-pause-resume.png
  ```

  **Commit**: YES
  - Message: `fix(lyrics): handle seek, pause, resume edge cases`
  - Files: `Common/LyricsSyncEngine.qml`, `Modules/DynamicIsland/LyricsContent/LyricsContent.qml`, `Modules/DynamicIsland/Media/Media.qml`

- [ ] T12. **性能调优 + eliding 策略完善**

  **What to do**:
  - **性能调优**：
    - 测量 `LyricsContent` 的 `Row + Repeater` 在 20 字/行时的渲染性能
    - 如果 frame time > 16ms，考虑将 `Repeater` 替换为 `ListView`（水平）或限制最大字数
    - 确保 `Timer` 在后台不运行（当 `active: false` 时停止）
  - **Eliding 策略完善**（Momus 修正）：
    - **最终方案**：上下文窗口截断
      - 计算当前活跃字在整行中的位置
      - 显示活跃字前后各 8-10 个字的窗口
      - 前后超出部分用 "…" 代替
      - 保证活跃字始终可见且在视觉中心附近
    - **禁止**：`Row.scale` 会导致文字模糊和可读性下降，绝不可使用
  - **代码清理**：
    - 删除 `LyricsContent.qml` 中旧的 `StyledListView` 相关代码（如果已完全替换）
    - 删除 `Media.qml` 中已废弃的 sync Timer 代码
    - 确保没有遗留的 `console.log` 调试代码

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with T11)
  - **Blocked By**: T9, T10

  **Acceptance Criteria**:
  - [ ] Compact bar 在 60fps 下流畅运行
  - [ ] 超长歌词有合理的显示策略，不溢出
  - [ ] 无遗留调试代码
  - [ ] 旧代码已清理

  **QA Scenarios**:
  ```
  Scenario: Performance check
    Tool: quickshell (visual)
    Steps:
      1. Play word-level song for 30s
      2. Observe for frame drops or stutter
    Expected Result: Smooth 60fps, no visible stutter
    Evidence: .sisyphus/evidence/t12-performance.log
  ```

  **Commit**: YES
  - Message: `refactor(lyrics): performance tuning and code cleanup`
  - Files: `Modules/DynamicIsland/LyricsContent/LyricsContent.qml`, `Modules/DynamicIsland/Media/Media.qml`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `quickshell` (if available) or at least validate QML syntax. Review all changed files for: `as any`/`@ts-ignore`, empty catches, console.log in prod, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Build [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start quickshell. Play a song with NetEase YRC (e.g., 周杰伦). Verify:
  - Compact bar shows word-level highlighting
  - Expanded panel shows multi-line word-level highlighting
  - Active word/line color is `#b4befe`
  - No 3D tilt in SpringLyricView
  - Play a song with only LRC: verifies line-level fallback
  - Pause/resume: sync remains accurate
  - Fast-forward: sync jumps correctly without drift
  Save evidence to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance. Detect cross-task contamination.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `feat(lyrics): add YRC/QRC fetcher with word-level parsing`
- **Wave 2**: `feat(lyrics): add LyricsSyncEngine with binary search`
- **Wave 3**: `feat(lyrics): upgrade SpringLyricView for word-level + catppuccin theme`
- **Wave 4**: `feat(lyrics): integrate word-level lyrics into compact bar and expanded panel`
- **Wave 5**: `refactor(lyrics): edge cases, performance, eliding`

---

## Success Criteria

### Verification Commands
```bash
# 1. Python fetcher outputs valid word-level JSON
python3 scripts/media/lyrics_fetcher.py "晴天" "周杰伦" | python3 -m json.tool > /dev/null && echo "VALID JSON"

# 2. QML syntax check (if qmlint available)
# qmlint Modules/DynamicIsland/LyricsContent/LyricsContent.qml
# qmlint Widgets/common/SpringLyricView.qml

# 3. quickshell launches without errors
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
- [ ] No new Python dependencies introduced
