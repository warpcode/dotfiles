
# find the first parent file that contains a list of specified files
find_parent_path() {
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
