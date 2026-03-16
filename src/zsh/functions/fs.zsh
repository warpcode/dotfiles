
# Resolve a path within the dotfiles repository
# @param path Path relative to DOTFILES root (e.g., "configs/myapp" or "src/zsh/init.zsh")
# @return 0 if found (echoes full realpath), 1 if not found
fs.dotfiles.path() {
    local path="$1"

    if [[ -z "$path" ]]; then
        return 1
    fi

    if [[ -n "$DOTFILES" && -e "$DOTFILES/$path" ]]; then
        local full_path="$DOTFILES/$path"
        echo "${full_path:a:P}"
        return 0
    fi

    return 1
}

# Find the first parent directory containing any of the specified files/directories
# Searches upward from the current directory to the root
# @param files Array of file/directory names to search for
# @return 0 if found (echoes path), 1 if not found
fs.find.root() {
    local files=("$@")
    local dir="$PWD"

    for file in "${files[@]}"; do
        if [[ -e "$dir/$file" ]]; then
            echo "$dir/$file"
            return 0
        fi
    done

    while [[ "$dir" != "/" ]]; do
        for file in "${files[@]}"; do
            if [[ -e "$dir/$file" ]]; then
                echo "$dir/$file"
                return 0
            fi
        done
        dir=$(dirname "$dir")
    done

    return 1
}

# Search for a string in file contents recursively from the current directory
# @param -r Optional: Use regex search (default is literal string search)
# @param query The string to search for
# @param dir Optional: The directory to search in (default: .)
# @return 0 if matches found (echoes filename:line:match), 1 if none found
fs.search() {
    local regex=false
    if [[ "$1" == "-r" ]]; then
        regex=true
        shift
    fi

    local query="$1"
    local dir="${2:-.}"

    if [[ -z "$query" ]]; then
        echo "Usage: fs.search [-r] <query> [dir]" >&2
        return 1
    fi

    local grep_flags=("-n" "-I") # Removed -H as we use --heading or awk for filename

    if [[ "$regex" == "false" ]]; then
        grep_flags+=("-F")
    fi

    # If in a git repo, use git grep to respect .gitignore
    if git.cli rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git.cli --no-pager grep --recurse-submodules --heading --break "${grep_flags[@]}" "$query" -- "$dir"
    else
        grep -r "${grep_flags[@]}" \
            --exclude-dir={.git,.svn,CVS,node_modules,vendor,dist,build,.gemini,.opencode} \
            "$query" "$dir" | awk -F: '
            {
                if ($1 != last_file) {
                    if (last_file != "") print "";
                    print $1;
                    last_file = $1;
                }
                sub(/^[^:]+:/, "");
                print $0;
            }'
    fi
}



