#!/usr/bin/env python3
"""歌词获取器 — 多源获取 + 多格式解析 + 统一输出 + 向后兼容

数据源: 网易云 YRC / LRC, QQ音乐 LRC（QRC 暂不可用）
输出格式:
{
    "format": "word" | "line",
    "source": "netease-yrc" | "netease-lrc" | "qq-lrc",
    "lines": [
        {"time": 12.34, "text": "完整行文本", "words": [
            {"word": "字", "startTime": 12.34, "endTime": 12.56}
        ]}
    ],
    "_legacy": [
        {"time": 12.34, "text": "完整行文本"}
    ]
}
"""

import sys
import json
import urllib.request
import urllib.parse
import re
import os
import hashlib
import base64

CACHE_DIR = "/tmp/qs_lyrics_cache"
V2_CACHE_DIR = os.path.join(CACHE_DIR, "v2")
os.makedirs(V2_CACHE_DIR, exist_ok=True)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}


# ============================================================
# 缓存
# ============================================================

def get_cache_path(title, artist):
    safe_name = f"{title}-{artist}".encode("utf-8", errors="ignore")
    hash_str = hashlib.md5(safe_name).hexdigest()
    return os.path.join(V2_CACHE_DIR, f"{hash_str}.json")


# ============================================================
# LRC 解析 (标准 + 增强格式)
# ============================================================

def parse_lrc(lrc_text):
    """解析标准 LRC。

    格式: [mm:ss.xx]歌词文本
    也支持增强 LRC: [mm:ss.xx]<mm:ss.xx>字<mm:ss.xx>字
    逐字 LRC: [mm:ss.xx]字[mm:ss.xx]字
    """
    if not lrc_text:
        return []

    lrc_text = (
        lrc_text.replace("&apos;", "'")
        .replace("&quot;", '"')
        .replace("&amp;", "&")
    )

    # 先尝试逐字/增强格式解析
    enhanced = _parse_enhanced_lrc(lrc_text)
    if enhanced:
        return enhanced

    # 回退到标准行级解析
    return _parse_standard_lrc(lrc_text)


# ============================================================
# 歌词元数据过滤 (移植自 SPlayer 的 META_TAG_REGEX 逻辑)
# ============================================================

# SPlayer 的 ISO 标准 LRC 标签过滤: [ti:], [ar:], [al:], [by:], [offset:], 等
# 直接移植自 SPlayer: src/utils/lyric/lyricParser.ts
_META_TAG_REGEX = re.compile(r'^\[[a-z]+:', re.IGNORECASE)

# 中文制作信息标签 (非 ISO 标准, 补充过滤)
_CN_META_REGEX = re.compile(
    r'^\s*('  # 允许前导空格
    # 长标签在前 (避免短标签抢先匹配)
    r'母带后期处理工程师|母带后期处理录音室|音乐制作助理|'
    r'和声编写|合声编写|混音工程|'
    r'录音工作室|混音工作室|母带后期|母带制作|'
    r'录音工程|录音助理|录音室|混音室|母带室|'
    r'录音师|混音师|母带工程师|制作助理|音乐助理|'
    r'词|曲|编曲|作词|作曲|制作人?|监制|出品人?|出品|发行|'
    r'吉他|贝斯|鼓|键盘|钢琴|小提琴|中提琴|大提琴|弦乐|管乐|'
    r'和声|合声|和音|合音|音乐制作|'
    r'录音|混音|母带'
    r')\s*[:：]',
)

# 英文制作信息标签 (OP/SP/ISRC 等)
_EN_META_REGEX = re.compile(
    r'^\s*(OP|SP|ISRC|UPC|EAN|ISWC)\s*[:：-]',
    re.IGNORECASE
)



def _is_metadata(text):
    """检测歌词行文本是否为元数据。
    
    移植自 SPlayer lyriParser.ts 的三层过滤:
    1. META_TAG_REGEX — ISO 标准 LRC 标签 ([ti:], [ar:], 等)
    2. CN_META_REGEX — 中文制作信息 (词：, 录音工作室：, 等)
    3. EN_META_REGEX — 英文制作信息 (OP:, SP:, ISRC:, 等)
    4. 歌名行检测 ("歌曲 - 歌手" 模式)
    """
    if not text:
        return True
    t = text.strip()
    if not t:
        return True
    # SPlayer: ISO LRC 标签
    if _META_TAG_REGEX.match(t):
        return True
    # 中文制作信息
    if _CN_META_REGEX.match(t):
        return True
    # 英文制作信息 (OP/SP/ISRC)
    if _EN_META_REGEX.match(t):
        return True
    # 歌名行: "歌曲 - 歌手" 模式 (非歌词内容)
    if ' - ' in t and 3 < len(t) < 80 and '：' not in t and ':' not in t:
        return True
    return False

def _parse_standard_lrc(lrc_text):
    """标准行级 LRC 解析。"""
    lines = []
    pattern = re.compile(r"\[(\d{2}):(\d{2})[\.:](\d{2,3})\](.*)")

    for line in lrc_text.split("\n"):
        line = line.strip()
        if not line:
            continue
        match = pattern.match(line)
        if match:
            minutes = int(match.group(1))
            seconds = int(match.group(2))
            ms_str = match.group(3)
            if len(ms_str) == 2:
                ms = int(ms_str) * 10
            else:
                ms = int(ms_str)
            total_seconds = minutes * 60 + seconds + ms / 1000
            text = match.group(4).strip()
            if text and not _is_metadata(text):
                lines.append({
                    "time": total_seconds,
                    "text": text,
                    "words": [{"word": text, "startTime": total_seconds, "endTime": total_seconds + 5.0}]
                })

    lines.sort(key=lambda x: x["time"])
    return lines


