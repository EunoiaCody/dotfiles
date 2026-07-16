#!/usr/bin/env python3
"""标题解析器 — 从 Bilibili/YouTube 混杂标题中提取歌曲元信息

借鉴 get-artist-title (npm) 和 youtube_title_parse (PyPI) 的流水线架构，
扩展了 Bilibili 全角括号模式的支持。

流水线:
  Text → [before: 去文件扩展名 → 去B站噪声 → 去YouTube噪声]
       → [split: B站【】→ by ARTIST → 《》→ YouTube分隔符 → 引号]
       → [after: 清理artist → 清理title → 清理通用fluff]
       → (artist, title)

用法:
  python3 scripts/media/title_parser.py "【初音未来】神曲【R Sound Design】"
  # → {"artist": "R Sound Design", "title": "神曲"}
"""

import sys
import json
import re
import os
from functools import reduce as _reduce

# ============================================================
# 流水线引擎 (移植自 youtube_title_parse/core.py)
# ============================================================

def _flow(functions):
    """左到右函数组合: flow([f,g])(x) = g(f(x))"""
    if not functions:
        return lambda arg: arg
    def composed(arg):
        result = arg
        for fn in functions:
            result = fn(result)
        return result
    return composed


def _combine_splitters(splitters):
    """依次尝试每个分割器, 优先返回同时有 artist+title 的结果。

    如果没有同时有两者的结果, 返回第一个至少含 title 的结果。
    这让 Bilibili 策略在无法识别 artist 时能 fallthrough 到后续策略。
    """
    def combined(text):
        best = None  # 最佳结果 (有 artist+title)
        fallback = None  # 次选 (只有 title, 最后出现的优先)
        for splitter in splitters:
            result = splitter(text)
            if not result:
                continue
            artist, song_title = result[0], result[1]
            if artist and song_title:
                return result  # 完美: 立刻返回
            if song_title:
                fallback = result  # 持续更新, 最后的有 title 结果胜出
        return fallback  # 无完美结果时返回最后的次选
    return combined


def _reduce_plugins(plugins):
    return [
        _flow(plugins["before"]),
        _combine_splitters(plugins["split"]),
        _flow(plugins["after"]),
    ]


def _map_artist(fn):
    def wrapper(parts):
        return [fn(parts[0]), parts[1]]
    return wrapper


def _map_title(fn):
    def wrapper(parts):
        return [parts[0], fn(parts[1])]
    return wrapper


def _map_artist_title(map_a, map_t):
    def wrapper(parts):
        return [map_a(parts[0]), map_t(parts[1])]
    return wrapper


def _get_song_artist_title(text, plugins):
    plugin = _reduce_plugins(plugins)
    split = plugin[1](plugin[0](text))
    if not split:
        return None
    return plugin[2](split)


# ============================================================
# 辅助函数
# ============================================================

def _has_fullwidth_brackets(text):
    """检测是否含全角括号 — Bilibili/中文平台的强信号。"""
    return bool(re.search(r'[【】《》「」]', text))


# ============================================================
# is_likely_music() — 借鉴 get-artist-title fluff 模式, 反向判定
# ============================================================

# 音乐信号词: 含任一 → 可能是音乐
_MUSIC_SIGNALS = [
    # YouTube 系 (移植自 base.js cleanMVPV + cleanFluff)
    r'\bMV\b', r'\bPV\b', r'M/V', r'M\/V',
    r'Official\s*(Music|Video|Audio)',
    r'\bLyrics?\b', r'歌词',
    r'\bMusic\b', r'\bAudio\b',
    # 中文系
    r'歌', r'曲', r'唱', r'演唱', r'听',
    r'主题曲', r'片头曲', r'片尾曲', r'插入曲', r'剧中曲', r'主題歌', r'劇中歌',
    r'\bOP\b', r'\bED\b', r'\bOST\b', r'\bBGM\b',
    # 二次元/翻唱系
    r'\bCover\b', r'翻唱', r'歌ってみた', r'踊ってみた',
    r'\bfeat\.?\b', r'\bft\.?\b', r'合唱',
    r'\bVocal\b', r'ボーカル',
    r'Original\s*Song', r'原创曲',
    # 二次元声库名
    r'ボカロ', r'VOCALOID', r'UTAU', r'CeVIO',
    r'(?:初音|鏡音|巡音|Megpoid|GUMI|IA|結月|紲星|flower|可不|星界|裏命|狐子|羽累)',
    # 专辑/音轨
    r'\bTrack\b', r'\bAlbum\b', r'Soundtrack', r'サントラ',
    r'\bSingle\b', r'\bEP\b',
]

