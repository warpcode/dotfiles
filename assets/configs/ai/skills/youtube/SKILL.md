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
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/transcript.py "https://www.youtube.com/watch?v=VIDEO_ID"
```

### 2. List Channel/Playlist Videos
To browse a channel or see the contents of a playlist, use the `channel.py` script. It outputs video metadata in JSON format.

**Usage:**
```bash
# List all videos
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/channel.py "https://www.youtube.com/channel/CHANNEL_ID"

# List latest 5 videos
uv run --project assets/configs/ai/skills/youtube/scripts assets/configs/ai/skills/youtube/scripts/channel.py --count 5 "https://www.youtube.com/channel/CHANNEL_ID"
```

## Tools

### youtube_video_transcript
Extracts metadata and transcript from a YouTube video URL.

**Arguments:**
- `url` (string, required): The YouTube video URL.

**Example:**
Input: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
Output: Markdown formatted metadata followed by the timestamped transcript.

### youtube_channel_videos
Lists videos from a YouTube channel or playlist.

**Arguments:**
- `url` (string, required): The YouTube channel or playlist URL.
- `count` (integer, optional): Number of videos to list (default: all).

**Example:**
Input: `https://www.youtube.com/c/YouTube`, `count: 3`
Output: A sequence of JSON objects, one per video.
