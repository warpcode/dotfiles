# Find the most commonly used executables in order
function history_sort(){
    history | awk '{a[$4]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head -n "${1:-20}";
}

# create directory and cd into it
function mkcd() {
    mkdir -p "$@" && cd "$@"
}

if [[ "$OSTYPE" =~ ^darwin ]]
then
    # Change working directory to the top-most Finder window location
    function cdfinder() {
    	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
    }
fi