# 非音乐信号词: 含任一且无音乐信号 → 不是音乐
_NON_MUSIC_SIGNALS = [
    # 游戏/实况
    r'実況', r'实况', r'直播', r'生放送',
    r'攻略', r'通关', r'解说', r'実況プレイ',
    r'ゲーム', r'\bGame\b', r'\bGaming\b', r'游戏', r'試玩', r'试玩',
    r'マイクラ', r'マインクラフト', r'Minecraft',
    # Vlog/日常
    r'\bVlog\b', r'日常', r'ルーティン', r'メイク',
    # 评测/教程
    r'评测', r'レビュー', r'开箱',
    r'\bTutorial\b', r'教程', r'教学',
    # 播客/新闻
    r'\bPodcast\b', r'播客', r'ラジオ',
    r'\bNews\b', r'新闻', r'ニュース',
    # 影视
    r'电影完整版', r'电视剧', r'综艺', r'纪录片', r'映画',
    # 生活
    r'料理', r'クッキング', r'做饭',
    r'ASMR', r'作業用',
]

_MUSIC_RE = re.compile('|'.join(_MUSIC_SIGNALS), re.IGNORECASE)
_NON_MUSIC_RE = re.compile('|'.join(_NON_MUSIC_SIGNALS), re.IGNORECASE)


def is_likely_music(title):
    """判定视频标题是否像是音乐内容。

    借鉴 get-artist-title 的 fluff 检测思路:
      含音乐信号词 → True
      不含音乐信号词 → False (严格: 不猜测)
    """
    if not title or not title.strip():
        return False
    # 必须至少命中一个音乐信号词
    return bool(_MUSIC_RE.search(title))


# ============================================================
# 预处理阶段 (before) — 移植 + 扩展
# ============================================================

# --- 文件扩展名去除 (移植自 remove_file_extensions.py) ---

_VIDEO_EXT = [
    "3g2","3gp","aaf","asf","avchd","avi","drc","flv","m2v","m4p","m4v",
    "mkv","mng","mov","mp2","mp4","mpe","mpeg","mpg","mpv","mxf","nsv",
    "ogg","ogv","qt","rm","rmvb","roq","svi","vob","webm","wmv","yuv",
]
_AUDIO_EXT = [
    "wav","bwf","raw","aiff","flac","m4a","pac","tta","wv","ast","aac",
    "mp2","mp3","mp4","amr","s3m","3gp","act","au","dct","dss","gsm",
    "m4p","mmf","mpc","ogg","oga","opus","ra","sln","vox",
]
_FILE_EXT_RX = re.compile(
    r'\.(' + '|'.join(_VIDEO_EXT + _AUDIO_EXT) + ')$', re.IGNORECASE
)


def _remove_file_extensions(text):
    return _FILE_EXT_RX.sub('', text)


# --- Bilibili 噪声去除 (新增) ---
# 不在 before 阶段去除【】括号 — 留给 split 阶段做结构分析。
# before 只去掉明显非括号噪声。

_BILIBILI_FLUFF = [
    # 分辨率后缀 (非括号)
    (r'[\s\-–_]+(?:HD|HQ|\d{3,4}p|4K)\s*$', ''),
]

_BILIBILI_FLUFF_RX = [(re.compile(p, re.IGNORECASE), r) for p, r in _BILIBILI_FLUFF]


def _clean_bilibili_fluff(text):
    """去除 Bilibili 非括号噪声 (结构分析前轻量清理)。"""
    for rx, replacement in _BILIBILI_FLUFF_RX:
        text = rx.sub(replacement, text)
    return text.strip()


# --- YouTube 噪声去除 (移植自 base.py clean_fluff) ---

