import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import json
from io import StringIO

# Add parent directory to sys.path to find the transcript module
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from transcript import (
    extract_video_id,
    fetch_video_info,
    fetch_transcript,
    get_transcript_data,
    format_with_template,
    main,
)

class TestTranscript(unittest.TestCase):

    def test_extract_video_id_valid_watch_url(self):
        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        self.assertEqual(extract_video_id(url), "dQw4w9WgXcQ")

    def test_extract_video_id_valid_short_url(self):
        url = "https://youtu.be/dQw4w9WgXcQ"
        self.assertEqual(extract_video_id(url), "dQw4w9WgXcQ")

    def test_extract_video_id_invalid_url(self):
        url = "https://example.com/abc"
        self.assertIsNone(extract_video_id(url))

    @patch("yt_dlp.YoutubeDL")
    def test_fetch_video_info_success(self, mock_youtube_dl):
        mock_ydl_instance = MagicMock()
        mock_youtube_dl.return_value.__enter__.return_value = mock_ydl_instance
        mock_ydl_instance.extract_info.return_value = {"title": "Test Title"}

        info = fetch_video_info("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        self.assertEqual(info, {"title": "Test Title"})
        mock_ydl_instance.extract_info.assert_called_once_with(
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ", download=False
        )

    @patch("yt_dlp.YoutubeDL")
    def test_fetch_video_info_error(self, mock_youtube_dl):
        mock_ydl_instance = MagicMock()
        mock_youtube_dl.return_value.__enter__.return_value = mock_ydl_instance
        mock_ydl_instance.extract_info.side_effect = Exception("DL error")

        with self.assertRaises(SystemExit) as cm:
            fetch_video_info("https://www.youtube.com/watch?v=invalid")
        self.assertEqual(cm.exception.code, 1)

    @patch("transcript.YouTubeTranscriptApi")
    def test_fetch_transcript_get_transcript_success(self, mock_api):
        mock_api.get_transcript.return_value = [
            {"start": 65.0, "text": "First snippet"},
            {"start": 125.0, "text": "Second snippet"},
        ]

        result = fetch_transcript("dQw4w9WgXcQ")
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["start_display"], "01:05")
        self.assertEqual(result[0]["text"], "First snippet")
        self.assertEqual(result[1]["start_display"], "02:05")
        self.assertEqual(result[1]["text"], "Second snippet")

    @patch("transcript.YouTubeTranscriptApi", spec=["list_transcripts"])
    def test_fetch_transcript_list_transcripts_fallback(self, mock_api):
        mock_transcript_obj = MagicMock()
        mock_transcript_obj.fetch.return_value = [
            {"start": 10.0, "text": "Fallback text"}
        ]
        mock_api.list_transcripts.return_value.find_transcript.return_value = (
            mock_transcript_obj
        )

        result = fetch_transcript("dQw4w9WgXcQ")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["start_display"], "00:10")
        self.assertEqual(result[0]["text"], "Fallback text")

    @patch("transcript.YouTubeTranscriptApi")
    def test_fetch_transcript_exception_returns_empty(self, mock_api):
        mock_api.get_transcript.side_effect = Exception("No transcript available")

        result = fetch_transcript("dQw4w9WgXcQ")
        self.assertEqual(result, [])

    @patch("transcript.fetch_transcript")
    @patch("transcript.fetch_video_info")
    @patch("transcript.extract_video_id")
    def test_get_transcript_data_success(
        self, mock_extract_id, mock_fetch_info, mock_fetch_trans
    ):
        mock_extract_id.return_value = "dQw4w9WgXcQ"
        mock_fetch_info.return_value = {
            "title": "Video Title",
            "uploader": "Uploader Name",
            "upload_date": "20230101",
            "duration_string": "10:00",
            "description": "Video Description",
        }
        mock_fetch_trans.return_value = [{"start": 0, "start_display": "00:00", "text": "Hi"}]

        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        data = get_transcript_data(url)

        self.assertEqual(data["title"], "Video Title")
        self.assertEqual(data["url"], url)
        self.assertEqual(data["uploader"], "Uploader Name")
        self.assertEqual(data["upload_date"], "20230101")
        self.assertEqual(data["duration_string"], "10:00")
        self.assertEqual(data["description"], "Video Description")
        self.assertEqual(len(data["transcript"]), 1)

    @patch("transcript.extract_video_id")
    def test_get_transcript_data_invalid_url_exits(self, mock_extract_id):
        mock_extract_id.return_value = None
        with self.assertRaises(SystemExit) as cm:
            get_transcript_data("https://invalid.com")
        self.assertEqual(cm.exception.code, 1)

    @patch("os.path.exists")
    def test_format_with_template_missing_template(self, mock_exists):
        mock_exists.return_value = False
        data = {"title": "Test Video", "transcript": []}
        result = format_with_template(data)
        self.assertEqual(result, json.dumps(data, indent=2))

    @patch("transcript.Environment")
    @patch("os.path.exists")
    def test_format_with_template_success(self, mock_exists, mock_env_cls):
        mock_exists.return_value = True
        mock_env = MagicMock()
        mock_template = MagicMock()
        mock_env.get_template.return_value = mock_template
        mock_template.render.return_value = "  Rendered Content  "
        mock_env_cls.return_value = mock_env

        data = {"title": "Test Video"}
        result = format_with_template(data)
        self.assertEqual(result, "Rendered Content")

    @patch("sys.stdout", new_callable=StringIO)
    @patch("transcript.get_transcript_data")
    def test_main_raw_flag(self, mock_get_data, mock_stdout):
        mock_get_data.return_value = {"title": "Test Video", "transcript": []}
        test_args = ["transcript.py", "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "--raw"]

        with patch.object(sys, "argv", test_args):
            main()

        output = mock_stdout.getvalue()
        self.assertIn('"title": "Test Video"', output)

    @patch("sys.stdout", new_callable=StringIO)
    @patch("transcript.format_with_template")
    @patch("transcript.get_transcript_data")
    def test_main_default(self, mock_get_data, mock_format, mock_stdout):
        mock_get_data.return_value = {"title": "Test Video", "transcript": []}
        mock_format.return_value = "# Test Video"
        test_args = ["transcript.py", "https://www.youtube.com/watch?v=dQw4w9WgXcQ"]

        with patch.object(sys, "argv", test_args):
            main()

        output = mock_stdout.getvalue().strip()
        self.assertEqual(output, "# Test Video")

if __name__ == "__main__":
    unittest.main()
