# Plan: 集成 Lyricify-Lyrics-Helper 新增歌词源

## Overview

将 Lyricify-Lyrics-Helper 中 **quickshell 尚未支持的 6 个歌词源** 集成到 `scripts/media/lyrics_fetcher.py`，同时增强已有的 QQ音乐/网易云获取链路。所有新增源提供 **line-level (LRC)** 作为最低保障，**word-level (逐字)** 作为优先输出。

## 对比分析

| 歌词源 | quickshell 现有 | Lyricify 新增 | 逐字支持 | 认证需求 | 可行性 |
|--------|:----:|:------:|:------:|------|:----:|
| TTML (AMLL DB) | ✅ | — | ✅ word | 无 | 已有 |
| QQ 音乐 QRC | ✅ | 待增强 | ✅ word | 无 | 已有 |
| QQ 音乐 LRC | ✅ | — | — | 无 | 已有 |
| 网易云 YRC | ✅ | 待增强 | ✅ word | 无 | 已有 |
| 网易云 LRC | ✅ | — | — | 无 | 已有 |
| **酷狗 KRC** | ❌ | ✅ | ✅ word | 无 | **新增** |
| **Musixmatch** | ❌ | ✅ | ✅ word | 自动Token | **新增** |
| **Apple Music** | ❌ | ✅ | ✅ word | 自动Token | **新增** |
| **LRCLIB** | ❌ | ✅ | — LRC | 无 | **新增** |
| **汽水音乐** | ❌ | ✅ | — LRC | 无 | **新增** |
| **Spotify** | ❌ | ✅ | ✅ word | 浏览器提取 | **新增** |

## Affected Files

- `scripts/media/lyrics_fetcher.py` — 主要修改文件，新增所有获取函数和解析器
- `Common/LyricsSyncEngine.qml` — 可能需要新增 source 类型常量（仅当引用了 source 名字做判断时）
- 无其他文件需要修改（所有新源输出统一 JSON 格式，前端透明兼容）

## Step-by-Step Plan

### Phase 1: 低挂果实 — LRCLIB 集成（最简单的开放 API）

- [ ] **1.1** 实现 `fetch_lrclib(title, artist)` 函数
  - 搜索端点: `GET https://lrclib.net/api/search?track_name=...&artist_name=...`
  - 获取端点: `GET https://lrclib.net/api/get?track_name=...&artist_name=...&duration=...`
  - 返回 `syncedLyrics` (LRC 格式) 和 `plainLyrics` (纯文本)
  - 解析 syncedLyrics 用已有的 `parse_lrc()` 函数
  - source 名称: `"lrclib"`
  - 超时 5s，异常静默回退

- [ ] **1.2** 整合进优先级链（Phase 5 统一调整）

### Phase 2: 酷狗音乐 KRC 集成（逐字歌词 + 解密）

- [ ] **2.1** 实现 KRC 解密函数 `_decrypt_krc(encrypted_base64)`
  - 密钥: `[0x40, 0x47, 0x61, 0x77, 0x5e, 0x32, 0x74, 0x47, 0x51, 0x36, 0x31, 0x2d, 0xce, 0xd2, 0x6e, 0x69]`
  - 步骤: Base64 解码 → 丢弃前 4 字节 → XOR 逐字节解密 → zlib 解压 → 去掉首字符 → UTF-8 文本
  - 使用 Python stdlib `zlib.decompress(data, -15)` (raw deflate)
  - 参考: Lyricify `Decrypter/Krc/Decrypter.cs` + `Helper.cs`

- [ ] **2.2** 实现 KRC 解析函数 `parse_krc(krc_text)`
  - 元数据行: `[id:...]`, `[ar:...]`, `[ti:...]`, `[language:...]` 等
  - 歌词行格式: `[lineStartMs, lineDurationMs]<wordStartMs, wordDurationMs, 0>文字<...>文字`
  - 解析逐字时间，转换为统一格式 (秒为单位)
  - 提取 `[language:...]` Base64 翻译内容（可选，目前 quickshell 不展示翻译）
  - 参考: Lyricify `Parsers/KrcParser.cs` + `Decrypter/Krc/Model.cs`

- [ ] **2.3** 实现 `fetch_kugou(title, artist)` 函数
  - Step 1: 搜索歌曲 `GET http://mobilecdn.kugou.com/api/v3/search/song?format=json&keyword=...&page=1&pagesize=5&showtype=1`
  - Step 2: 搜索歌词 `GET https://lyrics.kugou.com/search?ver=1&man=yes&client=pc&keyword=...&duration=...&hash=...`
  - Step 3: 下载歌词 `GET https://lyrics.kugou.com/download?ver=1&client=pc&id={id}&accesskey={accesskey}&fmt=krc&charset=utf8`
  - Step 4: 解密 + 解析 KRC
  - source 名称: `"kugou-krc"` (word-level) / `"kugou-lrc"` (line-level fallback)