def _parse_enhanced_lrc(lrc_text):
    """解析增强 LRC (带逐字时间标签)。

    增强格式: [mm:ss.xx]<mm:ss.xx>字<mm:ss.xx>字
    逐字格式: [mm:ss.xx]字[mm:ss.xx]字
    返回带有 words 数组的 lines, 或 None (如果无逐字数据则返回 None 让调用方回退)。
    """
    # 检测是否包含增强格式的 <mm:ss.xx> 标签
    if "<" not in lrc_text or ">" not in lrc_text:
        # 尝试逐字格式 [mm:ss.xx]字[mm:ss.xx]字
        if lrc_text.count("[") > len(lrc_text.split("\n")) * 2:
            return _parse_word_by_word_lrc(lrc_text)
        return None

    lines = []
    # 行级时间匹配
    line_pattern = re.compile(r"\[(\d{2}):(\d{2})[\.:](\d{2,3})\](.*)")

    for raw_line in lrc_text.split("\n"):
        raw_line = raw_line.strip()
        if not raw_line:
            continue

        # SPlayer: 过滤 ISO 元数据标签 [ti:], [ar:], 等
        if _META_TAG_REGEX.match(raw_line):
            continue

        match = line_pattern.match(raw_line)
        if not match:
            continue
        minutes = int(match.group(1))
        seconds = int(match.group(2))
        ms_str = match.group(3)
        if len(ms_str) == 2:
            ms = int(ms_str) * 10
        else:
            ms = int(ms_str)
        line_start = minutes * 60 + seconds + ms / 1000

        content = match.group(4).strip()
        if not content:
            continue

        # 解析增强标签 <mm:ss.xx>字
        word_pattern = re.compile(r"<(\d{2}):(\d{2})[\.:](\d{2,3})>([^<]*)")
        words = []
        full_text = ""
        for wm in word_pattern.finditer(content):
            w_min = int(wm.group(1))
            w_sec = int(wm.group(2))
            w_ms_str = wm.group(3)
            if len(w_ms_str) == 2:
                w_ms = int(w_ms_str) * 10
            else:
                w_ms = int(w_ms_str)
            w_start = w_min * 60 + w_sec + w_ms / 1000
            w_text = wm.group(4) or ""
            words.append({
                "word": w_text,
                "startTime": w_start,
                "endTime": w_start + 0.3  # 默认 300ms
            })
            full_text += w_text

        if not full_text:
            full_text = content
            words = [{"word": full_text, "startTime": line_start, "endTime": line_start + 5.0}]

        # 修正 endTime: 每个字的 endTime = 下一个字的 startTime
        for i in range(len(words) - 1):
            words[i]["endTime"] = words[i + 1]["startTime"]

        has_word_level = len(words) > 1
        lines.append({
            "time": line_start,
            "text": full_text,
            "words": words if has_word_level else [{"word": full_text, "startTime": line_start, "endTime": line_start + 5.0}]
        })

    if not lines:
        return None

    # 检查是否有真正的逐字数据(超过 50% 的行有多个 words)
    word_level_count = sum(1 for l in lines if len(l["words"]) > 1)
    if word_level_count > len(lines) * 0.3:
        lines.sort(key=lambda x: x["time"])
        return lines

    return None


def _parse_word_by_word_lrc(lrc_text):
    """解析逐字 LRC 格式: [mm:ss.xx]字[mm:ss.xx]字...[mm:ss.xx]字"""
    time_pattern = re.compile(r"\[(\d{2}):(\d{2})[\.:](\d{2,3})\]")

    lines = []
    raw_lines = lrc_text.split("\n")

    for raw_line in raw_lines:
        raw_line = raw_line.strip()
        if not raw_line:
            continue

        # SPlayer: 过滤 ISO 元数据标签 [ti:], [ar:], 等
        if _META_TAG_REGEX.match(raw_line):
            continue

        # 找出所有时间标签
        matches = list(time_pattern.finditer(raw_line))
        if len(matches) < 2:
            continue

        # 提取每对 (time, text)
        word_entries = []
        full_text = ""
        for i, m in enumerate(matches):
            minutes = int(m.group(1))
            seconds = int(m.group(2))
            ms_str = m.group(3)
            if len(ms_str) == 2:
                ms = int(ms_str) * 10
            else:
                ms = int(ms_str)
            t = minutes * 60 + seconds + ms / 1000

            # 获取该标签后的文本(到下一个标签前)
            start = m.end()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(raw_line)
            text = raw_line[start:end].strip()
            word_entries.append((t, text))
            full_text += text

        if not full_text:
            continue

        line_start = word_entries[0][0]
        words = []
        for i, (t, txt) in enumerate(word_entries):
            if not txt:
                continue
            end_time = word_entries[i + 1][0] if i + 1 < len(word_entries) else t + 2.0
            words.append({"word": txt, "startTime": t, "endTime": end_time})

        has_word_level = len(words) > 1
        lines.append({
            "time": line_start,
            "text": full_text,
            "words": words if has_word_level else [{"word": full_text, "startTime": line_start, "endTime": line_start + 5.0}]
        })

    if lines:
        lines.sort(key=lambda x: x["time"])
    return lines if lines else None


# ============================================================
# YRC 解析 (网易云逐字歌词)
# ============================================================

