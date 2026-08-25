import unittest
import sys
import os
import json
from unittest.mock import patch, MagicMock

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from transcript import (
    extract_video_id,
    fetch_video_info,
    fetch_transcript,
    get_transcript_data,
    format_with_template,
)

class TestTranscript(unittest.TestCase):
    def test_extract_video_id_valid(self):
        urls = [
            ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://youtu.be/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://www.youtube.com/embed/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
        ]
        for url, expected_id in urls:
            with self.subTest(url=url):
                self.assertEqual(extract_video_id(url), expected_id)

    def test_extract_video_id_invalid(self):
        invalid_urls = [
            "https://example.com/watch?v=invalid",
            "not_a_url",
            "",
        ]
        for url in invalid_urls:
            with self.subTest(url=url):
                self.assertIsNone(extract_video_id(url))

    @patch("transcript.yt_dlp.YoutubeDL")
    def test_fetch_video_info_success(self, mock_ydl_cls):
        mock_ydl = MagicMock()
        mock_ydl_cls.return_value.__enter__.return_value = mock_ydl
        mock_ydl.extract_info.return_value = {"title": "Test Title"}

        result = fetch_video_info("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        self.assertEqual(result, {"title": "Test Title"})
        mock_ydl.extract_info.assert_called_once_with("https://www.youtube.com/watch?v=dQw4w9WgXcQ", download=False)

    @patch("transcript.yt_dlp.YoutubeDL")
    def test_fetch_video_info_failure(self, mock_ydl_cls):
        mock_ydl = MagicMock()
        mock_ydl_cls.return_value.__enter__.return_value = mock_ydl
        mock_ydl.extract_info.side_effect = Exception("DL Error")

        with self.assertRaises(SystemExit) as cm:
            fetch_video_info("https://www.youtube.com/watch?v=invalid")
        self.assertEqual(cm.exception.code, 1)

    @patch("transcript.YouTubeTranscriptApi")
    def test_fetch_transcript_get_transcript_success(self, mock_api):
        mock_api.get_transcript.return_value = [
            {"start": 65, "text": "Hello world"}
        ]

        result = fetch_transcript("dQw4w9WgXcQ")
        expected = [
            {
                "start": 65,
                "start_display": "01:05",
                "text": "Hello world",
            }
        ]
        self.assertEqual(result, expected)

    @patch("transcript.YouTubeTranscriptApi")
    def test_fetch_transcript_list_transcripts_fallback(self, mock_api):
        del mock_api.get_transcript
        mock_item = MagicMock()
        mock_item.start = 125
        mock_item.text = "Fallback text"
        mock_item.__getitem__ = lambda self, key: getattr(self, key)

        mock_transcript_obj = MagicMock()
        mock_transcript_obj.fetch.return_value = [mock_item]

        mock_api.list_transcripts.return_value.find_transcript.return_value = mock_transcript_obj

        result = fetch_transcript("dQw4w9WgXcQ")
        expected = [
            {
                "start": 125,
                "start_display": "02:05",
                "text": "Fallback text",
            }
        ]
        self.assertEqual(result, expected)

    @patch("transcript.YouTubeTranscriptApi")
    def test_fetch_transcript_exception(self, mock_api):
        mock_api.get_transcript.side_effect = Exception("Transcript error")

        result = fetch_transcript("dQw4w9WgXcQ")
        self.assertEqual(result, [])

    @patch("transcript.fetch_transcript")
    @patch("transcript.fetch_video_info")
    @patch("transcript.extract_video_id")
    def test_get_transcript_data_success(self, mock_extract, mock_info, mock_transcript):
        mock_extract.return_value = "dQw4w9WgXcQ"
        mock_info.return_value = {
            "title": "Test Title",
            "uploader": "Test Uploader",
            "upload_date": "20230101",
            "duration_string": "03:45",
            "description": "Test Description",
        }
        mock_transcript.return_value = [{"start": 0, "start_display": "00:00", "text": "Hello"}]

        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        data = get_transcript_data(url)

        self.assertEqual(data["title"], "Test Title")
        self.assertEqual(data["url"], url)
        self.assertEqual(data["uploader"], "Test Uploader")
        self.assertEqual(data["upload_date"], "20230101")
        self.assertEqual(data["duration_string"], "03:45")
        self.assertEqual(data["description"], "Test Description")
        self.assertEqual(len(data["transcript"]), 1)

    @patch("transcript.extract_video_id")
    def test_get_transcript_data_invalid_url(self, mock_extract):
        mock_extract.return_value = None

        with self.assertRaises(SystemExit) as cm:
            get_transcript_data("invalid_url")
        self.assertEqual(cm.exception.code, 1)

    @patch("os.path.exists")
    def test_format_with_template_fallback_json(self, mock_exists):
        mock_exists.return_value = False
        data = {"title": "Test", "transcript": []}

        output = format_with_template(data)
        self.assertEqual(output, json.dumps(data, indent=2))

    @patch("transcript.Environment")
    @patch("os.path.exists")
    def test_format_with_template_render(self, mock_exists, mock_env_cls):
        mock_exists.return_value = True
        mock_env = MagicMock()
        mock_template = MagicMock()
        mock_template.render.return_value = " Rendered Content "
        mock_env.get_template.return_value = mock_template
        mock_env_cls.return_value = mock_env

        data = {"title": "Test Title"}
        output = format_with_template(data)

        self.assertEqual(output, "Rendered Content")

if __name__ == "__main__":
    unittest.main()
