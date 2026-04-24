##
# Download YouTube transcripts and metadata using uvx
#
# @param string $1 YouTube URL
##
youtube.video.transcript() {
    uvx --with youtube-transcript-api --with yt-dlp python -c "
import sys, re
from youtube_transcript_api import YouTubeTranscriptApi
import yt_dlp

url = sys.argv[1]
match = re.search(r'(?:v=|/)([a-zA-Z0-9_-]{11})', url)
if not match:
    print(f'Error: Could not extract video ID from {url}', file=sys.stderr)
    sys.exit(1)
vid = match.group(1)

with yt_dlp.YoutubeDL({'quiet': True}) as ydl:
    info = ydl.extract_info(url, download=False)

print(f'# {info[\"title\"]}')
print(f'\n**URL:** {url}')
print(f'**Channel:** {info.get(\"uploader\", \"\")}')
print(f'**Published:** {info.get(\"upload_date\", \"\")}')
print(f'**Duration:** {info.get(\"duration_string\", \"\")}')
print(f'\n## Description\n\n{info.get(\"description\", \"\")}')
print(f'\n## Transcript\n')

try:
    for s in YouTubeTranscriptApi().fetch(vid):
        mins, secs = divmod(int(s.start), 60)
        print(f'[{mins:02d}:{secs:02d}] {s.text}')
except Exception as e:
    print(f'Error fetching transcript: {e}', file=sys.stderr)
" "$1"
}

##
# Get latest N videos from a YouTube channel as JSON
#
# @param string $1 YouTube channel URL
# @param int    $2 Number of videos (default: 10)
##
youtube.channel.latest() {
    local count="${2:-10}"
    uvx --with yt-dlp yt-dlp --flat-playlist --dump-json --playlist-end "$count" "$1"
}

##
# Get all videos from a YouTube channel as JSON
#
# @param string $1 YouTube channel URL
##
youtube.channel.all() {
    uvx --with yt-dlp yt-dlp --flat-playlist --dump-json "$1"
}
