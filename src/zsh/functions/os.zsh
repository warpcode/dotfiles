#!/usr/bin/env zsh

# Function to detect if the system is Termux
_os_is_termux() {
    if [[ -n "$TERMUX_VERSION" ]] && [[ -n "$PREFIX" && -d "$PREFIX" ]]; then
        return 0
    else
        return 1
    fi
}

# OS detection utilities
# Functions for detecting operating system and architecture

# Detect OS and return a string identifier
# Detect OS from $OSTYPE and /etc/os-release.
# @return string OS identifier
_os_detect_os_family() {
    case $OSTYPE in
        darwin*) echo macos ;;
        linux*)
            if _os_is_termux; then
                echo "termux"
                return
            fi
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
        aarch64|arm64) echo arm64 ;;
        *) uname -m ;;
    esac
}

# Check if the current environment has a GUI
# Returns 0 (true) if GUI detected, 1 (false) otherwise
_os_has_gui() {
    # macOS is assumed to be GUI unless strictly SSH without X11 forwarding
    if [[ "$OSTYPE" == darwin* ]]; then
        [[ -z "$SSH_CONNECTION" ]] && return 0
    fi

    # Linux/BSD: Check for X11 or Wayland display variables
    if [[ -n "$DISPLAY" ]] || [[ -n "$WAYLAND_DISPLAY" ]]; then
        return 0
    fi

    # Default to no GUI
    return 1
}

# Check if the current environment is headless (CLI only)
_os_is_headless() {
    if _os_has_gui; then
        return 1
    else
        return 0
    fi
}

# Filter input lines by architecture patterns
# @param input Text to filter
# @return Filtered lines matching current architecture
_os_filter_by_arch() {
    local input="$1"
    local arch=$(_os_detect_arch)
    local arch_patterns=()
    case $arch in
        amd64) arch_patterns=("amd64" "x86_64" "x64") ;;
        arm64) arch_patterns=("arm64" "aarch64") ;;
        *) arch_patterns=("$arch") ;;
    esac
    local arch_regex="($(IFS='|'; echo "${arch_patterns[*]}"))"
    echo "$input" | grep -E "$arch_regex"
}