def parse_yrc(yrc_text):
    """解析网易云 YRC 格式。

    格式:
    [lineStartMs, lineDurationMs](wordStartMs, wordDurationMs, 0)字(wordStartMs, wordDurationMs, 0)字...

    时间均为毫秒, 需转换为秒。
    """
    if not yrc_text:
        return []

    lines = []
    # 匹配行头: [startMs, durationMs]
    line_pattern = re.compile(r"^\[(\d+),(\d+)\](.*)$")

    for raw_line in yrc_text.split("\n"):
        raw_line = raw_line.strip()
        if not raw_line:
            continue

        # SPlayer: 过滤 ISO 元数据标签 [ti:], [ar:], 等
        if _META_TAG_REGEX.match(raw_line):
            continue

        line_match = line_pattern.match(raw_line)
        if not line_match:
            continue

        line_start_ms = int(line_match.group(1))
        line_start = line_start_ms / 1000.0

        content = line_match.group(3)

        # 解析逐字标签: (startMs, durationMs, flag)字
        word_pattern = re.compile(r"\((\d+),(\d+),\d+\)([^(]*)")
        words = []
        full_text = ""

        for wm in word_pattern.finditer(content):
            w_start_ms = int(wm.group(1))
            w_dur_ms = int(wm.group(2))
            w_start = w_start_ms / 1000.0
            w_dur = w_dur_ms / 1000.0
            w_text = wm.group(3) or ""

            words.append({
                "word": w_text,
                "startTime": w_start,
                "endTime": w_start + w_dur if w_dur > 0 else w_start + 0.3
            })
            full_text += w_text

        if not full_text:
            continue

        # 跳过元数据行 (作词/作曲/编曲等)
        if _is_metadata(full_text):
            continue

        # 修正: 每个字的 endTime 要么用 duration, 要么用下一个字的 startTime
        for i in range(len(words) - 1):
            if words[i]["endTime"] > words[i + 1]["startTime"]:
                words[i]["endTime"] = words[i + 1]["startTime"]

        has_word_level = len(words) > 1
        lines.append({
            "time": line_start,
            "text": full_text,
            "words": words if has_word_level else [{"word": full_text, "startTime": line_start, "endTime": line_start + 5.0}]
        })

    if lines:
        lines.sort(key=lambda x: x["time"])
    return lines


# ============================================================
# HTTP 请求辅助
# ============================================================

def request_url(url, data=None, headers=None):
    if headers is None:
        headers = HEADERS
    try:
        req = urllib.request.Request(url, data=data, headers=headers)
        with urllib.request.urlopen(req, timeout=5) as response:
            return json.loads(response.read().decode())
    except Exception:
        return None


# ============================================================
# QRC XML 解析器 (QQ音乐旧版，保留备用)
# ============================================================

def _parse_qrc(qrc_text):
    """解析 QQ 音乐 QRC (XML 格式逐字歌词)。

    格式:
    <lyric>
      <line startTime="0" duration="1000">字(0,200)字(200,300)</line>
    </lyric>
    """
    if not qrc_text or "<lyric>" not in qrc_text:
        return None

    try:
        import xml.etree.ElementTree as ET
        root = ET.fromstring(qrc_text.strip())
    except Exception:
        return None

    lines = []
    for line_elem in root.findall("line"):
        start_ms = int(line_elem.get("startTime", 0))
        start_time = start_ms / 1000.0
        content = (line_elem.text or "").strip()

        # 解析逐字: 字(startMs, durationMs)
        word_pattern = re.compile(r"([^(]+)\((\d+),(\d+)\)")
        words = []
        full_text = ""

        for wm in word_pattern.finditer(content):
            w_text = wm.group(1) or ""
            w_start_ms = int(wm.group(2))
            w_dur_ms = int(wm.group(3))
            w_start = w_start_ms / 1000.0
            w_end = w_start + w_dur_ms / 1000.0 if w_dur_ms > 0 else w_start + 0.3
            words.append({"word": w_text, "startTime": w_start, "endTime": w_end})
            full_text += w_text

        if not full_text:
            full_text = content
            words = [{"word": full_text, "startTime": start_time, "endTime": start_time + 5.0}]

        for i in range(len(words) - 1):
            if words[i]["endTime"] > words[i + 1]["startTime"]:
                words[i]["endTime"] = words[i + 1]["startTime"]

        has_word = len(words) > 1
        lines.append({
            "time": start_time,
            "text": full_text,
            "words": words if has_word else [{"word": full_text, "startTime": start_time, "endTime": start_time + 5.0}]
        })

    if lines:
        lines.sort(key=lambda x: x["time"])
    return lines if lines else None


# ============================================================
# TTML 解析 + AMLL DB 获取 (Apple Music-like Lyrics 逐字)
# ============================================================

_TTML_SERVER = "https://amlldb.bikonoo.com/ncm-lyrics/%s.ttml"


def _parse_ttml_time(ts):
    parts = ts.strip().split(":")
    if len(parts) == 3:
        return int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
    elif len(parts) == 2:
        return int(parts[0]) * 60 + float(parts[1])
    return 0.0


def parse_ttml(ttml_text):
    """解析 TTML XML 为统一格式: <p begin=...><span begin=...>字</span></p>"""
    import xml.etree.ElementTree as ET
    if not ttml_text or "<tt" not in ttml_text:
        return []
    try:
        root = ET.fromstring(ttml_text.strip())
    except Exception:
        return []
    ns = root.tag.split("}")[0].replace("{", "") if "}" in root.tag else ""
    # TTML 使用 default namespace, 子元素无需前缀
    lines = []
    for p in root.iter("p"):
        begin_str = p.get("begin", "")
        if not begin_str:
            continue
        line_time = _parse_ttml_time(begin_str)
        words = []
        full_parts = []
        for span in p.iter("span"):
            w_begin = span.get("begin", "")
            w_end = span.get("end", "")
            w_text = (span.text or "")
            w_tail = span.tail or ""  # SPlayer: 词间空格/标点 (span.tail)
            if not w_begin or not w_text.strip():
                full_parts.append(w_text)
                full_parts.append(w_tail)
                continue
            w_start = _parse_ttml_time(w_begin)
            w_end_time = _parse_ttml_time(w_end) if w_end else w_start + 0.3
            # 附着 tail (中文为空, 英文为空格/标点) 避免渲染时黏连
            words.append({"word": w_text + w_tail, "startTime": w_start, "endTime": w_end_time})
            full_parts.append(w_text)
            full_parts.append(w_tail)
        full_text = "".join(full_parts).strip()
        if not full_text or not words or _is_metadata(full_text):
            continue
        lines.append({"time": line_time, "text": full_text,
                       "words": words if len(words) > 1 else [{"word": full_text, "startTime": line_time, "endTime": line_time + 5.0}]})
    if lines:
        lines.sort(key=lambda x: x["time"])
    return lines


