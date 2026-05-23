#!/usr/bin/env python3
import sys
import re
import argparse
from youtube_transcript_api import YouTubeTranscriptApi
import yt_dlp

def extract_video_id(url):
    match = re.search(r'(?:v=|/)([a-zA-Z0-9_-]{11})', url)
    return match.group(1) if match else None

def get_transcript(url):
    vid = extract_video_id(url)
    if not vid:
        print(f'Error: Could not extract video ID from {url}', file=sys.stderr)
        sys.exit(1)

    try:
        with yt_dlp.YoutubeDL({'quiet': True}) as ydl:
            info = ydl.extract_info(url, download=False)
    except Exception as e:
        print(f'Error fetching video info: {e}', file=sys.stderr)
        sys.exit(1)

    print(f'# {info.get("title", "Unknown Title")}')
    print(f'\n**URL:** {url}')
    print(f'**Channel:** {info.get("uploader", "Unknown")}')
    print(f'**Published:** {info.get("upload_date", "Unknown")}')
    print(f'**Duration:** {info.get("duration_string", "Unknown")}')
    print(f'\n## Description\n\n{info.get("description", "")}')
    print(f'\n## Transcript\n')

    try:
        transcript = YouTubeTranscriptApi.get_transcript(vid)
        for s in transcript:
            mins, secs = divmod(int(s['start']), 60)
            print(f'[{mins:02d}:{secs:02d}] {s["text"]}')
    except Exception as e:
        print(f'Error fetching transcript: {e}', file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Fetch YouTube video transcript and metadata.')
    parser.add_argument('url', help='YouTube video URL')
    args = parser.parse_args()

    get_transcript(args.url)

if __name__ == '__main__':
    main()
