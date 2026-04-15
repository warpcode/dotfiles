#!/usr/bin/env zsh

# tui.zsh - Terminal UI Components for Dotfiles
# Re-engineered for Zsh performance and conciseness.

zmodload zsh/zutil    # For zparseopts
zmodload zsh/datetime # For tui.date and tui.time

# --- Internal Helpers ---

typeset -gi TUI_INDENT_LEVEL=${TUI_INDENT_LEVEL:-0}
typeset -gi TUI_INDENT_WIDTH=${TUI_INDENT_WIDTH:-4}

_tui.indent() {
    printf '%*s' $(( TUI_INDENT_LEVEL * TUI_INDENT_WIDTH )) ''
}

_tui_err() { tui.error "$1"; return 1; }
tui.task() { print -P -- "$(_tui.indent)%F{blue}⚙︎ $*%f"; }
tui.start() { print -P -- "$(_tui.indent)%F{blue}🔧 $*%f"; }
tui.step() { print -P -- "$(_tui.indent)%F{blue}📝 $*%f"; }
tui.info() { print -P -- "$(_tui.indent)%F{blue}ℹ $*%f"; }
tui.success() { print -P -- "$(_tui.indent)%F{green}✓ $*%f"; }
tui.done() { print -P -- "$(_tui.indent)%F{green}✨ $*%f"; }
tui.warn() { print -P -- "$(_tui.indent)%F{yellow}⚠ $*%f"; }
tui.error() { print -P -- "$(_tui.indent)%F{red}✖ $*%f" >&2; }
tui.fatal() { print -P -- "$(_tui.indent)%F{red}❌ $*%f" >&2; }
tui.heading() { print -P -- "$(_tui.indent)%F{blue}$*%f"; }

