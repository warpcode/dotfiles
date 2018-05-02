# Find the most commonly used executables in order
function ha(){
    history | awk '{a[$4]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head -n "${@:-20}";
}

# create directory and cd into it
function mkcd() {
    mkdir -p "$@" && cd "$@"
}
