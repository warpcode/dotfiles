[[ "$OSTYPE" =~ ^darwin ]] || return 1

# OSX doesn't have /usr/local/bin in the path
_prepend_to_path "/usr/local/bin"


# Start the screensaver
alias ss="open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"

if [[ -d "/Applications/Xcode.app" ]]; then
    #iOS Simulator quick launch
    alias iossim="open \"/Applications/Xcode.app/Contents/Applications/iPhone Simulator.app\""
fi