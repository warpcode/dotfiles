#!/bin/bash
#
# df.jira - Generic Jira REST API wrapper for searches and metadata.
#
# Usage: df.jira jql "issuetype = Epic" --max-results 10
#        df.jira issues MAR-123 MAR-456 --fields "summary,status"
#        df.jira fields "Story"

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly JIRA_API_VERSION="3"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
JIRA_URL="${JIRA_URL:-}"
JIRA_USER="${JIRA_USER:-}"
JIRA_API_TOKEN="${JIRA_API_TOKEN:-${JIRA_API_KEY:-}}"
VERBOSE=0
RAW_OUTPUT=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] df.jira: $*" >&2
}

die() {
  err "$*"
  exit 1
}

#######################################
# Resolve a secret using DF_SECRET_GET_CMD.
# Arguments:
#   $1 - Variable name to resolve.
#######################################
resolve_secret() {
  local name=$1

  # 1. Early return if already set in environment
  [[ -n "${!name:-}" ]] && return 0

  # 2. Special case for token: check JIRA_API_KEY if name is JIRA_API_TOKEN
  if [[ "$name" == "JIRA_API_TOKEN" && -n "${JIRA_API_KEY:-}" ]]; then
    export JIRA_API_TOKEN="${JIRA_API_KEY}"
    return 0
  fi

  # 3. Guard: resolver command must be defined
  if [[ -z "${DF_SECRET_GET_CMD:-}" ]]; then
    echo "Error: $name is missing and DF_SECRET_GET_CMD is undefined." >&2
    exit 1
  fi

  # 4. Resolve and export
  local value
  value=$($DF_SECRET_GET_CMD "$name")
  
  # 5. Fallback for token if requested name failed
  if [[ -z "$value" && "$name" == "JIRA_API_TOKEN" ]]; then
    value=$($DF_SECRET_GET_CMD "JIRA_API_KEY")
  fi

  export "$name"="$value"
}

check_deps() {
  local dep
  for dep in curl jq base64; do
    if ! command -v "$dep" >/dev/null; then
      die "Error: '$dep' is required but not found."
    fi
  done
}

_call_api() {
  local method="$1"
  local endpoint="$2"
  local payload="${3:-}"

  local auth_header
  auth_header="Basic $(printf "%s:%s" "${JIRA_USER}" "${JIRA_API_TOKEN}" | base64 | tr -d '\n')"

  local -a curl_opts=(
    -s
    -w "%{http_code}"
    -X "${method}"
    -H "Authorization: ${auth_header}"
    -H "Content-Type: application/json"
    -H "Accept: application/json"
  )

  if [[ -n "${payload}" ]]; then
    curl_opts+=(-d "${payload}")
  fi

  if [[ "${VERBOSE}" -eq 1 ]]; then
    err "Request: ${method} ${endpoint}"
    [[ -n "${payload}" ]] && err "Payload: ${payload}"
  fi

  local response_file
  response_file=$(mktemp)
  
  local http_code
  http_code=$(curl "${curl_opts[@]}" -o "${response_file}" "${endpoint}")
  local response
  response=$(cat "${response_file}")
  rm -f "${response_file}"

  if [[ "${http_code}" -lt 200 || "${http_code}" -ge 300 ]]; then
    if [[ "${VERBOSE}" -eq 1 ]]; then
      err "HTTP Status: ${http_code}"
      err "Response: ${response}"
    fi
    case "${http_code}" in
      401) die "Authentication failed (401)." ;;
      403) die "Forbidden (403)." ;;
      404) die "Not Found (404)." ;;
      400) die "Bad Request (400)." ;;
      *)   die "Request failed with HTTP ${http_code}." ;;
    esac
  fi

  echo "${response}"
}

# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

cmd_jql() {
  local query=""
  local max_results=50
  declare -A extra_params

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --max-results) max_results="$2"; shift 2 ;;
      --param)
        if [[ "$2" != *=* ]]; then
          die "Error: --param requires key=value format (got: $2)"
        fi
        extra_params["${2%%=*}"]="${2#*=}"
        shift 2
        ;;
      --raw|--verbose|-v|--help|-h) shift ;; # Ignore global flags
      -*) die "Unknown option for 'jql': $1" ;;
      *) query="$1"; shift ;;
    esac
  done

  [[ -z "${query}" ]] && die "Error: JQL query string is required."

  local jq_filter='{"jql": $jql, "maxResults": ($maxResults | tonumber)}'
  local -a jq_args=(--arg jql "${query}" --arg maxResults "${max_results}")
  
  local k
  for k in "${!extra_params[@]}"; do
    local v="${extra_params[$k]}"
    jq_args+=(--arg "$k" "$v")
    if [[ "$v" =~ ^[0-9]+$ ]]; then
        jq_filter="${jq_filter} + {(\$ARGS.named | keys_unsorted | map(select(. == \"$k\")) | .[]): (\$ARGS.named[\"$k\"] | tonumber)}"
    else
        jq_filter="${jq_filter} + {(\$ARGS.named | keys_unsorted | map(select(. == \"$k\")) | .[]): \$ARGS.named[\"$k\"]}"
    fi
  done

  local payload
  payload=$(jq -n "${jq_args[@]}" "$jq_filter")

  local response
  response=$(_call_api "POST" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/search/jql" "${payload}")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    echo "${response}" | jq '.'
  fi
}

