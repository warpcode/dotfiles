
# Have on "open alias" on par with MacOS
if [[ ! "$OSTYPE" =~ ^darwin ]]; then
    open() {
        xdg-open ${@:-.}
    }
fi

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}