def fetch_ttml(ncm_id):
    """从 AMLL TTML DB 镜像获取逐字歌词。"""
    if not ncm_id:
        return None
    try:
        url = _TTML_SERVER.replace("%s", str(ncm_id))
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=5) as resp:
            raw = resp.read().decode("utf-8", errors="ignore")
            if raw and "<tt" in raw[:500]:
                lines = parse_ttml(raw)
                if lines:
                    return {"format": "word", "source": "ttml", "lines": lines}
    except Exception:
        pass
    return None


# ============================================================
# Triple DES 纯 Python 实现 (移植自 LDDC 项目)
# 用于解密 QQ 音乐 QRC 逐字歌词
# ============================================================

# S-boxes
_SBOX = [
    [14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7,0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8,4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0,15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13],
    [15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10,3,13,4,7,15,2,8,15,12,0,1,10,6,9,11,5,0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15,13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9],
    [10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8,13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1,13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7,1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12],
    [7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15,13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9,10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4,3,15,0,6,10,10,13,8,9,4,5,11,12,7,2,14],
    [2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9,14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6,4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14,11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3],
    [12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11,10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8,9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6,4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13],
    [4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1,13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6,1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2,6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12],
    [13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7,1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2,7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8,2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11],
]

_QRC_KEY = bytes("!@#)(*$%123ZXC!@!@#)(NHL", "utf8")


