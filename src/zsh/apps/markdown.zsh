#!/usr/bin/env zsh

# Get the body content of a markdown file (everything after frontmatter)
# If no valid frontmatter exists, returns the entire file.
# Also cleans up leading empty lines from the body.
markdown.body.get() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Error: File '$file' not found." >&2; return 1 }

  awk '
    BEGIN { skip = 0 }
    NR == 1 && /^---$/ { skip = 1; next }
    skip == 1 && /^---$/ { skip = 0; next }
    skip == 0 { print }
  ' "$file" | sed '/./,$!d'
}

# Get the inner frontmatter content from a single markdown file
markdown.frontmatter.get() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Error: File '$file' not found." >&2; return 1 }
  awk '
    BEGIN { p = 0; found = 0 }
    NR == 1 && /^---$/ { p = 1; next }
    p == 1 && /^---$/ { p = 0; found = 1; exit }
    p == 1 { print }
    END { if (found == 0) exit 1 }
  ' "$file"
}

# Stream frontmatter from multiple files with 'path' attribute injection
# Returns a multi-document YAML stream suitable for yq processing.
markdown.frontmatter.get.all() {
  [[ $# -eq 0 ]] && return 0
  awk '
    FNR == 1 {
      if (in_fm) print "---"
      in_fm = 0; found_fm = 0
    }
    /^---$/ {
      if (!found_fm) {
        in_fm = 1; found_fm = 1
        print "---"; print "path: " FILENAME
        next
      } else if (in_fm) {
        in_fm = 0; print "---"
        next
      }
    }
    in_fm { print }
  ' "$@"
}

# Remove the entire frontmatter block from a markdown file
# Atomic: Uses markdown.body.get to safely extract and replace the file.
markdown.frontmatter.remove() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Error: File '$file' not found." >&2; return 1 }

  # Only attempt removal if the file actually starts with frontmatter
  [[ "$(head -n 1 "$file")" == "---" ]] || return 0

  local tmp=$(mktemp)
  if markdown.body.get "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    echo "Error: Failed to remove frontmatter from '$file'." >&2
    return 1
  fi
}

# Set/Replace the entire frontmatter in a markdown file
# Atomic: Prepares the new file in a temporary location before replacement.
markdown.frontmatter.set() {
  local file="$1" content="$2"
  [[ -f "$file" ]] || { echo "Error: File '$file' not found." >&2; return 1 }

  local tmp=$(mktemp)
  {
    echo "---"
    [[ -n "$content" ]] && echo "$content"
    echo "---"
    markdown.body.get "$file"
  } > "$tmp" && mv "$tmp" "$file" || { rm -f "$tmp"; return 1 }
}

# Validate the YAML frontmatter using 'yq'
# Returns 0 if valid, non-zero otherwise.
markdown.frontmatter.validate() {
  local file="$1"
  [[ -f "$file" ]] || { echo "Error: File '$file' not found." >&2; return 1 }

  local fm
  fm=$(markdown.frontmatter.get "$file") || {
    echo "Error: No frontmatter found or invalid structure in '$file' (must start and end with '---')." >&2
    return 1
  }

  # Validate YAML using yq
  if echo "${fm:-"{}"}" | yq '.' > /dev/null 2>&1; then
    return 0
  else
    echo "Error: Invalid YAML in frontmatter of '$file'." >&2
    return 1
  fi
}
