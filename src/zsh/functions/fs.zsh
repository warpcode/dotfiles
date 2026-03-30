# fs.zsh - Filesystem utilities

# Resolve a path within the dotfiles repository
fs.dotfiles.path() {
    [[ -n "$1" && -n "$DOTFILES" ]] || return 1
    local full="${DOTFILES}/$1"
    [[ -e "$full" ]] || return 1
    echo "${full:a:P}"
}

# Find root directory containing markers
fs.find.root() {
    local dir=$PWD
    while [[ $dir != / ]]; do
        for f in "$@"; [[ -e "$dir/$f" ]] && { echo "$dir"; return 0 }
        dir=$dir:h
    done
    return 1
}

# Search for a string in file contents
fs.search() {
    local -A opts; zparseopts -E -D -K -A opts r s
    local query="$1" dir="${2:-.}"
    [[ -z "$query" ]] && { echo "Usage: fs.search [-r] [-s] <query> [dir]" >&2; return 1; }

    local -a flags=(-n -I)
    [[ -z "$opts[-r]" ]] && flags+=(-F)

    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local -a cmd=(git --no-pager grep --recurse-submodules "${flags[@]}")
        if [[ -n "$opts[-s]" ]]; then
            $cmd "$query" -- "$dir" | while IFS=: read -r file line_num content; do
                print "${file}:${line_num}:${content}"
            done
        else
            $cmd --heading --break "$query" -- "$dir"
        fi
    else
        local -a excludes=(.git .svn node_modules vendor dist build .gemini .opencode)
        local -a cmd=(grep -r "${flags[@]}")
        local d; for d in $excludes; cmd+=(--exclude-dir=$d)
        
        if [[ -n "$opts[-s]" ]]; then
            $cmd "$query" "$dir" | while IFS=: read -r file line_num content; do
                # Trim leading/trailing whitespace from line_num if needed
                print "${file}:${line_num}:${content}"
            done
        else
            local last="" file content
            $cmd "$query" "$dir" | while IFS=: read -r file content; do
                if [[ "$file" != "$last" ]]; then
                    [[ -n "$last" ]] && print ""
                    print -P "%F{blue}${file}%f"
                    last="$file"
                fi
                print -r -- "$content"
            done
        fi
    fi
}
