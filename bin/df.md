#!/bin/bash
#
# df.md - Markdown and frontmatter utilities.
# Extracted from src/zsh/apps/markdown.zsh for portability.

emulate -LR zsh
setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL EXTENDED_GLOB

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
typeset -r SCRIPT_DIR="${0:A:h}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  print -r -- "df.md: $*" >&2
}

# ---------------------------------------------------------------------------
# Core Functions
# ---------------------------------------------------------------------------

#######################################
# Description: Get the body content of a markdown file (everything after frontmatter).
# If no valid frontmatter exists, returns the entire file.
# Also cleans up leading empty lines from the body.
#
# Arguments:
#   $1 The path to the markdown file.
# Outputs:
#   The body content of the markdown file.
# Returns:
#   0 On success.
#   1 If file is missing or not found.
#######################################
_body() {
  local file="${1:-}"
  [[ -n "$file" ]] || { err "Missing file argument."; return 1 }
  [[ -f "$file" ]] || { err "File '$file' not found."; return 1 }

  awk '
    BEGIN { skip = 0 }
    NR == 1 && /^---$/ { skip = 1; next }
    skip == 1 && /^---$/ { skip = 0; next }
    skip == 0 { if (length($0) > 0 || found) { print; found=1 } }
  ' "$file"
}

#######################################
# Description: Get the inner frontmatter content from a single markdown file.
#
# Arguments:
#   $1 The path to the markdown file.
# Outputs:
#   The frontmatter content.
# Returns:
#   0 On success.
#   1 If file is missing, not found, or has no valid frontmatter.
#######################################
_fm_get() {
  local file="${1:-}"
  [[ -n "$file" ]] || { err "Missing file argument."; return 1 }
  [[ -f "$file" ]] || { err "File '$file' not found."; return 1 }
  awk '
    BEGIN { p = 0; found = 0 }
    NR == 1 && /^---$/ { p = 1; next }
    p == 1 && /^---$/ { p = 0; found = 1; exit }
    p == 1 { print }
    END { if (found == 0) exit 1 }
  ' "$file"
}

#######################################
# Description: Stream frontmatter from multiple files with 'path' attribute injection.
# Returns a multi-document YAML stream suitable for yq processing.
#
# Arguments:
#   $@ Paths to the markdown files.
# Outputs:
#   Multi-document YAML stream.
# Returns:
#   0 Always.
#######################################
_fm_get_all() {
  [[ $# -eq 0 ]] && return 0
  awk '
    FNR == 1 {
      if (in_fm) print "---"
      in_fm = 0; found_fm = 0
    }
    /^---$/ {
      if (!found_fm) {
        in_fm = 1; found_fm = 1
        print "---"; printf "path: \"%s\"\n", FILENAME
        next
      } else if (in_fm) {
        in_fm = 0; print "---"
        next
      }
    }
    in_fm { print }
  ' "$@"
}

#######################################
# Description: Remove the entire frontmatter block from a markdown file.
# Atomic: Uses _body to safely extract and replace the file.
#
# Arguments:
#   $1 The path to the markdown file.
# Returns:
#   0 On success or if file has no frontmatter.
#   1 If file is missing, not found, or removal fails.
#######################################
_fm_remove() {
  local file="${1:-}"
  [[ -n "$file" ]] || { err "Missing file argument."; return 1 }
  [[ -f "$file" ]] || { err "File '$file' not found."; return 1 }

  # Only attempt removal if the file actually starts with frontmatter
  local first_line
  read -r first_line < "$file"
  [[ "${first_line}" == "---" ]] || return 0

  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/df.md.XXXXXX")
  if _body "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    err "Failed to remove frontmatter from '$file'."
    return 1
  fi
}

#######################################
# Description: Set/Replace the entire frontmatter in a markdown file.
# Atomic: Prepares the new file in a temporary location before replacement.
#
# Arguments:
#   $1 The path to the markdown file.
#   $2 The new frontmatter content (without leading/trailing '---').
# Returns:
#   0 On success.
#   1 If file is missing, not found, or replacement fails.
#######################################
_fm_set() {
  local file="${1:-}"
  local content="${2:-}"
  [[ -n "$file" ]] || { err "Missing file argument."; return 1 }
  [[ -f "$file" ]] || { err "File '$file' not found."; return 1 }

  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/df.md.XXXXXX")
  {
    print -r -- "---"
    [[ -n "$content" ]] && print -r -- "$content"
    print -r -- "---"
    _body "$file"
  } > "$tmp" && mv "$tmp" "$file" || { rm -f "$tmp"; return 1 }
}

#######################################
# Description: Validate the YAML frontmatter using 'yq'.
# Returns 0 if valid, non-zero otherwise.
#
# Arguments:
#   $1 The path to the markdown file.
# Returns:
#   0 If frontmatter is valid YAML.
#   1 If file is missing, not found, lacks frontmatter, or YAML is invalid.
#######################################
_fm_validate() {
  local file="${1:-}"
  [[ -n "$file" ]] || { err "Missing file argument."; return 1 }
  [[ -f "$file" ]] || { err "File '$file' not found."; return 1 }

  local fm
  fm=$(_fm_get "$file") || {
    err "No frontmatter found or invalid structure in '$file' (must start and end with '---')."
    return 1
  }

  # Validate YAML using yq
  if print -r -- "${fm:-"{}"}" | yq '.' > /dev/null 2>&1; then
    return 0
  else
    err "Invalid YAML in frontmatter of '$file'."
    return 1
  fi
}

_usage() {
  print -r -- "Usage: df.md <command>"
  print -r -- ""
  print -r -- "Commands:"
  print -r -- "  body        Extract body content from a markdown file."
  print -r -- "  fm get      Extract frontmatter from a single markdown file."
  print -r -- "  fm get-all  Stream frontmatter from multiple markdown files."
  print -r -- "  fm remove   Remove frontmatter from a markdown file."
  print -r -- "  fm set      Replace the frontmatter in a markdown file."
  print -r -- "  fm validate Validate the YAML frontmatter of a markdown file."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    body)
      shift; _body "$@" ;;
    fm)
      local subcmd="${2:-}"
      case "${subcmd}" in
        get)       shift 2; _fm_get "$@" ;;
        get-all)   shift 2; _fm_get_all "$@" ;;
        remove)    shift 2; _fm_remove "$@" ;;
        set)       shift 2; _fm_set "$@" ;;
        validate)  shift 2; _fm_validate "$@" ;;
        *)
          err "Unknown fm subcommand: ${subcmd:-<none>}"
          _usage >&2
          return 1
          ;;
      esac
      ;;
    -h|--help)
      _usage ;;
    *)
      err "Unknown command: ${cmd:-<none>}"
      _usage >&2
      return 1
      ;;
  esac
}

main "$@"