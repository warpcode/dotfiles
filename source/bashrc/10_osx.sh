[[ "$OSTYPE" =~ ^darwin ]] || return 1

# Start the screensaver
alias ss="open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"

if [[ -d "/Applications/Xcode.app" ]]; then
    #iOS Simulator quick launch
    alias iossim="open \"/Applications/Xcode.app/Contents/Applications/iPhone Simulator.app\""
fi


# Change working directory to the top-most Finder window location
function cdfinder() {
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}