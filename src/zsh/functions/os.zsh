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
        aarch64|arm64) echo arm64 ;;
        *) uname -m ;;
    esac
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