def _clean_mvpv(text):
    """去除 MV/PV 标记 (移植自 base.js cleanMVPV)。"""
    text = re.sub(r'\s*\[\s*(?:off?icial\s+)?([PM]/V)\s*]', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\(\s*(?:off?icial\s+)?([PM]/V)\s*\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*【\s*(?:off?icial\s+)?([PM]/V)\s*】', '', text, flags=re.IGNORECASE)
    text = re.sub(r'[\s\-–_]+(?:off?icial\s+)?([PM]/V)\s*', '', text, flags=re.IGNORECASE)
    text = re.sub(r'(?:off?icial\s+)?([PM]/V)[\s\-–_]+', '', text)
    return text


def _clean_youtube_fluff(text):
    """去除 YouTube 常见噪声 (移植自 base.py cleanFluff)。"""
    text = _clean_mvpv(text)
    text = re.sub(r'\s*\[[^\]]+]$', '', text)               # [whatever] at end
    text = re.sub(r'^\s*\[[^\]]+]\s*', '', text)            # [whatever] at start
    text = re.sub(r'\s*\([^)]*\bver(\.|sion)?\s*\)$', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*[a-z]*\s*\bver(\.|sion)?$', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*(of+icial\s*)?(music\s*)?video', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*(full\s*)?album', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*(ALBUM TRACK\s*)?(album track\s*)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\(\s*of+icial\s*\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\(\s*lyric(s)?\s*\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\(\s*(of+icial)?\s*lyric(s)?\s*\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*\(\s*[0-9]{4}\s*\)', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s+\(\s*(HD|HQ|[0-9]{3,4}p|4K)\s*\)$', '', text)
    text = re.sub(r'[\s\-–_]+(HD|HQ|[0-9]{3,4}p|4K)\s*$', '', text)
    return text


# ============================================================
# 分割阶段 (split) — 多策略, 优先级递减
# ============================================================

# --- 辅助: 引号内判定 (移植自 base.py in_quotes) ---

def _in_quotes(text, idx):
    """判定 idx 位置是否在括号/引号对内 (含全角括号【】《》「」)。"""
    open_chars = '([{«【《「'
    close_chars = ')]}»】》」'
    toggle_chars = '"\''
    open_pars = {
        ')': 0, ']': 0, '}': 0, '»': 0,
        '"': 0, "'": 0,
        '】': 0, '》': 0, '」': 0,
    }
    for i in range(min(idx, len(text))):
        ch = text[i]
        oix = open_chars.find(ch)
        if oix != -1:
            open_pars[close_chars[oix]] += 1
        elif ch in close_chars and open_pars[ch] > 0:
            open_pars[ch] -= 1
        if ch in toggle_chars:
            open_pars[ch] = 1 - open_pars[ch]
    return _reduce(lambda acc, v: acc + v, open_pars.values(), 0) > 0


# --- 噪声关键词 (用于区分 artist【】与 fluff【】) ---

_FLUFF_KEYWORDS = [
    '试听', '无损', '画质', 'Hi-Res', 'HQ', 'CD音质',
    'MV', 'PV', 'M/V', 'Official', 'Music Video',
    '完整版', '动画', '主題歌', '主题曲', 'OP', 'ED',
    'OST', 'BGM', '插入曲', '剧中曲',
    '4K', '1080P', '720P', '高画质', '高清',
    '录音棚', '耳机试听', '耳机黨', '耳机党',
    '百万级', '翻唱', 'Cover',
    '投稿', '自制', '转载',
    '字幕', '翻译', '中字',
    # NicoNico/Bilibili 版本标签
    '本家', '原作', '原曲', '本家様', 'オリジナル',
    '歌ってみた', '踊ってみた', '演奏してみた',
    'MMD', 'モーション',
    # featuring 标注 (【feat. X】是元数据, 不是艺术家)
    'feat.', 'ft.', 'feat', 'ft',
    'Feat.', 'Ft.', 'featuring',
]

_FLUFF_KW_RE = re.compile('|'.join(re.escape(kw) for kw in _FLUFF_KEYWORDS), re.IGNORECASE)

# 艺术家人名特征: 含片假名、平假名、拉丁字母、或汉字人名常见后缀
_ARTIST_FEATURES_RE = re.compile(
    r'[ァ-ヴー]'          # 片假名
    r'|[ぁ-ん]'           # 平假名
    r'|[a-zA-Z]{2,}'      # 拉丁字母连续
    r'|[·•]'              # 日本人名分隔符 (例: R Sound Design)
    r'|Official'          # 官方频道标记
    r'|[Oo]fficial\s*[Cc]hannel'
    r'|[\u4e00-\u9fff]{2,4}(?:P|ちゃん|さん|君|氏)'  # 汉字名 + 后缀
)


def _is_artist_bracket(content):
    """判定【...】内容是否像是艺术家名而非 fluff 标签。"""
    content = content.strip()
    if not content or len(content) > 30:
        return False
    # 含 fluff 关键词 → 不是艺术家
    if _FLUFF_KW_RE.search(content):
        return False
    # 含艺术家人名特征 → 可能是艺术家
    if _ARTIST_FEATURES_RE.search(content):
        return True
    # 简短且不含噪声 → 默认认为是艺术家
    if len(content) <= 12:
        return True
    return False


def _extract_artist_from_bracket(content):
    """从【】括号内容中提取最终艺术家名。

    处理「歌名｜艺术家」格式: 取 ｜ 右侧部分作为艺术家。
    处理「艺术家A / 艺术家B」: 保留全部作为联合艺术家。
    """
    content = content.strip()
    # 如果含 ｜ (全角竖线), 取右侧作为艺术家
    if '｜' in content:
        parts = content.split('｜')
        # 取最后一个不含 fluff 词的部分
        for part in reversed(parts):
            part = part.strip()
            if part and not _FLUFF_KW_RE.search(part):
                return part
        return parts[-1].strip()
    return content


# --- 策略 1: Bilibili 【】括号识别 ---

def _split_bilibili_brackets(text):
    """从 Bilibili 风格标题提取 (artist, title)。

    扫描所有【...】块，区分「艺术家」和「标签/fluff」。
    提取出 artist 后，从剩余文本取歌名（优先「」 > 《》 > 《》 > 自由文本）。

    若 artist 为空，返回 None 让后续策略继续尝试。
    """
    # 提取所有【...】块
    bracket_pattern = re.compile(r'【([^】]*)】')
    brackets = bracket_pattern.findall(text)

    if not brackets:
        return None

    # 分类: artist_candidates vs fluff
    artist_parts = []
    title_from_bracket = None  # 从 ｜ 括号左侧提取的歌名

    for content in brackets:
        if _is_artist_bracket(content):
            artist_parts.append(_extract_artist_from_bracket(content))
            # 如果括号含 ｜, 左侧可能是歌名
            if '｜' in content:
                left = content.split('｜')[0].strip()
                if left and not _FLUFF_KW_RE.search(left) and len(left) >= 2:
                    title_from_bracket = left

    # 去掉【...】后剩下的文本
    remaining = bracket_pattern.sub(' ', text)

    # 提取歌名 — 优先级: 「」 > 《》 > bracket左侧 > 自由文本
    title = _extract_song_title(remaining)
    
    # 如果 remaining 提取的 title 很短、像 fluff、或含噪声, 优先用 bracket 左侧
    if title and title_from_bracket and (
        len(title) <= 4
        or _FLUFF_KW_RE.search(title)
        or title.strip().isupper()  # 全大写 → 很可能是标签
    ):
        title = title_from_bracket
    if not title:
        title = title_from_bracket

    if not title:
        return None

    artist = ' / '.join(artist_parts) if artist_parts else None

    # 如果只有 title 没有 artist, 也从括号中提取首个短括号作为备选
    if not artist:
        for content in brackets:
            stripped = content.strip()
            if stripped and len(stripped) <= 15 and not _FLUFF_KW_RE.search(stripped):
                artist = stripped
                break

    # 即使 artist 为空也返回 (新 combine 逻辑会优先选择有 artist 的结果)
    return [artist if artist else '', title]


def _extract_song_title(text):
    """从去括号后的文本中提取歌名。"""
    # 优先级 1: 「...」
    corner = re.search(r'「([^」]*)」', text)
    if corner:
        return corner.group(1).strip()

    # 优先级 2: 《...》
    guil = re.search(r'《([^》]*)》', text)
    if guil:
        return guil.group(1).strip()

    # 优先级 3: 清理后自由文本
    cleaned = text.strip()
    # 去除常见前缀
    cleaned = re.sub(r'^(?:主题曲|OP|ED|插入曲|剧中曲|OST|BGM)\s*[：:]*\s*', '', cleaned)
    # 去除常见后缀
    cleaned = re.sub(r'\s*(?:动画MV|官方MV|完整版|MV版)\s*$', '', cleaned)
    # 去除 by XXX
    cleaned = re.sub(r'\s*\bby\s+.+$', '', cleaned, flags=re.IGNORECASE)
    # 去除残留括号标记
    cleaned = re.sub(r'\s*[\[【][^\]】]*[\]】]', '', cleaned)
    # 去除 Vocaloid / 歌手后缀: "歌名 - 初音ミク" → "歌名"
    cleaned = re.sub(
        r'\s*[-–—]\s*(?:初音ミク|鏡音[レリ]ン|巡音[ルル]カ|KAITO|MEIKO|GUMI|IA|結月ゆかり|紲星あかり|flower|可不|星界|裏命|狐子|羽累|VOCALOID|UTAU|CeVIO|SynthV)\s*$',
        '', cleaned
    )

    cleaned = cleaned.strip(' 　-–—~_/|,，。、')
    if len(cleaned) >= 2:
        return cleaned
    return None


# --- 策略 2: by ARTIST 模式 ---

def _split_bilibili_by(text):
    """识别「歌名」by 艺术家 模式。"""
    # 「歌名」by Artist
    by_pattern = re.compile(r'[「「]([^」」]*)[」」]\s*by\s+(.+?)(?:\s*[\[【]|$)', re.IGNORECASE)
    m = by_pattern.search(text)
    if m:
        title = m.group(1).strip()
        artist = m.group(2).strip()
        # 清理 artist 后缀
        artist = re.sub(r'\s*(?:动画MV|官方MV|完整版)\s*$', '', artist, flags=re.IGNORECASE)
        if title and artist:
            return [artist.strip(), title.strip()]

    # "歌名" by Artist (文本中无「」的情况)
    plain_by = re.compile(
        r'(.+?)\s*\bby\s+(.+?)(?:\s*[\[【(]|$)',
        re.IGNORECASE
    )
    m2 = plain_by.search(text)
    if m2:
        title = m2.group(1).strip()
        artist = m2.group(2).strip()
        # 过滤明显不是歌名的内容
        if not _FLUFF_KW_RE.search(title) and len(title) >= 2 and len(artist) >= 2:
            return [artist, title]

    return None


# --- 策略 3: 《》歌名模式 ---

def _split_bilibili_guillemets(text):
    """《作品名》歌名 → 提取歌名, 尝试从【】取艺术家。"""
    guil_match = re.findall(r'《([^》]*)》', text)
    if not guil_match:
        return None

    # 最后一个《》通常是作品来源, 后面的文本是歌名
    # 或者前面的文本含【】→ artist
    last_guil = guil_match[-1]
    after_guil = text.split(f'《{last_guil}》')[-1] if f'《{last_guil}》' in text else ''

    # 提取 after_guil 中可能的歌名
    title = _extract_song_title(after_guil)
    if not title:
        # 有可能歌名就是《》本身
        title = last_guil.strip()

    # 从【】提取 artist
    brackets = re.findall(r'【([^】]*)】', text)
    artist = None
    for content in brackets:
        if _is_artist_bracket(content):
            artist = _extract_artist_from_bracket(content)
            break

    return [artist if artist else '', title]


# --- 策略 4: YouTube 标准分隔符切分 (移植自 base.py) ---

_SEPARATORS = [
    ' -- ', '--', ' - ', ' – ', ' — ', ' _ ',
    '-', '–', '—', ':', '|', '///', ' / ', '_', '/',
]


def _split_artist_title(text):
    """按分隔符切分 (移植自 base.js splitArtistTitle)。"""
    for sep in _SEPARATORS:
        try:
            idx = text.index(sep)
        except ValueError:
            continue
        if idx > 0 and idx < len(text) - len(sep) and not _in_quotes(text, idx):
            artist = text[:idx]
            title = text[idx + len(sep):]
            # 基本合理性检查: 两边都非空
            if artist.strip() and title.strip():
                return [artist.strip(), title.strip()]
    return None


# --- 策略 5: 引号模式 (移植自 quoted_title.py) ---

_QUOTES = ['""', '""', "''", '\x9c\xe2\x80\x9d']


def _split_text(text):
    """识别 Artist "Title" 格式 (移植自 quoted_title.js)。"""
    # 处理左右引号对
    for open_q, close_q in [('"', '"'), ('"', '"'), ("'", "'"), ('\x9c', '\xe2\x80\x9d')]:
        # 查找 "..." 对
        loose = re.compile(re.escape(open_q) + r'(.*?)' + re.escape(close_q))
        m = loose.search(text)
        if m:
            split_pos = m.start()
            artist = text[:split_pos].strip()
            title_inner = m.group(1).strip()
            # 去掉 artist 部分的尾部分隔符
            artist = re.sub(r'[\s\-–_/|]+$', '', artist)
            if artist and title_inner:
                return [artist, title_inner]

    return None


# ============================================================
# 清理阶段 (after) — 移植自 base.py + 扩展
# ============================================================

def _clean_artist(artist):
    """清理艺术家名 (移植自 base.py cleanArtist)。"""
    artist = artist.strip()
    # 去日期 YYMMDD
    artist = re.sub(r'\s*[0-1][0-9][0-1][0-9][0-3][0-9]\s*', '', artist)
    # 去残留括号
    artist = re.sub(r'[\[【][^\]】]*[\]】]', '', artist)
    # trim 符号
    artist = re.sub(r'^[/\s,:;~\-–_"\']+', '', artist)
    artist = re.sub(r'[/\s,:;~\-–_"\']+$', '', artist)
    return artist.strip()


def _clean_title(title):
    """清理歌名 (移植自 base.py cleanTitle + Bilibili 扩展)。"""
    title = title.strip()
    # YouTube 系
    title = re.sub(r'\s*\*+\s?\S+\s?\*+$', '', title)         # **NEW**
    title = re.sub(r'\s*video\s*clip', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s+\(?live\)?$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\(\s*\)', '', title)
    title = re.sub(r'\[\s*]', '', title)
    title = re.sub(r'【\s*】', '', title)
    title = re.sub(r'^(|.*\s)"(.*)"(\s.*|)$', r'\2', title)
    title = re.sub(r"^(|.*\s)'(.*)'(\s.*|)$", r'\2', title)
    # Bilibili 扩展
    title = re.sub(r'\s*(?:OP|ED|主题曲|插入曲|剧中曲|OST|BGM)\s*$', '', title)
    title = re.sub(r'\s*feat\.?\s*.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*【[^】]*】', '', title)                # 残留括号
    title = re.sub(r'\s*《[^》]*》', '', title)                # 残留书名号
    title = re.sub(r'\s*\bcover\s*(?:by|ver\.?)?.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*翻唱.*$', '', title)
    # trim 符号
    title = re.sub(r'^[/\s,:;~\-–_"\']+', '', title)
    title = re.sub(r'[/\s,:;~\-–_"\']+$', '', title)
    return title.strip()


def _clean_common_fluff(title):
    """清理通用 fluff (移植自 common.py cleanCommonFluff)。"""
    title = re.sub(r'\(not the( video)?\)\s*$', '', title)
    title = re.sub(r'(\s*[-~_/]\s*)?\b(with\s+)?lyrics\s*', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\(\s*(with\s+)?lyrics\s*\)\s*', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*\(\s*\)', '', title)
    return title.strip()


# ============================================================
# 主入口
# ============================================================

def parse(title, options=None):
    """解析视频标题, 返回 (artist, title) 元组。

    仅在标题含全角括号时启用 Bilibili 策略。
    借鉴 youtube_title_parse 的三阶段流水线架构,
    扩展了 Bilibili 【】/《》/「」 模式支持。

    返回:
        (artist, title) — 成功
        (None, None) — 无法解析或不含全角括号
    """
    if not title or not title.strip():
        return None, None

    # 门控: 仅全角括号标题启用解析
    if not _has_fullwidth_brackets(title):
        return None, None

    plugins = {
        "before": [_remove_file_extensions, _clean_bilibili_fluff, _clean_youtube_fluff],
        "split": [
            _split_bilibili_brackets,
            _split_bilibili_by,
            _split_bilibili_guillemets,
            _split_artist_title,
            _split_text,
        ],
        "after": [
            _map_artist_title(_clean_artist, _clean_title),
            _map_artist_title(lambda x: x, lambda x: x),  # identity pass
            _map_title(_clean_common_fluff),
        ],
    }

    result = _get_song_artist_title(title, plugins)
    if result and result[1]:
        artist = result[0].strip() if result[0] else None
        song_title = result[1].strip()
        return (artist, song_title)
    return None, None


# ============================================================
# CLI 模式
# ============================================================

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"artist": None, "title": None, "is_music": False}))
        sys.exit(0)

    title = sys.argv[1]
    music = is_likely_music(title)
    artist, song_title = parse(title) if music else (None, None)

    print(json.dumps({
        "artist": artist,
        "title": song_title,
        "is_music": music,
    }, ensure_ascii=False))
