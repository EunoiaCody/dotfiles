# 计划：Planning...

> 创建时间：7/16/2026, 9:33:04 PM
> 批准时间：7/16/2026, 9:46:54 PM

## 任务
`/home/eunoia/Development/Lyricify-Lyrics-Helper`是我刚刚发现的仓库，它支持fetch更多歌词源，请你把没有的歌词源都集成进来

计划已写入 `PLAN_LYRICIFY_INTEGRATION.md`。以下是核心要点:

## 计划总结

Lyricify-Lyrics-Helper 有 **6 个新歌词源** quickshell 尚未支持:

| 源 | 格式 | 逐字? | 认证 | 难度 |
|---|---|---|---|---|
| **LRCLIB** | LRC | ❌ 行级 | 零认证 | ⭐ |
| **酷狗 KRC** | KRC(加密) | ✅ 逐字 | 零认证 | ⭐⭐ |
| **Musixmatch** | RichSync JSON | ✅ 逐字 | 自动 Token | ⭐⭐⭐ |
| **Apple Music** | TTML | ✅ 逐字 | 自动 JWT | ⭐⭐⭐⭐ |
| **汽水音乐** | LRC | ❌ 行级 | Device ID | ⭐⭐ |
| **Spotify** | ColorLyrics | ✅ 逐字 | 需 sp_dc | ⭐⭐⭐⭐⭐ (可选) |

计划分 10 个 Phase，按 **可行性+价值** 排序实施。全部用 **Python stdlib 实现**（零 pip 依赖），输出统一 JSON 格式向后兼容，前端无需修改。

**预计新增 ~500-700 行代码**，修改仅 1 个文件 `scripts/media/lyrics_fetcher.py`。

---

**PLAN COMPLETE** — 请审阅计划，确认后进入执行模式。你可以对优先级、实施顺序或任何源提出调整。