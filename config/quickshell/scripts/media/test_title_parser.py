#!/usr/bin/env python3
"""title_parser 测试用例

覆盖:
  - Bilibili 用户 6 例
  - 非音乐判定
  - parse 不触发 (无全角括号)
  - YouTube 回归 (含全角括号的 YouTube 标题)
  - 噪声标题
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from title_parser import parse, is_likely_music


class TestIsLikelyMusic(unittest.TestCase):
    """is_likely_music() 判定测试。"""

    def test_music_true(self):
        """应判定为音乐内容。"""
        cases = [
            # YouTube 系
            "Sum 41 - In Too Deep (Official Video)",
            "Dua Lipa - New Rules (Official Music Video)",
            # Bilibili 系
            "【初音未来】神曲【R Sound Design】",
            "【可不】Kyu-kurarin【いよわ】",
            "【米津玄師】KICK BACK【MV】",
            # 含「」的
            "【主题曲】葬送的芙莉莲「勇者」by YOASOBI",
            # 纯音乐关键词
            "周杰伦 - 晴天 MV",
            "Official Music: Hello World",
        ]
        for title in cases:
            with self.subTest(title=title):
                self.assertTrue(is_likely_music(title),
                                f"Should be music: {title}")

    def test_music_false(self):
        """应判定为非音乐内容。"""
        cases = [
            "【実況】マイクラ実況 Part1【ゲーム】",
            "【ゲーム実況】ゼルダの伝説 Part5",
            "2024年最新ゲームレビュー",
            "今天天气真好啊 Vlog 日常",
            "Vlog: My Daily Routine",
            "电影完整版 2024 最新",
            "ASMR 料理 作り方",
            "【実況】原神 攻略 解説",
        ]
        for title in cases:
            with self.subTest(title=title):
                self.assertFalse(is_likely_music(title),
                                 f"Should NOT be music: {title}")

    def test_empty(self):
        self.assertFalse(is_likely_music(""))
        self.assertFalse(is_likely_music("   "))


class TestParseNoFullwidth(unittest.TestCase):
    """无全角括号时 parse() 应返回 (None, None)。"""

    def test_no_brackets(self):
        cases = [
            "Sum 41 - In Too Deep (Official Video)",
            "Dua Lipa - New Rules",
            "普通视频",
            "Just a regular title",
        ]
        for title in cases:
            with self.subTest(title=title):
                artist, song = parse(title)
                self.assertIsNone(artist, f"artist should be None for: {title}")
                self.assertIsNone(song, f"song should be None for: {title}")


class TestParseBilibili(unittest.TestCase):
    """Bilibili 用户 6 例 + 扩展。"""

    def test_example_1_vocaloid(self):
        """【初音未来】神曲【R Sound Design】【但丁】"""
        artist, title = parse("【初音未来】神曲【R Sound Design】【但丁】")
        self.assertIsNotNone(title)
        self.assertEqual(title, "神曲")
        self.assertIn("R Sound Design", artist)

    def test_example_2_kafu(self):
        """【可不】Kyu-kurarin【いよわ】"""
        artist, title = parse("【可不】Kyu-kurarin【いよわ】")
        self.assertEqual(title, "Kyu-kurarin")
        self.assertIn("いよわ", artist)

    def test_example_3_kagamine(self):
        """【鏡音リン】少女A【椎名もた】"""
        artist, title = parse("【鏡音リン】少女A【椎名もた】")
        self.assertEqual(title, "少女A")
        self.assertIn("椎名もた", artist)

    def test_example_4_cyberpunk(self):
        """《赛博朋克》I Really Want to Stay at Your House【Hi-Res…】"""
        artist, title = parse(
            "《赛博朋克：边缘行者》I Really Want to Stay at Your House"
            "【Hi-Res百万级录音棚试听】"
        )
        self.assertEqual(title, "I Really Want to Stay at Your House")

    def test_example_5_utada(self):
        """【One Last Kiss｜宇多田光】…《One Last Kiss》…【Hi-Res】"""
        artist, title = parse(
            "【One Last Kiss｜宇多田光】百万级录音棚听"
            "《One Last Kiss》《新·福音战士剧场版:│▌》【Hi-Res】"
        )
        self.assertEqual(title, "One Last Kiss")
        self.assertEqual(artist, "宇多田光")

    def test_example_6_frieren(self):
        """【主题曲/完整版/官方MV】葬送的芙莉莲「勇者」by YOASOBI…"""
        artist, title = parse(
            "【主题曲/完整版/官方MV】葬送的芙莉莲 "
            "主题曲OP「勇者」by YOASOBI 动画MV【4K画质】"
        )
        self.assertEqual(title, "勇者")
        self.assertIn("YOASOBI", artist)

    def test_kpop_quoted(self):
        """YouTube K-pop 引号格式 (含全角括号变体)"""
        artist, title = parse(
            '【MV】TWICE(트와이스) "OOH-AHH하게(Like OOH-AHH)" M/V'
        )
        self.assertEqual(title, "OOH-AHH하게(Like OOH-AHH)")
        self.assertIn("TWICE", artist)

    def test_bilibili_corner_brackets(self):
        """「」内歌名 + by 艺术家"""
        artist, title = parse("【MV】葬送的芙莉莲「勇者」by YOASOBI 完整版")
        self.assertEqual(title, "勇者")
        self.assertIn("YOASOBI", artist)

    def test_no_artist_bracket(self):
        """只有 fluff 括号, 没有艺术家括号"""
        artist, title = parse(
            "【Hi-Res】I Really Want to Stay at Your House【4K画质】"
        )
        self.assertEqual(title, "I Really Want to Stay at Your House")
        # artist 可能为 None 或空字符串
        self.assertTrue(artist is None or artist == "")

    def test_artist_with_pipe(self):
        """【歌名｜艺术家】→ 艺术家 = ｜右边"""
        artist, title = parse("【夜に駆ける｜YOASOBI】Official MV【4K】")
        self.assertEqual(artist, "YOASOBI")
        self.assertIn("夜に駆ける", title)


if __name__ == "__main__":
    unittest.main(verbosity=2)
