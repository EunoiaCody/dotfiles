# 计划：Untitled Plan

> 创建时间：7/16/2026, 3:30:11 PM
> 批准时间：7/16/2026, 3:39:30 PM

## 任务
好的，我现在想要优化一下歌词匹配，如果是音乐播放器中播放，无须担心，因为歌手，歌名和专辑名都能得到来匹配歌词

但如果是在浏览器中播放音乐，那么往往会在标题中出现干扰字词
比较简单的是这些:
- 【初音未来】神曲【R Sound Design】【但丁】
- 【可不】Kyu-kurarin【いよわ】
- 【鏡音リン】少女A【椎名もた】
但是还有比较困难的:
- 《赛博朋克：边缘行者》I Really Want to Stay at Your House【Hi-Res百万级录音棚试听】
- 【One Last Kiss｜宇多田光】百万级录音棚听《One Last Kiss》《新·福音战士剧场版:│▌》【Hi-Res】
- 【主题曲/完整版/官方MV】葬送的芙莉莲 主题曲OP「勇者」by YOASOBI 动画MV【4K画质】

我想要写一个脚本正确从标题中解析出这些歌曲元信息，我在github上找到了一个类似的项目，已经clone到了`/home/eunoia/Development/youtube_title_parse`
但是这个项目是为youtube特化的，刚刚列出来的都是bilibili的，我平时两个都看
而且这个项目已经6年没有更新了
这个项目的上游我也克隆下来了，在`/home/eunoia/Development/get-artist-title`，上次commit也是4年前了

我希望你能根据这两个项目写一个脚本来解析

## 修订说明

根据反馈做了两处关键调整：

1. **解析触发条件收窄**：仅当标题包含 `【】` `《》` `「」` 等全角括号时才走解析逻辑——这些是 Bilibili/中文视频平台的强信号标记
2. **新增「非音乐」判定层**：在解析之前先判断标题是否像音乐内容；不像的话直接返回「跳过」，QML 端完全不显示歌词

更新后的计划如下：

---

## Plan v2: 通用标题解析器（修订版）

### Overview

新增 `scripts/media/title_parser.py`，提供两个核心能力：
1. **`is_likely_music(title)`** — 前置判断：标题是否像音乐视频？（不是就跳过，连解析都不做）
2. **`parse(title)`** — 仅在标题含全角括号时启用，从 Bilibili/YouTube 标题提取 `(artist, title)`

两个函数都借鉴了 `get-artist-title` / `youtube_title_parse` 的架构和具体实现。

### 修订要点

| 原方案 | 修订后 |
|--------|--------|
| 所有浏览器标题都走解析 | 先过 `is_likely_music()`，非音乐直接跳过，**不解析也不显示歌词** |
| parse 始终执行 | 仅当标题含 `【】` `《》` `「」` 全角括号时才触发 parse |
| 流水线 5 个分割策略 | 保持不变，但增加了 `should_parse()` 门控 |

### 新增：`is_likely_music()` — 音乐判定启发式

借鉴 `youtube_title_parse` 的 fluff 模式匹配思路，反向使用：如果标题**不含**任何音乐信号词，且**含有**非音乐信号词，则判定为非音乐。

```
音乐信号词（含任一 → 可能是音乐）:
  MV, PV, M/V, Official, Lyrics, 歌词, Music, Audio,
  歌, 曲, 主题曲, OP, ED, OST, BGM, 插入曲,
  Cover, 翻唱, feat., ft., 合唱,  feat,
  Vocal, 歌ってみた, 踊ってみた,
  Original Song, 【, 《, 「

非音乐信号词（含任一且无音乐信号 → 非音乐）:
  实况, 直播, 攻略, 通关, 解说, Vlog, 日常,
  Game, Gaming, 游戏, 试玩, 评测, 开箱,
  Tutorial, 教程, Podcast, 播客, News, 新闻,
  电影完整版, 电视剧, 综艺, 纪录片
```

**判定逻辑**：
```
if 含音乐信号 → True（继续走解析）
elif 无非音乐信号 → True（保守：可能是音乐）
else → False（明确非音乐，跳过歌词）
```

### 修订：`parse()` — 门控触发

```python
def parse(title):
    # 仅在标题含全角括号时才解析（Bilibili/中文平台强信号）
    if not _has_fullwidth_brackets(title):
        return None, None
    # ... 流水线逻辑
```

`_has_fullwidth_brackets(text)` 检查是否含 `【` `】` `《` `》` `「` `」` 中任意一个。

### 修订：与 `lyrics_fetcher.py` 的集成

```python
def fetch_lyrics(title, artist):
    # Step 0: 音乐判定（浏览器场景）
    if not artist and not is_likely_music(title):
        return {"format": "none", "source": "not-music", 
                "lines": [], "_legacy": [{"time": 0, "text": ""}]}
    
    # Step 0.5: 标题解析（含全角括号时）
    if not artist:
        parsed_artist, parsed_title = parse(title)
        if parsed_artist:
            artist = parsed_artist
        if parsed_title:
            title = parsed_title
    
    # ... 原有的搜索+缓存逻辑
```

QML 端 `LyricsContent.qml` 收到空 `lines` 时自然表现为不显示歌词，无需额外改动。

### 借鉴两个参考项目的具体方式

| 借鉴来源 | 移植内容 |
|----------|----------|
| `get-artist-title` / `youtube_title_parse` | `SEPARATORS` 优先级列表、`in_quotes()` 括号感知切分、`clean_mvpv()`、`clean_fluff()`、`clean_artist()`、`clean_title()` 全部六个 fluff 去除函数 |
| 两个项目的流水线架构 | `flow()`、`combine_splitters()`、`reduce_plugins()` — 完整保留三阶段模式 |
| `youtube_title_parse` 测试集 | K-pop 引号格式（JYP 测试）、`(Official Video)` 等 YouTube fluff，确保向下兼容 |

### 更新后的文件影响

| 操作 | 文件 | 说明 |
|------|------|------|
| **新建** | `scripts/media/title_parser.py` | `is_likely_music()` + `parse()` + 移植的流水线引擎 (~450行) |
| **新建** | `scripts/media/test_title_parser.py` | 测试用例：6个B站例子 + YouTube回归 + 非音乐判定 |
| **微改** | `scripts/media/lyrics_fetcher.py` | `fetch_lyrics()` 入口加 ~20 行的判定+解析逻辑 |

### 数据流（修订后）

```
浏览器 MPRIS title
    │
    ▼
is_likely_music() ──No──▶ 返回空歌词 → QML 不显示
    │Yes
    ▼
含全角括号? ──No──▶ 原始 title 直接搜 API
    │Yes
    ▼
parse() 提取 (artist, title)
    │
    ▼
搜索结果 → 缓存 → 返回 JSON → QML 显示歌词
```

---

**修订后的 PLAN COMPLETE.** 

关键改动：解析触发条件从「浏览器场景」收紧为「含全角括号时才解析」，并新增 `is_likely_music()` 前置判定来过滤非音乐内容，两个函数都明确借鉴了那两个参考项目。

请审阅：
- **`/plan-approve`** — 批准开始实现
- **`/plan-revise <意见>`** — 继续调整