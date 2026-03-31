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
        for f in "$@"; do [[ -e "$dir/$f" ]] && { echo "$dir"; return 0 }; done
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

# Pipe fs.search into fzf with previews and open-in-editor binding
fs.fzf() {
    local regex=false
    if [[ "$1" == "-r" ]]; then
        regex=true
        shift
    fi

    local query="$1"
    local dir="${2:-.}"
    local dotfiles="${DOTFILES:-$HOME/.config/dotfiles}"

    local init_cmd="source $dotfiles/src/zsh/init.zsh >/dev/null 2>&1"

    # Use positional arguments to sub-zsh to avoid quoting issues with {q}, {1}, etc.
    # Add sleep  for debouncing. fzf kills the previous reload process if a new one is triggered.
    local reload_cmd="zsh -c 'sleep 0.25; $init_cmd && if [[ \${#1} -gt 0 ]]; then fs.search $([[ "$regex" == "true" ]] && echo -r) -s \"\$1\" \"\$2\"; else :; fi' -- {q} \"$dir\""
    local preview_cmd="zsh -c '$init_cmd && tui.preview \"\$1\" \"\$2\" 10' -- {1} {2}"

    # Start with initial search if query provided, otherwise start empty
    { [[ -n "$query" ]] && fs.search $([[ "$regex" == "true" ]] && echo -r) -s "$query" "$dir" || : } \
        | command fzf --ansi --disabled --query "$query" \
            --bind "change:reload:$reload_cmd" \
            --delimiter ':' --preview-window=right:60%:wrap:+{2}-15 \
            --preview "$preview_cmd" \
            | while IFS=: read file line rest; do
                [[ -n "$file" ]] && ${VISUAL:-${EDITOR:-vim}} "+$line" "$file" < /dev/tty
            done
}