cmd_issues() {
  local -a issue_ids=()
  local fields=""
  local expand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fields) fields="$2"; shift 2 ;;
      --expand) expand="$2"; shift 2 ;;
      --raw|--verbose|-v|--help|-h) shift ;; # Ignore global flags
      -*) die "Unknown option for 'issues': $1" ;;
      *) issue_ids+=("$1"); shift ;;
    esac
  done

  [[ ${#issue_ids[@]} -eq 0 ]] && die "Error: At least one issue ID/key is required."

  local payload
  payload=$(jq -n \
    --arg fields "${fields}" \
    --arg expand "${expand}" \
    '{"issueIdsOrKeys": $ARGS.positional}
     + (if $fields != "" then {"fields": ($fields | split(",") | map(select(length > 0)))} else {} end)
     + (if $expand != "" then {"expand": ($expand | split(",") | map(select(length > 0)))} else {} end)' \
    --args "${issue_ids[@]}")

  local response
  response=$(_call_api "POST" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/issue/bulkfetch" "${payload}")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    echo "${response}" | jq '.'
  fi
}

cmd_fields() {
  local filter=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw|--verbose|-v|--help|-h) shift ;;
      -*) die "Unknown option for 'fields': $1" ;;
      *) filter="$1"; shift ;;
    esac
  done

  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/field")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  elif [[ -n "${filter}" ]]; then
    echo "${response}" | jq --arg filter "${filter}" 'map(select(.name | test($filter; "i"))) | map({(.id): .name}) | add // {}'
  else
    echo "${response}" | jq 'map({(.id): .name}) | add'
  fi
}

cmd_statuses() {
  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/status")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    # Output map of ID -> {name, category}
    echo "${response}" | jq 'map({(.id): {name: .name, category: .statusCategory.name}}) | add'
  fi
}

cmd_types() {
  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/issuetype")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    echo "${response}" | jq 'map({(.id): {name: .name, subtask: .subtask}}) | add'
  fi
}

cmd_priorities() {
  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/priority")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    echo "${response}" | jq 'map({(.id): .name}) | add'
  fi
}

cmd_resolutions() {
  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/resolution")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    echo "${response}" | jq 'map({(.id): .name}) | add'
  fi
}

cmd_projects() {
  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/project")

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    echo "${response}"
  else
    echo "${response}" | jq 'map({(.key): .name}) | add'
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: df.jira <subcommand> [options]

Subcommands:
  jql                   Search for issues
  issues                Fetch details for specific issue(s)
  fields                List or search for Jira fields
  statuses              List Jira statuses and their categories
  types                 List available issue types
  priorities            List priority levels
  resolutions           List resolution types
  projects              List accessible projects

General Options:
  --url <url>           Jira workspace URL
  --user <email>        Jira user email
  --token <api-token>   Jira API token
  --raw                 Output raw response from API
  -v, --verbose         Show verbose request/response details
  -h, --help            Show this help

'jql' Options:
  <query>               JQL query string (positional, required)
  --max-results <int>   Maximum number of results (default: 50)
  --param <key=val>     Additional parameters to pass to the API

'issues' Options:
  <id/key>...           One or more issue IDs or keys (positional, required)
  --fields <list>       Comma-separated list of fields to include
  --expand <list>       Comma-separated list of expand options

'fields' Options:
  <filter>              Optional search pattern to filter fields by name

Authentication:
  Can be provided via flags or environment variables:
  JIRA_URL, JIRA_USER, JIRA_API_TOKEN (or JIRA_API_KEY)
EOF
  exit 1
}

main() {
  check_deps

  # Manual option parsing for Bash
  local -a args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url) JIRA_URL="$2"; shift 2 ;;
      --user) JIRA_USER="$2"; shift 2 ;;
      --token) JIRA_API_TOKEN="$2"; shift 2 ;;
      --raw) RAW_OUTPUT=1; shift ;;
      -v|--verbose) VERBOSE=1; shift ;;
      -h|--help) usage ;;
      --) shift; args+=("$@"); break ;;
      -*) die "Unknown option: $1" ;;
      *) break ;;
    esac
  done

  set -- "${args[@]}" "$@"

  local subcommand="${1:-}"
  [[ -z "${subcommand}" ]] && usage
  shift

  # Resolve secrets if not already in env
  resolve_secret "JIRA_URL"
  resolve_secret "JIRA_USER"
  resolve_secret "JIRA_API_TOKEN"

  # Final validation of mandatory credentials
  [[ -z "${JIRA_URL:-}" ]]   && die "Error: Jira URL is required (or set JIRA_URL)."
  [[ -z "${JIRA_USER:-}" ]]  && die "Error: Jira User is required (or set JIRA_USER)."
  [[ -z "${JIRA_API_TOKEN:-}" ]] && die "Error: Jira API Token is required (or set JIRA_API_TOKEN/JIRA_API_KEY)."

  if [[ ! "${JIRA_URL}" =~ ^https?:// ]]; then
    JIRA_URL="https://${JIRA_URL}"
  fi

  case "${subcommand}" in
    jql)         cmd_jql "$@" ;;
    issues)      cmd_issues "$@" ;;
    fields)      cmd_fields "$@" ;;
    statuses)    cmd_statuses "$@" ;;
    types)       cmd_types "$@" ;;
    priorities)  cmd_priorities "$@" ;;
    resolutions) cmd_resolutions "$@" ;;
    projects)    cmd_projects "$@" ;;
    *)           die "Unknown subcommand: ${subcommand}" ;;
  esac
}

main "$@"
