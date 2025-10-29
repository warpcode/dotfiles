
# Find the first parent directory containing any of the specified files/directories
# Searches upward from the current directory to the root
# @param files Array of file/directory names to search for
# @return 0 if found (echoes path), 1 if not found
_fs_find_parent_path() {
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
