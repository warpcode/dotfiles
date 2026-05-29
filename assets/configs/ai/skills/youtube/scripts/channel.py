#!/usr/bin/env python3
import sys
import argparse
import json
import yt_dlp

def _get_ydl_opts(count, raw):
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
        'dump_single_json': True,
    }

    # Apply default truncation of 10 if no count is provided and not raw
    if count is None and not raw:
        count = 10

    if count:
        ydl_opts['playlist_items'] = f'1-{count}'

    return ydl_opts


def _format_video_data(info, url):
    output = {
        'title': info.get('title'),
        'uploader': info.get('uploader'),
        'url': url,
        'entries': []
    }

    if 'entries' in info:
        for entry in info['entries']:
            output['entries'].append({
                'title': entry.get('title'),
                'url': entry.get('url') or f"https://www.youtube.com/watch?v={entry.get('id')}",
                'id': entry.get('id'),
                'duration': entry.get('duration')
            })
    else:
        # If it's a single video instead of a channel/playlist
        output['entries'].append({
            'title': info.get('title'),
            'url': url,
            'id': info.get('id'),
            'duration': info.get('duration')
        })

    return output


def list_videos(url, count=None, raw=False):
    ydl_opts = _get_ydl_opts(count, raw)

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        output = _format_video_data(info, url)

        if raw:
            # In raw mode, we might want to return the full yt-dlp info
            # but for now, let's just return our structured output as it's cleaner
            print(json.dumps(output, indent=2))
        else:
            # Print as a single JSON object for easier parsing by jq
            print(json.dumps(output))


def main():
    parser = argparse.ArgumentParser(description='List videos from a YouTube channel.')
    parser.add_argument('url', help='YouTube channel URL')
    parser.add_argument('--count', type=int, help='Number of videos to list')
    parser.add_argument('--raw', action='store_true', help='Output raw JSON data without truncation')
    args = parser.parse_args()

    try:
        list_videos(args.url, args.count, args.raw)
    except Exception as e:
        print(f'Error fetching channel info: {e}', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
