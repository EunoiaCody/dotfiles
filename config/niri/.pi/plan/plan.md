# 计划：Planning...

> 创建时间：7/17/2026, 8:12:59 PM
> 状态：审阅中

## 任务
那你把那8个小功能都实现了吧，并且录屏、录制 GIF、普通截屏、OCR 识别要落盘，截长屏不需要，可以删除

## 计划已生成

计划保存在 `.pi/plan.md`。以下是核心要点：

---

### 7 个功能实现方案

| # | 功能 | 方案 | 落盘路径 |
|---|---|---|---|
| 0 | **取色器** | 已可用 (`hyprpicker -a`)，不动 | 剪贴板 |
| 1 | **录屏** | `slurp` 选区域 → `wf-recorder` → `.mp4` | `~/Videos/Recordings/` |
| 2 | **录制 GIF** | `slurp` 选区 → `wf-recorder` 录临时 MP4 → stop 时 `ffmpeg` + `gifski` 转 GIF | `~/Videos/Recordings/` |
| 3 | **普通截屏** | `grim -g "$(slurp)"` → 同时落盘 PNG + `wl-copy` 剪贴板 | `~/Pictures/Screenshots/` |
| 4 | **OCR 识别** | `grim` 选区 → `tesseract` (chi_sim+eng) → `wl-copy` + PNG 留存 | `~/Pictures/OCR/` |
| 5 | **录麦克风** | `pw-record` 录麦克风 source | `~/Videos/Recordings/` |
| 6 | **录电脑声音** | `pw-record` 录 monitor source | `~/Videos/Recordings/` |

### 需要改动的文件

```
新建:
  scripts/capture/record.sh       ← 录屏/GIF/录音统一控制脚本
  scripts/audio/wave_mic.sh       ← 麦克风波形可视化
  scripts/audio/wave_sys.sh       ← 系统音频波形可视化

修改:
  ToolsBackend.qml     ← 截屏落盘 + OCR 命令
  ToolsContent.qml     ← 删除「截长屏」、索引重排
  Paths.qml            ← 新增 Recordings/OCR 路径常量
```

### 预览：record.sh 结构

```bash
record.sh start video     # slurp选区 → wf-recorder录制 → PID锁文件
record.sh stop  video     # 发SIGINT → notify-send提示路径
record.sh start gif       # slurp选区 → wf-recorder临时MP4
record.sh stop  gif       # 终止录制 → ffmpeg+gifski转GIF → 删临时文件
record.sh start audio_mic # pw-record 麦克风
record.sh start audio_sys # pw-record 系统音频
record.sh stop  audio     # 停止录音
```

---

**PLAN COMPLETE** — 请审阅，批准后我开始逐步实现。