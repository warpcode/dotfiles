#!/usr/bin/env zsh

# os.zsh - OS and architecture detection utilities with caching

# Detect if running in Termux
os.is_termux() {
    (( $+TERMUX_VERSION )) && [[ -d "$PREFIX" ]]
}

# Detect OS family (macos, debian, fedora, arch, termux, linux, or unknown)
os.family() {
    [[ -n "$__OS_FAMILY" ]] && { echo "$__OS_FAMILY"; return }

    local os="unknown"
    case "$OSTYPE" in
        darwin*) os="macos" ;;
        linux*)
            if os.is_termux; then os="termux"
            elif [[ -f /etc/os-release ]]; then
                local -A os_info
                local line key val
                for line in ${(f)"$(</etc/os-release)"}; do
                    [[ "$line" == [A-Z_]*=* ]] || continue
                    key="${line%%=*}"
                    val="${line#*=}"
                    # Remove quotes
                    val="${${val#[\"\']}%[\"\']}"
                    os_info[$key]="$val"
                done
                
                local id="${os_info[ID]}"
                local like="${os_info[ID_LIKE]}"
                
                case "$id" in
                    ubuntu|debian|pop|kali|linuxmint) os="debian" ;;
                    fedora|rhel|centos) os="fedora" ;;
                    arch|manjaro) os="arch" ;;
                    *) 
                        if [[ "$like" == *debian* ]]; then os="debian"
                        elif [[ "$like" == *fedora* ]]; then os="fedora"
                        elif [[ "$like" == *arch* ]]; then os="arch"
                        else os="${id:-linux}"
                        fi
                        ;;
                esac
            fi
            ;;
    esac
    export __OS_FAMILY="$os"
    echo "$os"
}

# Detect architecture (amd64, arm64, or raw uname)
os.arch() {
    [[ -n "$__OS_ARCH" ]] && { echo "$__OS_ARCH"; return }

    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
    esac
    export __OS_ARCH="$arch"
    echo "$arch"
}

# Environment checks
os.has_gui() {
    [[ "$OSTYPE" == darwin* && -z "$SSH_CONNECTION" ]] && return 0
    [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]
}

os.is_headless() {
    ! os.has_gui
}

# Filter input lines by architecture patterns
# Usage: os.filter_by_arch "input string" OR echo "input" | os.filter_by_arch
os.filter_by_arch() {
    local arch=$(os.arch) p
    case "$arch" in
        amd64) p="(amd64|x86_64|x64)" ;;
        arm64) p="(arm64|aarch64)" ;;
        *)     p="$arch" ;;
    esac
    
    # Zsh-first filtering
    if [[ -n "$1" ]]; then
        local -a lines=( ${(f)1} )
        print -l ${(M)lines:#(#i)*$~p*}
    else
        local line
        while read -r line; do
            [[ "$line" == (#i)*$~p* ]] && echo "$line"
        done
    fi
}
