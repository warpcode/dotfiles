---
name: youtube
description: Extract transcripts and metadata from YouTube videos, or list videos from channels and playlists. Use this skill whenever the user provides a YouTube URL and wants to understand its content, get a summary, or browse a channel's video history.
---

# YouTube Skill

A skill for interacting with YouTube content using standalone Python scripts and `uv`.

## Workflow

This skill orchestrates standalone Python scripts located in the `scripts/` directory. These scripts use `yt-dlp` and `youtube-transcript-api` to fetch data.

### 1. Extract Video Metadata & Transcript
To get the full context of a video, use the `transcript.py` script. It extracts the title, description, uploader, upload date, and a timestamped transcript.

**Usage:**
```bash
# Get formatted Markdown (default)
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/transcript.py "https://www.youtube.com/watch?v=VIDEO_ID"

# Get raw JSON payload
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/transcript.py --raw "https://www.youtube.com/watch?v=VIDEO_ID"
```

### 2. List Channel/Playlist Videos
To browse a channel or see the contents of a playlist, use the `channel.py` script. It outputs video metadata in JSON format.

**Usage:**
```bash
# List latest 10 videos (default truncation)
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/channel.py "https://www.youtube.com/channel/CHANNEL_ID"

# List specific number of videos
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/channel.py --count 5 "https://www.youtube.com/channel/CHANNEL_ID"

# Get all videos (raw mode, no truncation)
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/channel.py --raw "https://www.youtube.com/channel/CHANNEL_ID"
```

## Templates

Markdown output for video transcripts follows the structure defined in:
`assets/configs/ai/skills/youtube/templates/video_transcript.md.tmpl`

## Tools

### youtube_video_transcript
Extracts metadata and transcript from a YouTube video URL.

**Arguments:**
- `url` (string, required): The YouTube video URL.
- `raw` (boolean, optional): If true, returns the raw JSON metadata and transcript payload.

### youtube_channel_videos
Lists videos from a YouTube channel or playlist.

**Arguments:**
- `url` (string, required): The YouTube channel or playlist URL.
- `count` (integer, optional): Number of videos to list. Defaults to 10.
- `raw` (boolean, optional): If true, returns the full payload without truncation.
