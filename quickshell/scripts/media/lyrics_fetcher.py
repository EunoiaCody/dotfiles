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
            if text and not text.lower().startswith(
                ("offset:", "by:", "al:", "ti:", "ar:")
            ):
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
            # 无字内容(如空行或纯标点) — 跳过
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
# QQ音乐获取
# ============================================================

def fetch_qq(track, artist):
    """获取 QQ 音乐歌词。

    返回统一格式 dict 或 None。
    QQ 音乐目前仅支持 LRC (QRC 端点暂时不可用)。
    """
    qq_headers = {
        "User-Agent": HEADERS["User-Agent"],
        "Referer": "https://y.qq.com/",
    }
    try:
        keyword = f"{track} {artist}"
        search_url = (
            "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
            f"?w={urllib.parse.quote(keyword)}&format=json"
        )
        search_data = request_url(search_url, headers=qq_headers)

        songmid = ""
        if (
            search_data
            and "data" in search_data
            and "song" in search_data["data"]
            and "list" in search_data["data"]["song"]
        ):
            song_list = search_data["data"]["song"]["list"]
            if song_list:
                songmid = song_list[0]["songmid"]

        if not songmid:
            return None

        # 获取歌词（LRC）
        lyric_url = (
            "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg"
            f"?songmid={songmid}&format=json&nobase64=1"
        )
        lyric_data = request_url(lyric_url, headers=qq_headers)

        if not lyric_data:
            return None

        # 尝试 QRC (逐字)
        if "qrc" in lyric_data and lyric_data["qrc"]:
            qrc_raw = lyric_data["qrc"]
            try:
                qrc_decoded = base64.b64decode(qrc_raw).decode("utf-8")
            except Exception:
                qrc_decoded = qrc_raw
            qrc_lines = _parse_qrc(qrc_decoded)
            if qrc_lines:
                return {
                    "format": "word",
                    "source": "qq-qrc",
                    "lines": qrc_lines,
                }

        # 回退到 LRC
        if "lyric" in lyric_data and lyric_data["lyric"]:
            raw_lrc = lyric_data["lyric"]
            try:
                decoded_lrc = base64.b64decode(raw_lrc).decode("utf-8")
            except Exception:
                decoded_lrc = raw_lrc
            lines = parse_lrc(decoded_lrc)
            if lines:
                has_word = any(len(l["words"]) > 1 for l in lines)
                return {
                    "format": "word" if has_word else "line",
                    "source": "qq-lrc",
                    "lines": lines,
                }

    except Exception:
        pass
    return None


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
# 网易云获取
# ============================================================

def fetch_netease(track, artist):
    """获取网易云歌词，优先 YRC (逐字)，回退 LRC。"""
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

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps([{"time": 0, "text": "等待播放..."}]))
        sys.exit(0)

    title = sys.argv[1]
    artist = sys.argv[2] if len(sys.argv) > 2 else ""

    cache_file = get_cache_path(title, artist)

    # 读取 v2 缓存
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                cached_data = json.load(f)
                if cached_data and isinstance(cached_data, dict) and "_legacy" in cached_data:
                    print(json.dumps(cached_data))
                    sys.exit(0)
        except Exception:
            pass

    result = None
    source_name = ""

    # 优先级: 网易云 YRC > QQ音乐 LRC > 网易云 LRC
    if not result:
        result = fetch_netease(title, artist)
        if result:
            source_name = result["source"]

    if not result:
        result = fetch_qq(title, artist)
        if result:
            source_name = result["source"]

    # 构建输出
    if not result:
        output = {"format": "line", "source": "none", "lines": [{"time": 0, "text": "未找到歌词", "words": [{"word": "未找到歌词", "startTime": 0, "endTime": 5.0}]}], "_legacy": [{"time": 0, "text": "未找到歌词"}]}
    else:
        output = build_output(result)
        # 添加来源提示到第一行
        output["_legacy"].insert(0, {"time": 0, "text": f"[来源: {source_name}]"})
        output["lines"].insert(0, {"time": 0, "text": f"[来源: {source_name}]", "words": [{"word": f"[来源: {source_name}]", "startTime": 0, "endTime": 1.0}]})

        # 写入缓存
        try:
            with open(cache_file, "w") as f:
                json.dump(output, f, ensure_ascii=False)
        except Exception:
            pass

    print(json.dumps(output))
