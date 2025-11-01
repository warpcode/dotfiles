# OS detection utilities
# Functions for detecting operating system and architecture

# Detect OS and return a string identifier
# Detect OS from $OSTYPE and /etc/os-release.
# @return string OS identifier
_os_detect_os_family() {
    case $OSTYPE in
        darwin*) echo macos ;;
        linux*)
            [ -f /etc/os-release ] || { echo unknown; return; }
             . /etc/os-release
             case $ID in
                 ubuntu|debian) echo debian ;;
                  fedora|arch) echo "$ID" ;;
                 *) echo unsupported ;;
             esac
            ;;
        *) echo unknown ;;
    esac
}

# Detect architecture using uname.
# @return string arch identifier
_os_detect_arch() {
    case $(uname -m) in
        x86_64|amd64) echo amd64 ;;
        aarch64|arm64) echo aarch64 ;;
        *) uname -m ;;
    esac
}