### Phase 3: Musixmatch 集成（逐字歌词，自动 Token）

- [ ] **3.1** 实现 Musixmatch Token 管理
  - 端点: `GET https://apic-desktop.musixmatch.com/ws/1.1/token.get?app_id=web-desktop-app-v1.0&t={random_letters}`
  - 缓存 user_token（模块级变量），过期/401时自动刷新
  - 处理 captcha 限流 (429/401 "captcha" hint → sleep 1s 重试最多3次)
  - 不需要任何用户密钥

- [ ] **3.2** 实现 Musixmatch 富同步歌词解析 `parse_musixmatch_richsync(richsync_json)`
  - 格式: `[{"ts": 0.0, "te": 5.0, "l": [{"c": "Hello", "o": 0.0}, ...], "x": "Hello world"}, ...]`
  - ts/te = 行时间 (秒), l[].c = 字, l[].o = 字在行内偏移(秒)
  - 转换为统一格式
  - 参考: Lyricify `Parsers/MusixmatchParser.cs` + `Models/Musixmatch.cs`

- [ ] **3.3** 实现 `fetch_musixmatch(title, artist, duration_sec=None)` 函数
  - 搜索+获取一体化: `GET macro.subtitles.get?namespace=lyrics_richsynched&optional_calls=track.richsync&subtitle_format=lrc&q_track=...&q_artist=...&q_duration=...`
  - 若返回 `track.richsync.get` 有数据 → 逐字歌词
  - 否则回退 `track.subtitles.get` → LRC 行级歌词
  - 否则回退 `track.lyrics.get` → 纯文本
  - source 名称: `"musixmatch-richsync"` / `"musixmatch-lrc"` / `"musixmatch-plain"`

### Phase 4: Apple Music 集成（TTML 逐字歌词）

- [ ] **4.1** 实现 Apple Music Access Token 获取
  - 步骤 1: `GET https://music.apple.com/us/browse` 获取 HTML
  - 步骤 2: 正则提取 `index*.js` 文件 URL
  - 步骤 3: 获取 JS 文件，正则提取 JWT token (`eyJ...`)
  - 步骤 4: 验证 token 有效性（解码 JWT payload 检查 exp）
  - 缓存 token，过期前1分钟自动刷新
  - 参考: Lyricify `Api.cs` 中的 `GetAccessTokenAsync`, `FindIndexScriptUrls`, `FindAccessTokenInScript`

- [ ] **4.2** 实现 Apple Music 搜索
  - 端点: `GET https://amp-api.music.apple.com/v1/catalog/us/search?term=...&types=songs&limit=5&l=en-US`
  - Authorization: `Bearer {accessToken}`
  - Origin: `https://music.apple.com`

- [ ] **4.3** 实现 Apple Music 歌词获取
  - 端点: `GET https://amp-api.music.apple.com/v1/catalog/us/songs/{id}?include[songs]=syllable-lyrics&l=zh-hans-cn&extend=ttmlLocalizations`
  - 返回 `data[0].relationships.syllable-lyrics.data[0].attributes.ttmlLocalizations` (或 fallback `ttml`)
  - 解析 TTML 用已有的 `parse_ttml()` 函数（格式兼容）
  - source 名称: `"apple-music"`

### Phase 5: 汽水音乐 (SodaMusic) 集成

- [ ] **5.1** 实现 `fetch_sodamusic(title, artist)` 函数
  - 搜索: `GET https://api.qishui.com/luna/pc/search/track?q=...&aid=386088&app_name=luna_pc&device_id=...&version_code=2.1.0...`
  - 获取详情: `POST https://api.qishui.com/luna/pc/track_v2` 带 `track_id`
  - 返回: `lyric.content` (可能是 LRC 文本)
  - User-Agent: `LunaPC/2.1.0(12292405)`
  - source 名称: `"sodamusic"`

### Phase 6: 网易云增强（eapi 端点）

- [ ] **6.1** 新增 `fetch_netease_eapi(title, artist)` 作为增强备选
  - 使用 `interface3.music.163.com/eapi/song/lyric/v1` 端点
  - 支持 `yv`, `ytv`, `yrv` 参数获取更多变体
  - 实现 EAPI AES-ECB 签名（参考 Lyricify `EapiHelper.cs`）
  - 注意：当前 weapi 已有 YRC 逐字支持，eapi 主要增加罗马音和翻译
  - 标记为可选增强（翻译不阻塞主流程）

### Phase 7: QQ音乐增强

