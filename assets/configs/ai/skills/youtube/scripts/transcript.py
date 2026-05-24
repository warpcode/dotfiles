#!/usr/bin/env python3
import sys
import re
import argparse
import json
import os
from youtube_transcript_api import YouTubeTranscriptApi
import yt_dlp

def extract_video_id(url):
    match = re.search(r'(?:v=|/)([a-zA-Z0-9_-]{11})', url)
    return match.group(1) if match else None

def get_transcript_data(url):
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
    template_path = os.path.join(script_dir, '..', 'templates', 'video_transcript.md.tmpl')

    if not os.path.exists(template_path):
        print(f"Warning: Template not found at {template_path}. Falling back to basic output.", file=sys.stderr)
        return json.dumps(data, indent=2)

    with open(template_path, 'r') as f:
        template = f.read()

    # Simple template rendering
    rendered = template
    rendered = rendered.replace('{{ .title }}', data['title'])
    rendered = rendered.replace('{{ .url }}', data['url'])
    rendered = rendered.replace('{{ .uploader }}', data['uploader'])
    rendered = rendered.replace('{{ .upload_date }}', data['upload_date'])
    rendered = rendered.replace('{{ .duration_string }}', data['duration_string'])
    rendered = rendered.replace('{{ .description }}', data['description'])

    # Handle the range loop for transcript
    transcript_placeholder = re.search(r'{{ range \.transcript -}}(.*?){{ end -}}', rendered, re.DOTALL)
    if transcript_placeholder:
        loop_content = transcript_placeholder.group(1)
        transcript_lines = []
        for s in data['transcript']:
            line = loop_content.replace('{{ .start_display }}', s['start_display'])
            line = line.replace('{{ .text }}', s['text'])
            transcript_lines.append(line)

        rendered = rendered[:transcript_placeholder.start()] + ''.join(transcript_lines) + rendered[transcript_placeholder.end():]

    return rendered.strip()

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