tui.banner() {
    local text="$1"
    local char="${2:--}"
    local width="${3:-0}"
    local indent="$(_tui.indent)"
    local line

    (( ${#char} == 0 )) && char='-'
    (( width <= 0 )) && width=${#text}
    (( width < ${#text} )) && width=${#text}

    line=$(printf '%*s' "$width" '')
    line=${line// /$char}

    print -r -- "${indent}${line}"
    print -r -- "${indent}${text}"
    print -r -- "${indent}${line}"
}

tui.progress() {
    print -Pn -- "\r$(_tui.indent)%F{blue}🔍%f $*" >&2
}

tui.progress.clear() {
    print -Pn -- "\r\033[K" >&2
}

tui.indent.push() {
    local delta="${1:-1}"
    (( TUI_INDENT_LEVEL += delta ))
}

tui.indent.pop() {
    local delta="${1:-1}"
    (( TUI_INDENT_LEVEL -= delta ))
    (( TUI_INDENT_LEVEL < 0 )) && TUI_INDENT_LEVEL=0
}

tui.indent.reset() {
    TUI_INDENT_LEVEL=0
}

tui.with_indent() {
    local delta="${1:-1}"
    shift
    local old_level=$TUI_INDENT_LEVEL
    tui.indent.push "$delta"
    "$@"
    local ret=$?
    TUI_INDENT_LEVEL=$old_level
    return $ret
}

# --- Public API ---

# @description Read user input with support for defaults and validation.
# Flags: -d (default), -o (optional), -v (validation regex)
tui.input() {
    local -A opts; zparseopts -E -D -K -A opts d: o v:
    local prompt="${1:-Input}" default="$opts[-d]" validation="$opts[-v]"
    local value=""

    local display_prompt="$prompt${default:+ [%B$default%b]}: "
    
    while true; do
        print -Pn "%F{blue}➜%f $display_prompt" > /dev/tty
        if read -r value < /dev/tty; then
            value="${value:-$default}"

            if [[ -z "$value" ]]; then
                [[ -n "$opts[-o]" ]] && { echo ""; return 0; }
                continue
            fi

            if [[ -n "$validation" && ! "$value" =~ $validation ]]; then
                _tui_err "Invalid input (must match: $validation)"
                continue
            fi

            echo "$value"
            return 0
        else
            echo "" >&2
            [[ -n "$opts[-o]" ]] && return 0 || return 1
        fi
    done
}

# @description A styled Yes/No confirmation prompt (single-keypress).
# Flags: -d <y|n> (default)
tui.confirm() {
    local -A opts; zparseopts -E -D -K -A opts d:
    local prompt="${1:-Are you sure?}" default="${opts[-d]:l}"
    
    local suffix="[y/n]"
    [[ "$default" == "y" ]] && suffix="[%BY%bn/n]"
    [[ "$default" == "n" ]] && suffix="[y/%BN%bn]"

    print -Pn "%F{yellow}?%f $prompt $suffix " > /dev/tty
    
    # read -k 1 returns immediately after one character.
    local choice
    if read -k 1 choice < /dev/tty; then
        echo "" >&2
        case "${choice:l}" in
            y) return 0 ;;
            n) return 1 ;;
            $'\n'|$'\r') [[ "$default" == "y" ]] && return 0 || return 1 ;;
            *) return 1 ;;
        esac
    fi
    return 1
}

# @description Select items from a list using fzf.
# Flags: -c (custom), -o (optional), -m (multi), -p (prompt), -d (default)
tui.select() {
    local -A opts; zparseopts -E -D -K -A opts c o m p: d:
    local prompt="${1:-Select}" fzf_prompt="${opts[-p]:-$1}"
    shift # Remove prompt from $@
    
    local -a items=( "${(@)@:#}" ) # Native Zsh: Remove empty elements
    
    # Fast-path for single items
    if (( $#items == 1 )) && [[ -z "$opts[-o]$opts[-c]$opts[-m]" ]]; then
        echo "$items[1]"
        return 0
    fi

    (( $+commands[fzf] )) || return $(_tui_err "fzf not found")

    local hint="(Enter: confirm${opts[-m]:+, Tab: select}${opts[-c]:+, Ctrl-N: custom})"
    local -a fzf_cmd=( fzf --prompt "$fzf_prompt $hint> " --height 40% --reverse --ansi )
    [[ -n "$opts[-m]" ]] && fzf_cmd+=( -m )
    
    # Handle default selection
    if [[ -n "$opts[-d]" ]]; then
        local idx=${items[(i)*$opts[-d]*]}
        (( idx <= $#items )) && fzf_cmd+=( --bind "load:pos($idx)" )
    fi

    # Handle custom input via fzf reload mechanism
    local out
    if [[ -n "$opts[-c]" ]]; then
        local tmp=$(mktemp)
        trap "rm -f '$tmp'" EXIT
        print -l "${items[@]}" > "$tmp"
        
        local bind="ctrl-n:execute(read -r \"?Custom value: \" val < /dev/tty > /dev/tty; [[ -n \"\$val\" ]] && { print \"\$val\" | cat - \"$tmp\" > \"$tmp.new\" && mv \"$tmp.new\" \"$tmp\"; })+reload(cat \"$tmp\")+first"
        [[ -z "$opts[-m]" ]] && bind+="+accept" || bind+="+toggle+down"
        
        out=$( "${fzf_cmd[@]}" --bind "$bind" < "$tmp" )
    else
        out=$( print -l "${items[@]}" | "${fzf_cmd[@]}" )
    fi

    local ret=$?
    if (( ret == 0 )); then
        echo "$out"
    elif [[ -n "$opts[-o]" ]]; then
        return 0
    fi
    return $ret
}

tui.multiselect() { tui.select -m "$@"; }

# @description Date picker around today.
tui.date() {
    local -A opts; zparseopts -E -D -K -A opts d: p:
    local prompt="${opts[-p]:-${1:-Date}}" query="${opts[-d]:-Today}"
    local -a items=()
    
    # Generate dates using Zsh arithmetic and strftime
    local i ts d day label
    for i in {-30..90}; do
        ts=$(( EPOCHSECONDS + i * 86400 ))
        d=$(strftime "%Y-%m-%d" $ts)
        day=$(strftime "%a" $ts)
        case $i in
            0) label=" %F{green}[Today]%f" ;;
            1) label=" %F{blue}[Tomorrow]%f" ;;
            -1) label=" %F{yellow}[Yesterday]%f" ;;
            *) label="" ;;
        esac
        items+=( "$d ($day)$label" )
    done

    local selected=$(tui.select -p "$prompt" -d "$query" -c "${items[@]}")
    echo "${selected%% *}" # Return only the YYYY-MM-DD part
}

# @description Time picker (HH:MM:SS).
tui.time() {
    local -A opts; zparseopts -E -D -K -A opts d: p:
    local prompt="${opts[-p]:-${1:-Time}}"
    
    local h m s
    if [[ "$opts[-d]" =~ ^([0-9]{2}):([0-9]{2})(:([0-9]{2}))?$ ]]; then
        h="$match[1]" m="$match[2]" s="$match[4]"
    else
        h=$(strftime "%H" $EPOCHSECONDS)
        m=$(strftime "%M" $EPOCHSECONDS)
        s=$(strftime "%S" $EPOCHSECONDS)
    fi

    h=$(tui.select -p "$prompt (Hour)" -d "$h" {00..23}) || return 1
    m=$(tui.select -o -p "$prompt (Minute)" -d "$m" -c {00..59}) || return 1
    s=$(tui.select -o -p "$prompt (Second)" -d "$s" -c {00..59}) || return 1

    echo "${h:-00}:${m:-00}:${s:-00}"
}

# @description Preview a file with syntax highlighting.
tui.preview() {
    local file="$1" line="${2:-0}"
    [[ -f "$file" ]] || return 1

    # Zsh-native binary check via file command if available
    (( $+commands[file] )) && file -bi "$file" | grep -q 'binary' && return 1

    # 1. bat
    if (( $+commands[bat] )); then
        local -a args=( --style=numbers --color=always )
        (( line > 0 )) && args+=( --highlight-line "$line" )
        bat "${args[@]}" "$file"
        return
    fi

    # 2. pygmentize or print fallback
    local pcmd=${commands[pygmentize]:-$commands[pygmentise]}
    if [[ -n "$pcmd" ]]; then
        $pcmd -f terminal -g "$file" 2>/dev/null | {
            local i=0 content
            while IFS= read -r content; do
                (( ++i ))
                if (( i == line )); then
                    print -Pn "\r%F{red}>>>%f %5d: $content\n" "$i"
                else
                    print -Pn "    %5d: $content\n" "$i"
                fi
            done
        }
    else
        local -a lines=( ${(f)"$(<"$file")"} )
        local i=0
        for line_content in "${lines[@]}"; do
            (( ++i ))
            if (( i == line )); then
                print -Pn "%F{red}>>>%f %5d: $line_content\n" "$i"
            else
                print -Pn "    %5d: $line_content\n" "$i"
            fi
        done
    fi
}