- [ ] **7.1** 补充 QQ音乐 XML 歌词下载端点
  - 使用 `c.y.qq.com/qqmusic/fcgi-bin/lyric_download.fcg` 端点
  - 参数: `version=15&miniversion=82&lrctype=4&musicid={songid}`
  - 返回 XML，提取 `orig` (原文) + `ts` (翻译)
  - QRC 内容用已有的 Triple DES 解密
  - 注意：当前移动端 API 已经实现 QRC 获取，此端点可作为稳定回退

### Phase 8: Spotify 集成（从浏览器提取 sp_dc，仿 yt-dlp）

- [ ] **8.1** 实现 `_get_spotify_sp_dc()` — 从浏览器自动提取 cookie
  - 仿 `yt-dlp` 的 `--cookies-from-browser` 机制
  - 使用 Python stdlib `sqlite3` 读取 Chromium/Firefox cookie 数据库
  - Chromium: `~/.config/chromium/Default/Cookies` 或 `~/.config/google-chrome/Default/Cookies`
  - Firefox: `~/.mozilla/firefox/*.default-release/cookies.sqlite`
  - 查询 `sp_dc` cookie（domain: `.spotify.com`）
  - 若无法读取，回退到环境变量 `SPOTIFY_SP_DC`
  - 若都不可用，跳过 Spotify 源（不报错）

- [ ] **8.2** 实现 Spotify Token 刷新
  - Token 端点: `https://open.spotify.com/api/token`
  - 需生成 TOTP（HMAC-SHA1, 30s period, 6 digits）
  - Secret key 从 GitHub (`spot-secrets-go`) 获取，含内置 fallback JSON
  - 用 `sp_dc` cookie 换取 access token
  - 参考: Lyricify `Api.cs` 中的 `RefreshAccessTokenAsync`, `BuildTokenParametersAsync`, `GenerateTotp`

- [ ] **8.3** 实现 Spotify 搜索 + 歌词获取
  - 搜索: `pathfinder` GraphQL endpoint (`api-partner.spotify.com/pathfinder/v1/query`)
  - 回退: Web API (`api.spotify.com/v1/search`)
  - 歌词: `https://spclient.wg.spotify.com/color-lyrics/v2/track/{id}?format=json&market=from_token`
  - 解析: SYLLABLE_SYNCED → 逐字 / LINE_SYNCED → 行级 / UNSYNCED → 纯文本
  - source 名称: `"spotify-syllable"` / `"spotify-line"` / `"spotify-plain"`

### Phase 9: 优先级链调整

- [ ] **9.1** 调整 `fetch_lyrics()` 中的优先级链为:

```
TTML (AMLL DB)           → 逐字（已有）
  ↓ 失败
QQ 音乐 QRC              → 逐字（已有）
  ↓ 失败
Musixmatch RichSync      → 逐字（新增）
  ↓ 失败
Apple Music TTML         → 逐字（新增）
  ↓ 失败
Spotify Syllable         → 逐字（新增，自动提取 sp_dc）
  ↓ 失败
网易云 YRC               → 逐字（已有）
  ↓ 失败
酷狗 KRC                 → 逐字（新增）
  ↓ 失败
LRCLIB                   → 行级（新增）
  ↓ 失败
QQ 音乐 LRC              → 行级（已有）
  ↓ 失败
网易云 LRC               → 行级（已有）
  ↓ 失败
汽水音乐                 → 行级（新增）
  ↓ 失败
所有源都失败 → "未找到歌词"
```

- [ ] **9.2** 全源并发获取，渐进式优先级升级（核心架构改造）
  - 使用 `concurrent.futures.ThreadPoolExecutor` 同时启动所有源的 fetch
  - 所有源立即并发执行（不是排队串行）
  - **渐进式输出协议**:
    - 第一个完成的源（任意优先级）→ 立即 emit JSON（`_update: false`，快速展示歌词）
    - 后续更高优先级的源完成时 → emit 升级 JSON（`_update: true`，前端切换到更好歌词）
    - 同优先级或更低优先级的源完成后不 emit（避免降级）
  - Daemon 模式：同一请求可产出多条 JSON line，每条独立 flush
  - CLI 模式：增加 `--wait-best` 选项，等待最高优先级源完成后再输出（默认行为：先输出最快的，再持续升级直到超时 8s）
  - 实现细节：
    - `fetch_lyrics_async(title, artist, callback)` — 并发版核心函数
    - 用 `ThreadPoolExecutor` + `as_completed` 接收结果
    - 维护 `best_source_priority` 状态，仅当新结果优先级更高时触发 callback
    - 后台线程继续等待更高优先级源，不阻塞已返回结果

