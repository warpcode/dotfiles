#!/usr/bin/env python3
import sys
import argparse
import json
import yt_dlp

def list_videos(url, count=None):
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
        'dump_single_json': True,
    }
    if count:
        ydl_opts['playlist_items'] = f'1-{count}'

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            if 'entries' in info:
                for entry in info['entries']:
                    print(json.dumps(entry))
            else:
                # If it's a single video instead of a channel/playlist
                print(json.dumps(info))
    except Exception as e:
        print(f'Error fetching channel info: {e}', file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='List videos from a YouTube channel.')
    parser.add_argument('url', help='YouTube channel URL')
    parser.add_argument('--count', type=int, help='Number of videos to list')
    args = parser.parse_args()

    list_videos(args.url, args.count)

if __name__ == '__main__':
    main()
