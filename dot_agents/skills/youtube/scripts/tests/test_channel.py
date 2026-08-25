import json
import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# Add parent directory of tests to sys.path so we can import channel
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import channel


class TestChannelScript(unittest.TestCase):
    def test_get_ydl_opts_defaults(self):
        opts = channel._get_ydl_opts(count=None, raw=False)
        self.assertEqual(opts["quiet"], True)
        self.assertEqual(opts["extract_flat"], True)
        self.assertEqual(opts["dump_single_json"], True)
        self.assertEqual(opts["playlist_items"], "1-10")

    def test_get_ydl_opts_custom_count(self):
        opts = channel._get_ydl_opts(count=5, raw=False)
        self.assertEqual(opts["playlist_items"], "1-5")

    def test_get_ydl_opts_raw_without_count(self):
        opts = channel._get_ydl_opts(count=None, raw=True)
        self.assertNotIn("playlist_items", opts)

    def test_get_ydl_opts_raw_with_count(self):
        opts = channel._get_ydl_opts(count=3, raw=True)
        self.assertEqual(opts["playlist_items"], "1-3")

    def test_format_video_data_channel_with_entries(self):
        info = {
            "title": "Test Channel",
            "uploader": "Test Uploader",
            "entries": [
                {
                    "title": "Video 1",
                    "url": "https://www.youtube.com/watch?v=vid1",
                    "id": "vid1",
                    "duration": 120,
                },
                {
                    "title": "Video 2",
                    "url": None,
                    "id": "vid2",
                    "duration": 300,
                },
            ],
        }
        url = "https://www.youtube.com/channel/UC123"
        result = channel._format_video_data(info, url)

        self.assertEqual(result["title"], "Test Channel")
        self.assertEqual(result["uploader"], "Test Uploader")
        self.assertEqual(result["url"], url)
        self.assertEqual(len(result["entries"]), 2)
        self.assertEqual(result["entries"][0]["title"], "Video 1")
        self.assertEqual(result["entries"][0]["url"], "https://www.youtube.com/watch?v=vid1")
        self.assertEqual(result["entries"][1]["url"], "https://www.youtube.com/watch?v=vid2")

    def test_format_video_data_single_video(self):
        info = {
            "title": "Single Video",
            "uploader": "Creator",
            "id": "single123",
            "duration": 200,
        }
        url = "https://www.youtube.com/watch?v=single123"
        result = channel._format_video_data(info, url)

        self.assertEqual(result["title"], "Single Video")
        self.assertEqual(len(result["entries"]), 1)
        self.assertEqual(result["entries"][0]["title"], "Single Video")
        self.assertEqual(result["entries"][0]["url"], url)
        self.assertEqual(result["entries"][0]["id"], "single123")
        self.assertEqual(result["entries"][0]["duration"], 200)

    @patch("yt_dlp.YoutubeDL")
    def test_list_videos(self, mock_youtube_dl):
        mock_ydl_instance = MagicMock()
        mock_youtube_dl.return_value.__enter__.return_value = mock_ydl_instance
        mock_ydl_instance.extract_info.return_value = {
            "title": "Channel Name",
            "uploader": "Uploader Name",
            "entries": [
                {
                    "title": "Video A",
                    "id": "vA",
                    "duration": 100,
                }
            ],
        }

        url = "https://www.youtube.com/c/testchannel"
        res = channel.list_videos(url, count=5, raw=False)

        mock_youtube_dl.assert_called_once_with({
            "quiet": True,
            "extract_flat": True,
            "dump_single_json": True,
            "playlist_items": "1-5",
        })
        mock_ydl_instance.extract_info.assert_called_once_with(url, download=False)
        self.assertEqual(res["title"], "Channel Name")
        self.assertEqual(res["entries"][0]["id"], "vA")

    @patch("channel.list_videos")
    def test_main_default(self, mock_list_videos):
        mock_list_videos.return_value = {
            "title": "Test Channel",
            "uploader": "Test Uploader",
            "url": "https://www.youtube.com/channel/UC123",
            "entries": [],
        }

        test_args = ["channel.py", "https://www.youtube.com/channel/UC123"]
        with patch.object(sys, "argv", test_args):
            with patch("builtins.print") as mock_print:
                channel.main()
                mock_list_videos.assert_called_once_with(
                    "https://www.youtube.com/channel/UC123", None, False
                )
                mock_print.assert_called_once_with(
                    json.dumps(mock_list_videos.return_value)
                )

    @patch("channel.list_videos")
    def test_main_raw_and_count(self, mock_list_videos):
        mock_list_videos.return_value = {
            "title": "Test Channel",
            "uploader": "Test Uploader",
            "url": "https://www.youtube.com/channel/UC123",
            "entries": [],
        }

        test_args = [
            "channel.py",
            "https://www.youtube.com/channel/UC123",
            "--count",
            "3",
            "--raw",
        ]
        with patch.object(sys, "argv", test_args):
            with patch("builtins.print") as mock_print:
                channel.main()
                mock_list_videos.assert_called_once_with(
                    "https://www.youtube.com/channel/UC123", 3, True
                )
                mock_print.assert_called_once_with(
                    json.dumps(mock_list_videos.return_value, indent=2)
                )

    @patch("channel.list_videos")
    def test_main_error_handling(self, mock_list_videos):
        mock_list_videos.side_effect = RuntimeError("Network error")

        test_args = ["channel.py", "https://www.youtube.com/channel/UC123"]
        with patch.object(sys, "argv", test_args):
            with patch("sys.stderr.write") as mock_stderr:
                with self.assertRaises(SystemExit) as cm:
                    channel.main()
                self.assertEqual(cm.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