def _bitnum(data, b, c):
    idx = (b // 32) * 4 + 3 - ((b % 32) // 8)
    return ((data[idx] >> (7 - (b % 8))) & 1) << c

def _bitnum_intr(a, b, c):
    return ((a >> (31 - b)) & 1) << c

def _bitnum_intl(a, b, c):
    return ((a << b) & 0x80000000) >> c

def _sbox_bit(a):
    return (a & 32) | ((a & 31) >> 1) | ((a & 1) << 4)

def _init_perm(data):
    def bn(d, b, c):
        idx = (b // 32) * 4 + 3 - ((b % 32) // 8)
        return ((d[idx] >> (7 - (b % 8))) & 1) << c
    s0 = sum(bn(data, p[0], 31 - i) for i, p in enumerate(
        [(57,31),(49,30),(41,29),(33,28),(25,27),(17,26),(9,25),(1,24),
         (59,23),(51,22),(43,21),(35,20),(27,19),(19,18),(11,17),(3,16),
         (61,15),(53,14),(45,13),(37,12),(29,11),(21,10),(13,9),(5,8),
         (63,7),(55,6),(47,5),(39,4),(31,3),(23,2),(15,1),(7,0)])) & 0xFFFFFFFF
    s1 = sum(bn(data, p[0], 31 - i) for i, p in enumerate(
        [(56,31),(48,30),(40,29),(32,28),(24,27),(16,26),(8,25),(0,24),
         (58,23),(50,22),(42,21),(34,20),(26,19),(18,18),(10,17),(2,16),
         (60,15),(52,14),(44,13),(36,12),(28,11),(20,10),(12,9),(4,8),
         (62,7),(54,6),(46,5),(38,4),(30,3),(22,2),(14,1),(6,0)])) & 0xFFFFFFFF
    return s0, s1

def _inv_perm(s0, s1):
    data = bytearray(8)
    def bi(a, b, c): return ((a >> (31 - b)) & 1) << c
    data[3] = bi(s1,7,7)|bi(s0,7,6)|bi(s1,15,5)|bi(s0,15,4)|bi(s1,23,3)|bi(s0,23,2)|bi(s1,31,1)|bi(s0,31,0)
    data[2] = bi(s1,6,7)|bi(s0,6,6)|bi(s1,14,5)|bi(s0,14,4)|bi(s1,22,3)|bi(s0,22,2)|bi(s1,30,1)|bi(s0,30,0)
    data[1] = bi(s1,5,7)|bi(s0,5,6)|bi(s1,13,5)|bi(s0,13,4)|bi(s1,21,3)|bi(s0,21,2)|bi(s1,29,1)|bi(s0,29,0)
    data[0] = bi(s1,4,7)|bi(s0,4,6)|bi(s1,12,5)|bi(s0,12,4)|bi(s1,20,3)|bi(s0,20,2)|bi(s1,28,1)|bi(s0,28,0)
    data[7] = bi(s1,3,7)|bi(s0,3,6)|bi(s1,11,5)|bi(s0,11,4)|bi(s1,19,3)|bi(s0,19,2)|bi(s1,27,1)|bi(s0,27,0)
    data[6] = bi(s1,2,7)|bi(s0,2,6)|bi(s1,10,5)|bi(s0,10,4)|bi(s1,18,3)|bi(s0,18,2)|bi(s1,26,1)|bi(s0,26,0)
    data[5] = bi(s1,1,7)|bi(s0,1,6)|bi(s1,9,5)|bi(s0,9,4)|bi(s1,17,3)|bi(s0,17,2)|bi(s1,25,1)|bi(s0,25,0)
    data[4] = bi(s1,0,7)|bi(s0,0,6)|bi(s1,8,5)|bi(s0,8,4)|bi(s1,16,3)|bi(s0,16,2)|bi(s1,24,1)|bi(s0,24,0)
    return bytes(data)

def _des_f(state, key):
    t1 = (((state << 31) & 0xFFFFFFFF) | ((state & 0xF0000000) >> 1) | ((state << 4) & 0xFFFFFFFF) >> 5 | ((state << 3) & 0xFFFFFFFF) >> 6 | ((state & 0x0F000000) >> 3) | ((state << 8) & 0xFFFFFFFF) >> 11 | ((state << 7) & 0xFFFFFFFF) >> 12 | ((state & 0x00F00000) >> 5) | ((state << 12) & 0xFFFFFFFF) >> 17 | ((state << 11) & 0xFFFFFFFF) >> 18 | ((state & 0x000F0000) >> 7) | ((state << 16) & 0xFFFFFFFF) >> 23) & 0xFFFFFFFF
    t2 = (((state << 15) & 0xFFFFFFFF) | ((state & 0x0000F000) << 15) | ((state << 20) & 0xFFFFFFFF) >> 5 | ((state << 19) & 0xFFFFFFFF) >> 6 | ((state & 0x00000F00) << 13) | ((state << 24) & 0xFFFFFFFF) >> 11 | ((state << 23) & 0xFFFFFFFF) >> 12 | ((state & 0x000000F0) << 11) | ((state << 28) & 0xFFFFFFFF) >> 17 | ((state << 27) & 0xFFFFFFFF) >> 18 | ((state & 0x0000000F) << 9) | ((state << 0) & 0xFFFFFFFF) >> 23) & 0xFFFFFFFF
    lrg = [(t1 >> 24) & 0xFF ^ key[0], (t1 >> 16) & 0xFF ^ key[1], (t1 >> 8) & 0xFF ^ key[2],
           (t2 >> 24) & 0xFF ^ key[3], (t2 >> 16) & 0xFF ^ key[4], (t2 >> 8) & 0xFF ^ key[5]]
    state = ((_SBOX[0][_sbox_bit(lrg[0] >> 2)] << 28) | (_SBOX[1][_sbox_bit(((lrg[0] & 3) << 4) | (lrg[1] >> 4))] << 24) |
             (_SBOX[2][_sbox_bit(((lrg[1] & 0x0F) << 2) | (lrg[2] >> 6))] << 20) | (_SBOX[3][_sbox_bit(lrg[2] & 0x3F)] << 16) |
             (_SBOX[4][_sbox_bit(lrg[3] >> 2)] << 12) | (_SBOX[5][_sbox_bit(((lrg[3] & 3) << 4) | (lrg[4] >> 4))] << 8) |
             (_SBOX[6][_sbox_bit(((lrg[4] & 0x0F) << 2) | (lrg[5] >> 6))] << 4) | _SBOX[7][_sbox_bit(lrg[5] & 0x3F)]) & 0xFFFFFFFF
    def bl(a, b, c): return ((a << b) & 0xFFFFFFFF) >> c
    return (bl(state,15,0)|bl(state,6,1)|bl(state,19,2)|bl(state,20,3)|bl(state,28,4)|bl(state,11,5)|bl(state,27,6)|bl(state,16,7)|bl(state,0,8)|bl(state,14,9)|bl(state,22,10)|bl(state,25,11)|bl(state,4,12)|bl(state,17,13)|bl(state,30,14)|bl(state,9,15)|bl(state,1,16)|bl(state,7,17)|bl(state,23,18)|bl(state,13,19)|bl(state,31,20)|bl(state,26,21)|bl(state,2,22)|bl(state,8,23)|bl(state,18,24)|bl(state,12,25)|bl(state,29,26)|bl(state,5,27)|bl(state,21,28)|bl(state,10,29)|bl(state,3,30)|bl(state,24,31)) & 0xFFFFFFFF

def _des_crypt(data, key):
    s0, s1 = _init_perm(data)
    for idx in range(15):
        s1, s0 = (_des_f(s1, key[idx]) ^ s0) & 0xFFFFFFFF, s1
    s0 = (_des_f(s1, key[15]) ^ s0) & 0xFFFFFFFF
    return _inv_perm(s0, s1)

def _key_schedule(key, mode):
    ENC, DEC = 1, 0
    shift = [1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1]
    permC = [56,48,40,32,24,16,8,0,57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35]
    permD = [62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,60,52,44,36,28,20,12,4,27,19,11,3]
    comp = [13,16,10,23,0,4,2,27,14,5,20,9,22,18,11,3,25,7,15,6,26,19,12,1,40,51,30,36,46,54,29,39,50,44,32,47,43,48,38,55,33,52,45,41,49,35,28,31]
    c = sum(((key[p[0] // 8] >> (7 - p[0] % 8)) & 1) << (31 - i) for i, p in enumerate([(x, 0) for x in permC])); tmp = 0
    c = sum(((key[pc // 8] >> (7 - pc % 8)) & 1) << (31 - i) for i, pc in enumerate(permC)) & 0xFFFFFFFF
    d = sum(((key[pd // 8] >> (7 - pd % 8)) & 1) << (31 - i) for i, pd in enumerate(permD)) & 0xFFFFFFFF
    sched = [[0]*6 for _ in range(16)]
    for i in range(16):
        c = ((c << shift[i]) | (c >> (28 - shift[i]))) & 0x0FFFFFFF
        d = ((d << shift[i]) | (d >> (28 - shift[i]))) & 0x0FFFFFFF
        togen = 15 - i if mode == DEC else i
        for j in range(24):
            sched[togen][j // 8] |= ((c >> (31 - comp[j])) & 1) << (7 - (j % 8))
        for j in range(24, 48):
            sched[togen][j // 8] |= ((d >> (31 - (comp[j] - 27))) & 1) << (7 - (j % 8))
    return sched

def _triple_des_crypt(data, key, mode):
    ENC, DEC = 1, 0
    if mode == ENC:
        keys = [_key_schedule(key[0:8], ENC), _key_schedule(key[8:16], DEC), _key_schedule(key[16:24], ENC)]
    else:
        keys = [_key_schedule(key[16:24], DEC), _key_schedule(key[8:16], ENC), _key_schedule(key[0:8], DEC)]
    result = bytearray()
    for i in range(0, len(data), 8):
        block = data[i:i+8]
        if len(block) < 8:
            block = block + b'\x00' * (8 - len(block))
        for k in keys:
            block = _des_crypt(block, k)
        result.extend(block[:len(data[i:i+8])])
    return bytes(result)


def _decrypt_qrc(encrypted_hex):
    """解密 QQ 音乐 QRC 歌词 (Triple DES + zlib 解压)。"""
    import zlib
    if not encrypted_hex or encrypted_hex.strip() == "":
        return None
    try:
        encrypted_data = bytes.fromhex(encrypted_hex.strip())
    except Exception:
        return None
    decrypted = _triple_des_crypt(encrypted_data, _QRC_KEY, 0)
    # 尝试 zlib 解压
    for decompress in [lambda d: zlib.decompress(d, -15), zlib.decompress, lambda d: zlib.decompress(d, 15 + 32)]:
        try:
            return decompress(decrypted).decode("utf8", errors="ignore")
        except Exception:
            continue
    # 可能未压缩
    try:
        return decrypted.decode("utf8", errors="ignore")
    except Exception:
        return None


# ============================================================
# QQ音乐获取 (移动端 API — 支持 QRC 逐字)
# ============================================================

_QQ_SESSION_CACHE = {"uid": "", "sid": "", "userip": "", "expire": 0}


def _qq_init_session():
    """初始化 QQ 音乐移动端会话。"""
    import time
    if _QQ_SESSION_CACHE["uid"] and _QQ_SESSION_CACHE["expire"] > time.time():
        return
    try:
        payload = json.dumps({
            "comm": {"ct": 11, "cv": "1003006", "v": "1003006", "os_ver": "15",
                       "phonetype": "24122RKC7C", "tmeAppID": "qqmusiclight",
                       "nettype": "NETWORK_WIFI", "udid": "0"},
            "request": {"method": "GetSession", "module": "music.getSession.session",
                         "param": {"caller": 0, "uid": "0", "vkey": 0}}
        }).encode()
        req = urllib.request.Request(
            "https://u.y.qq.com/cgi-bin/musicu.fcg",
            data=payload,
            headers={"Content-Type": "application/json", "User-Agent": "okhttp/3.14.9"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            if data.get("code") == 0 and data.get("request", {}).get("code") == 0:
                session = data["request"]["data"]["session"]
                import time
                _QQ_SESSION_CACHE["uid"] = session.get("uid", "")
                _QQ_SESSION_CACHE["sid"] = session.get("sid", "")
                _QQ_SESSION_CACHE["userip"] = session.get("userip", "")
                _QQ_SESSION_CACHE["expire"] = time.time() + 3600
    except Exception:
        pass


def _qq_api(method, module, param):
    """调用 QQ 音乐移动端 API。"""
    _qq_init_session()
    comm = {"ct": 11, "cv": "1003006", "v": "1003006", "os_ver": "15",
            "phonetype": "24122RKC7C", "tmeAppID": "qqmusiclight",
            "nettype": "NETWORK_WIFI", "udid": "0"}
    if _QQ_SESSION_CACHE["uid"]:
        comm["uid"] = _QQ_SESSION_CACHE["uid"]
        comm["sid"] = _QQ_SESSION_CACHE["sid"]
        comm["userip"] = _QQ_SESSION_CACHE["userip"]
    payload = json.dumps({"comm": comm, "request": {"method": method, "module": module, "param": param}}).encode()
    req = urllib.request.Request(
        "https://u.y.qq.com/cgi-bin/musicu.fcg",
        data=payload,
        headers={"Content-Type": "application/json", "User-Agent": "okhttp/3.14.9"}
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = json.loads(resp.read())
        if data.get("code") == 0 and data.get("request", {}).get("code") == 0:
            return data["request"]["data"]
        return None


def fetch_qq(track, artist):
    """获取 QQ 音乐歌词。
    
    双轨策略:
    1. 移动端 API (u.y.qq.com) — 支持 QRC 逐字, 但 Triple DES 解密在纯 Python 下不稳定
    2. 旧版 API (c.y.qq.com) — 稳定 LRC 回退
    """
    import base64 as b64

    # === 策略 1: 旧版 LRC 端点 (稳定, 先拉取保底) ===
    lrc_lines = None
    try:
        qq_headers = {
            "User-Agent": HEADERS["User-Agent"],
            "Referer": "https://y.qq.com/",
        }
        keyword = f"{track} {artist}"
        search_url = (
            "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
            f"?w={urllib.parse.quote(keyword)}&format=json"
        )
        search_data = request_url(search_url, headers=qq_headers)
        songmid = ""
        if search_data and search_data.get("data", {}).get("song", {}).get("list"):
            songmid = search_data["data"]["song"]["list"][0].get("songmid", "")
        if songmid:
            lyric_url = (
                "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg"
                f"?songmid={songmid}&format=json&nobase64=1"
            )
            lyric_data = request_url(lyric_url, headers=qq_headers)
            if lyric_data and "lyric" in lyric_data and lyric_data["lyric"]:
                raw_lrc = lyric_data["lyric"]
                try:
                    decoded_lrc = base64.b64decode(raw_lrc).decode("utf-8")
                except Exception:
                    decoded_lrc = raw_lrc
                lrc_lines = parse_lrc(decoded_lrc)
    except Exception:
        pass

    # === 策略 2: 移动端 QRC (尝试获取逐字) ===
    try:
        search_id = str(
            (hashlib.md5(keyword.encode()).digest()[0] & 0x0F) * 18014398509481984 +
            (hashlib.md5(keyword.encode()).digest()[1] & 0x0F) * 4294967296 +
            (int(hashlib.md5(keyword.encode()).digest()[2:4].hex(), 16) % 86400000)
        )
        result = _qq_api("DoSearchForQQMusicLite", "music.search.SearchCgiService", {
            "search_id": search_id,
            "remoteplace": "search.android.keyboard",
            "query": keyword,
            "search_type": 0,
            "num_per_page": 1,
            "page_num": 1,
            "highlight": 0,
            "nqc_flag": 0,
            "page_id": 1,
            "grp": 1,
        })
        if result:
            songs = result.get("body", {}).get("item_song", [])
            if songs:
                s = songs[0]
                song_id = s["id"]
                song_name = s.get("title", track)
                singer_name = "/".join(x.get("name", "") for x in s.get("singer", [])) or artist
                album_name = s.get("album", {}).get("name", "")
                lyric_data = _qq_api("GetPlayLyricInfo", "music.musichallSong.PlayLyricInfo", {
                    "albumName": b64.b64encode(album_name.encode()).decode(),
                    "crypt": 1, "ct": 19, "cv": 2111,
                    "interval": s.get("interval", 0),
                    "lrc_t": 0, "qrc": 1, "qrc_t": 0, "roma": 1, "roma_t": 0,
                    "singerName": b64.b64encode(singer_name.encode()).decode(),
                    "songID": song_id,
                    "songName": b64.b64encode(song_name.encode()).decode(),
                    "trans": 1, "trans_t": 0, "type": 0,
                })
                if lyric_data:
                    qrc_raw = lyric_data.get("lyric", "")
                    if qrc_raw and isinstance(qrc_raw, str) and len(qrc_raw) > 10:
                        qrc_text = _decrypt_qrc(qrc_raw)
                        if qrc_text:
                            qrc_lines = parse_yrc(qrc_text)
                            if qrc_lines:
                                return {"format": "word", "source": "qq-qrc", "lines": qrc_lines}
    except Exception:
        pass

    # === 回退: LRC ===
    if lrc_lines:
        has_word = any(len(l["words"]) > 1 for l in lrc_lines)
        return {"format": "word" if has_word else "line", "source": "qq-lrc", "lines": lrc_lines}

    return None
    ne_headers = HEADERS.copy()
    ne_headers["Referer"] = "http://music.163.com/"

    post_data = urllib.parse.urlencode(
        {"s": f"{track} {artist}", "type": 1, "offset": 0, "total": "true", "limit": 1}
    ).encode("utf-8")

    try:
        # 搜索歌曲
        search_url = "http://music.163.com/api/search/get/"
        res = request_url(search_url, data=post_data, headers=ne_headers)
        if not (
            res
            and "result" in res
            and "songs" in res["result"]
            and res["result"]["songs"]
        ):
            return None

        song_id = res["result"]["songs"][0]["id"]

        # 尝试 YRC 端点 (yv=-1 返回逐字歌词)
        yrc_url = (
            f"http://music.163.com/api/song/lyric"
            f"?id={song_id}&lv=-1&tv=-1&yv=-1"
        )
        yrc_data = request_url(yrc_url, headers=ne_headers)

        if yrc_data and "yrc" in yrc_data and yrc_data["yrc"].get("lyric"):
            yrc_raw = yrc_data["yrc"]["lyric"]
            yrc_lines = parse_yrc(yrc_raw)
            if yrc_lines:
                return {
                    "format": "word",
                    "source": "netease-yrc",
                    "lines": yrc_lines,
                }

        # 回退到标准 LRC (os=pc 端点, 更稳定)
        lrc_url = (
            f"http://music.163.com/api/song/lyric"
            f"?os=pc&id={song_id}&lv=-1&kv=-1&tv=-1"
        )
        lrc_data = request_url(lrc_url, headers=ne_headers)

        if lrc_data and "lrc" in lrc_data and lrc_data["lrc"].get("lyric"):
            lrc_raw = lrc_data["lrc"]["lyric"]
            lines = parse_lrc(lrc_raw)
            if lines:
                has_word = any(len(l["words"]) > 1 for l in lines)
                return {
                    "format": "word" if has_word else "line",
                    "source": "netease-lrc",
                    "lines": lines,
                }

        # 如果 YRC 端点也返回了 LRC (作为最后的回退)
        if yrc_data and "lrc" in yrc_data and yrc_data["lrc"].get("lyric"):
            lrc_raw = yrc_data["lrc"]["lyric"]
            lines = parse_lrc(lrc_raw)
            if lines:
                return {
                    "format": "line",
                    "source": "netease-lrc",
                    "lines": lines,
                }

    except Exception:
        pass
    return None


# ============================================================
# 网易云搜索辅助 (只拿 song_id, 不取歌词)
# ============================================================

def _fetch_netease_search(track, artist):
    """搜索 NetEase 歌曲, 返回 song_id (用于 TTML 获取), 失败返回 None。"""
    ne_headers = HEADERS.copy()
    ne_headers["Referer"] = "http://music.163.com/"
    post_data = urllib.parse.urlencode(
        {"s": f"{track} {artist}", "type": 1, "offset": 0, "total": "true", "limit": 1}
    ).encode("utf-8")
    try:
        res = request_url("http://music.163.com/api/search/get/", data=post_data, headers=ne_headers)
        if res and "result" in res and "songs" in res["result"] and res["result"]["songs"]:
            return res["result"]["songs"][0]["id"]
    except Exception:
        pass
    return None


# ============================================================
# 网易云获取 (YRC 优先，LRC 回退)
# ============================================================

def fetch_netease(track, artist):
    """获取网易云歌词，优先 YRC (逐字)，回退 LRC。"""
    ne_headers = HEADERS.copy()
    ne_headers["Referer"] = "http://music.163.com/"

    post_data = urllib.parse.urlencode(
        {"s": f"{track} {artist}", "type": 1, "offset": 0, "total": "true", "limit": 1}
    ).encode("utf-8")

    try:
        search_url = "http://music.163.com/api/search/get/"
        res = request_url(search_url, data=post_data, headers=ne_headers)
        if not (
            res
            and "result" in res
            and "songs" in res["result"]
            and res["result"]["songs"]
        ):
            return None

        song_id = res["result"]["songs"][0]["id"]

        # YRC 端点 (yv=-1)
        yrc_url = f"http://music.163.com/api/song/lyric?id={song_id}&lv=-1&tv=-1&yv=-1"
        yrc_data = request_url(yrc_url, headers=ne_headers)

        if yrc_data and "yrc" in yrc_data and yrc_data["yrc"].get("lyric"):
            yrc_lines = parse_yrc(yrc_data["yrc"]["lyric"])
            if yrc_lines:
                return {"format": "word", "source": "netease-yrc", "lines": yrc_lines}

        # LRC 回退 (os=pc)
        lrc_url = f"http://music.163.com/api/song/lyric?os=pc&id={song_id}&lv=-1&kv=-1&tv=-1"
        lrc_data = request_url(lrc_url, headers=ne_headers)

        if lrc_data and "lrc" in lrc_data and lrc_data["lrc"].get("lyric"):
            lines = parse_lrc(lrc_data["lrc"]["lyric"])
            if lines:
                has_word = any(len(l["words"]) > 1 for l in lines)
                return {"format": "word" if has_word else "line", "source": "netease-lrc", "lines": lines}

        # YRC 端点的 LRC 回退
        if yrc_data and "lrc" in yrc_data and yrc_data["lrc"].get("lyric"):
            lines = parse_lrc(yrc_data["lrc"]["lyric"])
            if lines:
                return {"format": "line", "source": "netease-lrc", "lines": lines}

    except Exception:
        pass
    return None


# ============================================================
# 统一输出构建
# ============================================================

def build_output(result):
    """将解析结果构建为统一输出格式 (含 _legacy 向后兼容)。"""
    if not result or not result.get("lines"):
        return [{"time": 0, "text": "暂无歌词"}]

    lines = result["lines"]
    fmt = result.get("format", "line")
    source = result.get("source", "unknown")

    # 构建 _legacy flat array
    legacy = []
    for line in lines:
        legacy.append({"time": line["time"], "text": line["text"]})

    output = {
        "format": fmt,
        "source": source,
        "lines": lines,
        "_legacy": legacy,
    }

    return output


# ============================================================
# 入口
# ============================================================

# ============================================================
# 核心获取逻辑 (CLI 和 daemon 共用)
# ============================================================

def fetch_lyrics(title, artist):
    """获取歌词，返回统一格式 dict。"""
    cache_file = get_cache_path(title, artist)
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                cached_data = json.load(f)
                if cached_data and isinstance(cached_data, dict) and "_legacy" in cached_data:
                    return cached_data
        except Exception:
            pass

    result = None
    source_name = ""
    qq_cached = None
    ne_cached = None

    # Step 0: TTML
    if not result:
        ne_search = _fetch_netease_search(title, artist)
        if ne_search:
            ttml_result = fetch_ttml(ne_search)
            if ttml_result:
                result = ttml_result
                source_name = result["source"]

    # Step 1: QQ QRC
    if not result:
        qq_cached = fetch_qq(title, artist)
        if qq_cached and qq_cached.get("format") == "word":
            result = qq_cached
            source_name = result["source"]

    # Step 2: NetEase YRC
    if not result:
        ne_cached = fetch_netease(title, artist)
        if ne_cached and ne_cached.get("format") == "word":
            result = ne_cached
            source_name = result["source"]

    # Step 3: QQ LRC
    if not result and qq_cached:
        result = qq_cached
        source_name = result["source"]

    # Step 4: NetEase LRC
    if not result and ne_cached:
        result = ne_cached
        source_name = result["source"]

    if not result:
        output = {"format": "line", "source": "none", "lines": [{"time": 0, "text": "未找到歌词", "words": [{"word": "未找到歌词", "startTime": 0, "endTime": 5.0}]}], "_legacy": [{"time": 0, "text": "未找到歌词"}]}
    else:
        output = build_output(result)
        output["_legacy"].insert(0, {"time": 0, "text": f"[来源: {source_name}]"})
        output["lines"].insert(0, {"time": 0, "text": f"[来源: {source_name}]", "words": [{"word": f"[来源: {source_name}]", "startTime": 0, "endTime": 1.0}]})
        try:
            with open(cache_file, "w") as f:
                json.dump(output, f, ensure_ascii=False)
        except Exception:
            pass
    return output


if __name__ == "__main__":
    # --daemon: stdin JSON 行 → stdout JSON 行
    if len(sys.argv) >= 2 and sys.argv[1] == "--daemon":
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                req = json.loads(line)
                t, a = req.get("title", ""), req.get("artist", "")
                if t:
                    out = fetch_lyrics(t, a)
                    sys.stdout.write(json.dumps(out, ensure_ascii=False) + "\n")
                    sys.stdout.flush()
            except Exception:
                pass
        sys.exit(0)

    # ---- CLI 模式 (兼容旧版) ----
    if len(sys.argv) < 2:
        print(json.dumps([{"time": 0, "text": "等待播放..."}]))
        sys.exit(0)
    title = sys.argv[1]
    artist = sys.argv[2] if len(sys.argv) > 2 else ""
    out = fetch_lyrics(title, artist)
    print(json.dumps(out))
