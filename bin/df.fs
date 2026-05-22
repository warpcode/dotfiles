#!/usr/bin/env zsh
#
# df.fs - Standalone Filesystem & Profile Utility

emulate -LR zsh
setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
typeset -r SCRIPT_DIR="${0:A:h}"

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Extract DOTFILES from relative script dir if missing
typeset -r DOTFILES_DIR="${DOTFILES:-${SCRIPT_DIR:h}}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
    print -r -- "df.fs: $*" >&2
}

_usage() {
    print -r -- "Usage: df.fs <command> [args...]"
    print -r -- ""
    print -r -- "Commands:"
    print -r -- "  profile name       - Get current active profile name"
    print -r -- "  profile set <name> - Set active profile to <name> and save to ~/.dotfiles_profile"
    print -r -- "  profile list <dir> [filename] - List config directories or file paths merging global/default with active profile overrides"
}

#######################################
# Get the current active profile name.
# Outputs:
#   Writes the active profile name to stdout.
# Returns:
#   0 on success.
#######################################
_cmd_profile_name() {
    if [[ -n "${DOTFILES_PROFILE:-}" ]]; then
        print -r -- "${DOTFILES_PROFILE}"
        return 0
    fi
    if [[ -f "${HOME}/.dotfiles_profile" ]]; then
        local p="$(<"${HOME}/.dotfiles_profile")"
        if [[ -n "${p}" ]]; then
            print -r -- "${p}"
            return 0
        fi
    fi
    print -r -- "default"
}

#######################################
# Set the current active profile.
# Arguments:
#   $1 - The name of the profile to set.
# Outputs:
#   Writes confirmation message to stdout.
# Returns:
#   0 on success, 1 if no name provided.
#######################################
_cmd_profile_set() {
    local target="$1"
    [[ -z "${target}" ]] && { err "profile set requires a profile name"; return 1; }

    echo "${target}" > "${HOME}/.dotfiles_profile"
    export DOTFILES_PROFILE="${target}"
    print -r -- "Profile set to: ${target}"
}

#######################################
# List paths to profile configuration files or directories, merging profile overrides with global base.
# Arguments:
#   $1 - The base directory.
#   $2 - (Optional) The specific file name/pattern to search for inside the directories.
# Outputs:
#   Writes matching file paths to stdout.
# Returns:
#   0 on success, 1 if missing base argument, base dir doesn't exist, or no matches found.
#######################################
_cmd_profile_list() {
    local dir="$1"
    local filename="${2:-}"
    [[ -z "${dir}" ]] && { err "profile list requires a base directory argument"; return 1; }

    # Resolves to absolute path relative to dotfiles if not absolute
    if [[ "${dir}" != /* ]]; then
        dir="${DOTFILES_DIR}/${dir}"
    fi

    [[ ! -d "${dir}" ]] && { err "Directory not found: ${dir}"; return 1; }

    local active_profile="$(_cmd_profile_name)"

    local -a search_dirs=()
    # If the exact profile directory exists inside the target base directory
    if [[ -d "${dir}/${active_profile}" ]]; then
        search_dirs+=( "${dir}/${active_profile}" )
    fi

    # Include 'global' if present
    if [[ "${active_profile}" != "global" && -d "${dir}/global" ]]; then
        search_dirs+=( "${dir}/global" )
    fi

    # If neither the profile nor global/default folders exist but the base dir does
    if [[ ${#search_dirs[@]} -eq 0 ]]; then
         search_dirs=( "${dir}" )
    fi

    local query="${filename:-*}"
    local found=0
    local d
    local -a matches
    local match_file
    # Use zsh globbing to handle wildcards in filename
    for d in "${search_dirs[@]}"; do
        matches=( ${d}/$~query(ND) )
        if [[ ${#matches[@]} -gt 0 ]]; then
            for match_file in "${matches[@]}"; do
                [[ -f "${match_file}" ]] && print -r -- "${match_file}"
            done
            found=1
        fi
    done

    # We output all instances across priority, caller decides which to use, e.g. for `df.secrets` merging
    (( found == 0 )) && return 1

    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Entry point.
# Arguments:
#   All script arguments passed through.
#######################################
main() {
    local cmd="${1:-}"
    shift || true

    case "${cmd}" in
        profile)
            local subcmd="${1:-}"
            shift || true
            case "${subcmd}" in
                name) _cmd_profile_name "$@" ;;
                set) _cmd_profile_set "$@" ;;
                list) _cmd_profile_list "$@" ;;
                *) err "Unknown profile command: ${subcmd}"; _usage; return 1 ;;
            esac
            ;;
        -h|--help) _usage ;;
        *) err "Unknown command: ${cmd}"; _usage; return 1 ;;
    esac
}

main "$@"
