#!/bin/bash
# Common GitHub API client for the github-cli skill.
# Provides a unified interface for making GitHub API requests (REST and GraphQL)
# by prioritizing the gh CLI and falling back to curl if needed.

# ---------------------------------------------------------------------------
# Authentication & Provider Detection
# ---------------------------------------------------------------------------

_detect_github_provider() {
  if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    echo "gh"
  elif [[ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
    echo "curl"
  else
    echo "none"
  fi
}

GITHUB_PROVIDER=$(_detect_github_provider)

# ---------------------------------------------------------------------------
# API Request Wrapper
# ---------------------------------------------------------------------------

#######################################
# Unified GitHub API request function.
# Arguments:
#   $1 - HTTP Method (GET, POST, PATCH, DELETE, etc.)
#   $2 - API endpoint path (e.g., /repos/owner/repo/issues)
#   $@ - Additional flags (e.g., -d '{"title":"..."}' or --input file)
# Returns:
#   API response to stdout.
#######################################
github_api_request() {
  local method="$1"
  local endpoint="$2"
  shift 2

  case "$GITHUB_PROVIDER" in
    "gh")
      gh api -X "$method" "$endpoint" "$@"
      ;;
    "curl")
      local token="${GITHUB_TOKEN:-$GH_TOKEN}"
      local base_url="https://api.github.com"
      local curl_args=()
      local input_file=""

      # Strip leading slash if present
      endpoint="${endpoint#/}"

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --input)
            input_file="$2"
            shift 2
            ;;
          *)
            curl_args+=("$1")
            shift
            ;;
        esac
      done

      if [[ -n "$input_file" ]]; then
        curl -s -X "$method" \
          -H "Authorization: Bearer $token" \
          -H "Accept: application/vnd.github+json" \
          "$base_url/$endpoint" "${curl_args[@]}" \
          -d @"$input_file"
      else
        curl -s -X "$method" \
          -H "Authorization: Bearer $token" \
          -H "Accept: application/vnd.github+json" \
          "$base_url/$endpoint" "${curl_args[@]}"
      fi
      ;;
    *)
      echo "Error: No GitHub authentication found. Run 'gh auth login' or set GITHUB_TOKEN." >&2
      return 1
      ;;
  esac
}

#######################################
# Unified GitHub GraphQL request function.
# Arguments:
#   $1 - GraphQL query (string or @file)
#   $@ - Additional flags (e.g., -F key=value or -f key=value)
# Returns:
#   API response to stdout.
#######################################
github_graphql_request() {
  local query="$1"
  shift

  case "$GITHUB_PROVIDER" in
    "gh")
      gh api graphql -f query="$query" "$@"
      ;;
    "curl")
      local token="${GITHUB_TOKEN:-$GH_TOKEN}"
      local variables_json="{}"

      # Extract variables from -F or -f flags
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -F|-f)
            local key_val="$2"
            local key="${key_val%%=*}"
            local val="${key_val#*=}"
            # Check if value is a number, boolean, or needs to be a string
            if [[ "$val" =~ ^[0-9]+$ || "$val" == "true" || "$val" == "false" ]]; then
                variables_json=$(jq -n --argjson vars "$variables_json" --arg key "$key" --argjson val "$val" '$vars + {($key): $val}')
            else
                variables_json=$(jq -n --argjson vars "$variables_json" --arg key "$key" --arg val "$val" '$vars + {($key): $val}')
            fi
            shift 2
            ;;
          *)
            shift
            ;;
        esac
      done

      local query_content
      if [[ "$query" == @* ]]; then
        query_content=$(cat "${query#@}")
      else
        query_content="$query"
      fi

      local payload
      payload=$(jq -n --arg query "$query_content" --argjson vars "$variables_json" '{query: $query, variables: $vars}')

      curl -s -X POST \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/graphql" \
        -d "$payload"
      ;;
    *)
      echo "Error: No GitHub authentication found. Run 'gh auth login' or set GITHUB_TOKEN." >&2
      return 1
      ;;
  esac
}
