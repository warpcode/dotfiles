##
# Download YouTube transcripts and metadata
#
# @param string $1 YouTube URL
##
youtube.video.transcript() {
    local script_dir="${DOTFILES:-${HOME}/.dotfiles}/assets/configs/ai/skills/youtube/scripts"
    uv run --project "$script_dir" "$script_dir/transcript.py" "$1"
}

##
# Get latest N videos from a YouTube channel as JSON
#
# @param string $1 YouTube channel URL
# @param int    $2 Number of videos (default: 10)
##
youtube.channel.latest() {
    local count="${2:-10}"
    local script_dir="${DOTFILES:-${HOME}/.dotfiles}/assets/configs/ai/skills/youtube/scripts"
    uv run --project "$script_dir" "$script_dir/channel.py" --count "$count" "$1"
}

##
# Get all videos from a YouTube channel as JSON
#
# @param string $1 YouTube channel URL
##
youtube.channel.all() {
    local script_dir="${DOTFILES:-${HOME}/.dotfiles}/assets/configs/ai/skills/youtube/scripts"
    uv run --project "$script_dir" "$script_dir/channel.py" "$1"
}
