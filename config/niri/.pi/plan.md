## Plan: 实现灵动岛工具箱 7 个功能 & 落盘支持

### Overview

当前 `Mod+Shift+I` 打开的灵动岛工具箱有 8 个入口，但大部分后端未实现、`record.sh` 脚本缺失、普通截屏仅复制到剪贴板不落盘。本计划：删除「截长屏」，为其余 7 个功能补齐完整后端（录屏/GIF/截屏/OCR 落盘，录音落盘），同时补全 `wave_mic.sh` / `wave_sys.sh` 音频可视化脚本。

### Affected Files

| 文件 | 变更类型 |
|---|---|
| `~/Pictures/` | 新增子目录 `Recordings/`, `OCR/` |
| `.config/quickshell/scripts/capture/record.sh` | **新建** — 录屏/GIF/录音统一控制脚本 |
| `.config/quickshell/scripts/audio/wave_mic.sh` | **新建** — 麦克风波形可视化 |
| `.config/quickshell/scripts/audio/wave_sys.sh` | **新建** — 系统音频波形可视化 |
| `.config/quickshell/Modules/DynamicIsland/Tools/ToolsBackend.qml` | **修改** — 普通截屏落盘、新增 OCR 函数、精简 Process 节点 |
| `.config/quickshell/Modules/DynamicIsland/Tools/ToolsContent.qml` | **修改** — 移除截长屏、调整索引映射、OCR 触发 |
| `.config/quickshell/Common/Paths.qml` | **修改** — 添加 Recordings/OCR 路径常量 |

### Step-by-Step Plan

#### Phase 1: 基础设施 — 路径常量与目录

- [ ] **Step 1.1**: 在 `Paths.qml` 中添加 `recordingsDir` 和 `ocrDir` 路径常量，指向 `~/Videos/Recordings` 和 `~/Pictures/OCR`
- [ ] **Step 1.2**: 确保 `scripts/capture/` 和 `scripts/audio/` 目录存在（通过脚本创建）

#### Phase 2: 核心脚本 — `record.sh`（录屏 / GIF / 录音统一控制）

- [ ] **Step 2.1**: 创建 `scripts/capture/record.sh`，采用 subcommand 模式：
  - `start video` — 用 `slurp` 选区域，`wf-recorder` 录制 MP4，PID 写入 `/tmp/niri-record-video.pid`，保存到 `~/Videos/Recordings/`
  - `start gif` — 用 `slurp` 选区域，`wf-recorder` 录制 MP4 临时文件，stop 时用 `ffmpeg` + `gifski` 转 GIF 落盘
  - `start audio_mic` — `pw-record` 录制麦克风到 `~/Audio/Recordings/`（或统一用 `~/Videos/Recordings/`）
  - `start audio_sys` — `pw-record` 录制系统音频（monitor source）
  - `stop video|gif|audio` — 读取 PID 文件，发 SIGINT 终止，gif 额外执行转码
- [ ] **Step 2.2**: 确保脚本有 `set -euo pipefail`，有超时保护、残留 PID 清理、通知 (`notify-send`) 提示保存路径

#### Phase 3: 音频可视化脚本

- [ ] **Step 3.1**: 创建 `scripts/audio/wave_mic.sh` — 用 `pactl` 获取默认麦克风 source，pipe 到简单的 RMS 音量读取循环，输出整数到 stdout
- [ ] **Step 3.2**: 创建 `scripts/audio/wave_sys.sh` — 用 `pactl` 获取默认音频输出 monitor source，同上逻辑
- [ ] **Step 3.3**: （备选方案）如果安装 `cava` 更可靠，则创建一个最小 cava 配置，脚本用 `cava -p config` 输出 raw 数据

#### Phase 4: ToolsBackend.qml — 后端改造

- [ ] **Step 4.1**: 修改 `takeScreenshot()` — 命令改为 `grim -g "$(slurp)"` 同时保存到 `~/Pictures/Screenshots/` 并管道到 `wl-copy`
- [ ] **Step 4.2**: 新增 `recognizeOcr()` 函数 — `grim -g "$(slurp)" /tmp/niri-ocr.png && tesseract /tmp/niri-ocr.png - -l chi_sim+eng | wl-copy`，同时 .png 留存到 `~/Pictures/OCR/`
- [ ] **Step 4.3**: 新增 `ocrProcess` Process 节点
- [ ] **Step 4.4**: 保持 `startRecord()` / `stopRecord()` / `startAudio()` / `stopAudio()` 不变（它们已指向 `record.sh`）

#### Phase 5: ToolsContent.qml — UI 与索引调整

- [ ] **Step 5.1**: 从 `toolsModel` 中删除 `{ icon: "height", tip: "截长屏" }`
- [ ] **Step 5.2**: 更新 `triggerSelected()` 的 if-else 分支：
  - index 0 → 取色器（不变）
  - index 1 → 录屏（不变）
  - index 2 → 录制 GIF（不变）
  - index 3 → 普通截屏（不变）
  - index 4 → **OCR 识别** (`toolsBackend.recognizeOcr()`)
  - index 5 → 录麦克风（原 index 6）
  - index 6 → 录电脑声音（原 index 7）
- [ ] **Step 5.3**: `stopRecording()` / `stopAudio()` 绑定不变，`requestShowAudio` 传递正确 mode

#### Phase 6: 集成验证

- [ ] **Step 6.1**: 确认 `DynamicIsland.qml` 中的 `ToolsContent` 信号连接无需修改（`requestSetRecording`、`requestShowAudio`、`stopRecording` 等）
- [ ] **Step 6.2**: 确认 `AudioContent.qml` 引用的 `wave_mic.sh` / `wave_sys.sh` 路径正确（它用的是 `Paths.scriptPath("audio", "wave_" + audioMode + ".sh")`）

### Risks & Considerations

- **依赖检查**：脚本依赖 `grim`, `slurp`, `wf-recorder`, `ffmpeg`, `gifski`, `tesseract`, `pw-record`, `notify-send`。需要在脚本中检查依赖并在缺失时通过 `notify-send` 提示用户安装。
- **PipeWire vs PulseAudio**：`pw-record` 需要 PipeWire 环境。若用户使用纯 PulseAudio，需要回退到 `parec`。优先检测 PipeWire。
- **GIF 录制策略**：`wf-recorder` 不支持直接录制 GIF。策略是录制短 MP4 → `ffmpeg` 转调色板 PNG → `gifski` 合成 GIF，最后清理临时文件。
- **OCR 语言包**：`tesseract` 需要 `chi_sim` 简体中文语言包，若缺失则在通知中提示安装 `tesseract-data-chi_sim`。
- **音频波形可视化**：`AudioContent.qml` 期望脚本 stdout 输出整数（0-60 范围），已在 QML 端做归一化和曲线处理。脚本只需输出稳定的 RMS 近似值。

### Estimated Impact

- **Files to create**: 3（`record.sh`, `wave_mic.sh`, `wave_sys.sh`）
- **Files to modify**: 3（`ToolsBackend.qml`, `ToolsContent.qml`, `Paths.qml`）
- **Files to delete**: 0
- **New directories**: 2（`scripts/capture/`, `scripts/audio/`），以及落盘目标 `~/Videos/Recordings/`、`~/Pictures/OCR/`（脚本自动创建）

---

PLAN COMPLETE
