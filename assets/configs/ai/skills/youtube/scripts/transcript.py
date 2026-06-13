#!/usr/bin/env python3
import sys
import re
import argparse
import json
import os
from youtube_transcript_api import YouTubeTranscriptApi
import yt_dlp
from jinja2 import Environment, FileSystemLoader

def extract_video_id(url):
    match = re.search(r'(?:v=|/)([a-zA-Z0-9_-]{11})', url)
    return match.group(1) if match else None

def fetch_video_info(url):
    try:
        with yt_dlp.YoutubeDL({'quiet': True}) as ydl:
            return ydl.extract_info(url, download=False)
    except Exception as e:
        print(f'Error fetching video info: {e}', file=sys.stderr)
        sys.exit(1)

def fetch_transcript(vid):
    transcript = []
    try:
        raw_transcript = YouTubeTranscriptApi.get_transcript(vid)
        for s in raw_transcript:
            mins, secs = divmod(int(s['start']), 60)
            transcript.append({
                'start': s['start'],
                'start_display': f'{mins:02d}:{secs:02d}',
                'text': s['text']
            })
    except Exception as e:
        print(f'Error fetching transcript: {e}', file=sys.stderr)
        # We continue even if transcript fails, metadata might still be useful
    return transcript

def get_transcript_data(url):
    vid = extract_video_id(url)
    if not vid:
        print(f'Error: Could not extract video ID from {url}', file=sys.stderr)
        sys.exit(1)

    info = fetch_video_info(url)
    transcript = fetch_transcript(vid)

    return {
        'title': info.get('title', 'Unknown Title'),
        'url': url,
        'uploader': info.get('uploader', 'Unknown'),
        'upload_date': info.get('upload_date', 'Unknown'),
        'duration_string': info.get('duration_string', 'Unknown'),
        'description': info.get('description', ''),
        'transcript': transcript
    }

def format_with_template(data):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    templates_dir = os.path.join(script_dir, '..', 'templates')
    template_file = 'video_transcript.md.tmpl'

    if not os.path.exists(os.path.join(templates_dir, template_file)):
        print(f"Warning: Template not found at {templates_dir}/{template_file}. Falling back to JSON.", file=sys.stderr)
        return json.dumps(data, indent=2)

    env = Environment(loader=FileSystemLoader(templates_dir), trim_blocks=True, lstrip_blocks=True)
    template = env.get_template(template_file)

    return template.render(**data).strip()

def main():
    parser = argparse.ArgumentParser(description='Fetch YouTube video transcript and metadata.')
    parser.add_argument('url', help='YouTube video URL')
    parser.add_argument('--raw', action='store_true', help='Output raw JSON data')
    args = parser.parse_args()

    data = get_transcript_data(args.url)

    if args.raw:
        print(json.dumps(data, indent=2))
    else:
        print(format_with_template(data))

if __name__ == '__main__':
    main()