### Phase 10: 并发框架 + 渐进式升级协议

- [ ] **10.1** 实现 `fetch_lyrics_async(title, artist)` — ThreadPool 并发版
  - 同时启动所有源（不限优先级）
  - 用 `concurrent.futures.as_completed` 接收最先返回的结果
  - 维护 `_emitted_priority` 状态，仅当新结果优先级更高时 yield

- [ ] **10.2** 更新 Daemon 模式协议
  - 每个请求可产出多条 JSON line（第一条 `_update: false`，后续 `_update: true`）
  - 前端收到 `_update: true` 时替换当前歌词（不创建新行）

- [ ] **10.3** 更新 `LyricsDaemon.qml` 的 `SplitParser.onRead`
  - 解析 `_update` 字段
  - `_update: false` → 正常流程（新歌曲歌词）
  - `_update: true` → 直接替换 `LyricsSyncEngine` 的当前歌词数据

- [ ] **10.4** CLI 模式:
  - 默认行为: 输出第一条结果后，继续等待最高优先级源（最长 8s），输出最终最佳结果
  - `--fast` 选项: 输出第一条结果后立即退出
  - `--wait-best` 选项: 等待所有源完成或超时 8s，只输出最佳结果

### Phase 11: 测试与文档

- [ ] **10.1** 添加 CLI 测试模式：`python3 lyrics_fetcher.py --test "歌曲名" "歌手名"` 打印所有源的结果
- [ ] **10.2** 用 5 首中英文歌曲手动测试每个源
- [ ] **10.3** 更新 `AGENTS.md` 中的歌词源列表

## Risks & Considerations

1. **Musixmatch 限流风险**: 免费 API 无官方文档，可能遇到 401 captcha 限流。需要重试+退避策略，且不阻塞主流程（捕获异常静默跳过）

2. **Apple Music Token 失效**: Apple 可能更新 JS 结构导致 token 提取正则失效。需要用 try/except 包裹所有 Apple Music 调用，失败则静默回退

3. **KRC 解密依赖**: XOR + zlib 解密在不同版本酷狗可能变化。参考 Lyricify 的现有实现，它已在生产环境验证

4. **汽水音乐 API 稳定性**: 作为字节跳动旗下产品，API 可能随时变更域名或参数。标记为低优先级源

5. **Spotify sp_dc**: 需要用户自己从浏览器提取 cookie，不适合作为开箱即用的功能。建议作为可选配置

6. **Python 依赖**: 所有功能使用 stdlib（zlib, base64, hashlib, json, urllib, xml.etree.ElementTree），无需新增 pip 依赖。Triple DES 已自实现，KRC XOR 解密简单

7. **向后兼容**: 新 source 名称直接嵌入 `_legacy[0].text`（如 `[来源: kugou-krc]`），前端无需任何改动

8. **网络超时**: 每个源的 API 调用超时设为 5-8s，避免用户等待过久。Apple Music 需要额外的 JS 抓取步骤，总超时可放宽到 10s

## Estimated Impact

- **文件修改**: 1 (`scripts/media/lyrics_fetcher.py`)
- **新增代码量**: ~800-1000 行 Python + ~30 行 QML
- **新增函数**: ~15 个 (6× fetch_*, decrypt_krc, parse_krc, parse_musixmatch, parse_spotify, get_sp_dc, 并发框架函数等)
- **破坏性变更**: 极低（纯增量，输出 JSON 新增 `_update` 字段，前端需要处理但向后兼容）
- **新增源数量**: 6 个新歌词源（全部并发）
- **并发模型**: ThreadPoolExecutor 全源并发 + 渐进式优先级升级

## 实施顺序建议

按可行性/价值排序:

| 顺序 | Phase | 源 | 理由 |
|------|-------|-----|------|
| 1 | Phase 1 | Musixmatch | 全球最大歌词库，逐字质量高，自动Token |
| 2 | Phase 2 | Apple Music | TTML逐字质量最高，自动 JWT |
| 3 | Phase 3 | Spotify | 浏览器提取 sp_dc，逐字 |
| 4 | Phase 4 | 酷狗 KRC | 中文歌曲覆盖好，逐字+翻译 |
| 5 | Phase 5 | LRCLIB | 开放 LRC 库，零认证 |
| 6 | Phase 6 | 汽水音乐 | 中文歌曲补充 |
| 7 | Phase 7 | 并发框架 | ThreadPool 全源并发 + 渐进升级 |
| 8 | Phase 8 | QML 协议适配 | Daemon 多输出 → 前端升级处理 |
| 9 | Phase 9 | 优先级链 | 最终调整优先级常量 |
| 10 | Phase 10 | 测试 | 验证所有源 + 并发行为 |
