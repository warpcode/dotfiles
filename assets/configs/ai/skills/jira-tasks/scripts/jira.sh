#!/bin/bash
#
# df.jira - Generic Jira REST API wrapper for searches and metadata.
#
# This script provides a command-line interface to the Jira REST API v3,
# supporting JQL searches, issue details, and metadata retrieval.
#
# Usage: df.jira <subcommand> [options]

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

readonly JIRA_API_VERSION="3"

# Shared JQ filter for processing issue lists (JQL results or Bulk Fetch)
# Expects --arg expand "..." and --argjson full_issue true|false
ISSUE_PROCESSOR_JQ=$(cat <<'EOF'
  # Recursive function to handle nested ADF content
  def flatten_adf:
    if . == null then ""
    elif type == "array" then map(flatten_adf) | join("")
    elif .type == "text" then .text
    elif .type == "hardBreak" then "\n"
    elif .type == "inlineCard" then .attrs.url
    elif .type == "mention" then .attrs.text
    elif .type | IN("paragraph", "heading", "listItem", "tableCell") then
      (.content | flatten_adf) + "\n"
    elif .content then
      .content | flatten_adf
    else ""
    end;

  ($expand | split(",") | map(select(length > 0))) as $requested_expands |

  def process_issue:
    {
        id: .id,
        key: .key,
        parent: .fields.parent.key,
        type: .fields.issuetype.name,
        summary: .fields.summary,
        description: (.fields.description | flatten_adf | sub("\n$"; "")),
        comment: {
            total: .fields.comment.total,
            comments: [.fields.comment.comments[]? | {
                author: .author.displayName,
                created: .created,
                updated: .updated,
                body: (.body | flatten_adf | sub("\n$"; ""))
            }]
        },
        assignee: (.fields.assignee.displayName // "Unassigned"),
        status: .fields.status.name,
        priority: .fields.priority.name,
        labels: .fields.labels,
        components: [.fields.components[]? | .name],
        created: .fields.created,
        updated: .fields.updated
    }
    # Include any issue-level expands (like changelog, transitions) if present
    + (with_entries(
        select(.key | IN($requested_expands[]))
        | if .key == "changelog" then
            .value = {
                histories: [.value.histories[]? | {
                    id: .id,
                    author: .author.displayName,
                    author_id: .author.accountId,
                    created: .created,
                    items: [.items[]? | {
                        field: .field,
                        fieldId: .fieldId,
                        from: .from,
                        fromString: .fromString,
                        to: .to,
                        toString: .toString
                    }]
                }]
            }
          elif .key == "transitions" then
            .value = [.value[]? | {
                transitionId: .id,
                transitionname: .name,
                statusId: .to.id,
                statusName: .to.name,
                hasScreen: .hasScreen,
                isGlobal: .isGlobal,
                isInitial: .isInitial,
                isAvailable: .isAvailable,
                isConditional: .isConditional,
                isLooped: .isLooped
            }]
          else . end
      ))
    + (if $full_issue == 1 then {original: .} else {} end);

  # Root object processing
  {
    isLast: (if .isLast == null then true else .isLast end),
    resultsOnPage: (.issues | length // 0),
    nextPageToken: .nextPageToken
  }
  # Include any top-level expands (like names, schema) if present in source
  + (with_entries(select(.key | IN($requested_expands[]))))
  + { issues: ([.issues[]? | process_issue]) }
EOF
)
readonly ISSUE_PROCESSOR_JQ

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

JIRA_URL="${JIRA_URL:-}"
JIRA_USER="${JIRA_USER:-}"
JIRA_API_TOKEN="${JIRA_API_TOKEN:-${JIRA_API_KEY:-}}"
JIRA_PROJECT="${JIRA_PROJECT:-}"
VERBOSE="${VERBOSE:-0}"
RAW_OUTPUT="${RAW_OUTPUT:-0}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

#######################################
# Print error message to stderr.
# Arguments:
#   $* - Error message string.
# Outputs:
#   Writes formatted error message to stderr.
# Returns:
#   None.
#######################################
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] jira.sh: $*" >&2
}

#######################################
# Print error message and exit.
# Arguments:
#   $* - Error message string.
# Outputs:
#   Writes error message to stderr.
# Returns:
#   Exits with status 1.
#######################################
die() {
  err "$*"
  exit 1
}

#######################################
# Resolve a secret using DF_SECRET_GET_CMD if not already set.
# Globals:
#   DF_SECRET_GET_CMD - Read. The command used to retrieve secrets.
#   JIRA_URL - Modified. Resolved workspace URL.
#   JIRA_USER - Modified. Resolved user email.
#   JIRA_API_TOKEN - Modified. Resolved API token.
#   JIRA_PROJECT - Modified. Resolved project key.
#   JIRA_API_KEY - Read. Checked as fallback for token.
# Arguments:
#   $1 - Variable name to resolve (e.g., JIRA_URL).
# Outputs:
#   None.
# Returns:
#   0 on success, 1 if secret cannot be resolved.
#######################################
resolve_secret() {
  local name="${1}"

  # 1. Early return if already set in environment
  [[ -n "${!name:-}" ]] && return 0

  # 2. Special case for token: check JIRA_API_KEY if name is JIRA_API_TOKEN
  if [[ "${name}" == "JIRA_API_TOKEN" && -n "${JIRA_API_KEY:-}" ]]; then
    export JIRA_API_TOKEN="${JIRA_API_KEY}"
    return 0
  fi

  # 3. Guard: resolver command must be defined
  if [[ -z "${DF_SECRET_GET_CMD:-}" ]]; then
    err "Error: ${name} is missing and DF_SECRET_GET_CMD is undefined."
    return 1
  fi

  # 4. Resolve and export
  local value
  value=$(${DF_SECRET_GET_CMD} "${name}")

  # 5. Fallback for token if requested name failed
  if [[ -z "${value}" && "${name}" == "JIRA_API_TOKEN" ]]; then
    value=$(${DF_SECRET_GET_CMD} "JIRA_API_KEY")
  fi

  if [[ -z "${value}" ]]; then
    return 1
  fi

  export "${name}"="${value}"
}

#######################################
# Verify required dependencies are installed.
# Arguments:
#   None
# Outputs:
#   None.
# Returns:
#   None (dies if dependency missing).
#######################################
check_deps() {
  local dep
  for dep in curl jq base64; do
    command -v "${dep}" >/dev/null || die "Error: '${dep}' is required but not found."
  done
}

#######################################
# Unified output processor for API responses.
# Globals:
#   RAW_OUTPUT - Whether to skip JQ filtering.
# Arguments:
#   $1 - API JSON response string.
#   $2 - JQ filter string.
#   $@ - Additional JQ arguments.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on JQ failure.
#######################################
_process_output() {
  local response="${1}"
  local jq_filter="${2}"
  shift 2

  if [[ "${RAW_OUTPUT}" -eq 1 ]]; then
    printf '%s\n' "${response}"
  else
    printf '%s\n' "${response}" | jq "$@" "${jq_filter}"
  fi
}

#######################################
# Internal helper to call the Jira REST API.
# Globals:
#   JIRA_USER
#   JIRA_API_TOKEN
#   VERBOSE
# Arguments:
#   $1 - HTTP method (GET, POST, etc.)
#   $2 - Absolute endpoint URL.
#   $3 - Optional JSON payload.
#   $@ - Additional curl options.
# Outputs:
#   Writes API response to stdout.
# Returns:
#   API response string.
#######################################
_call_api() {
  local method="${1}"
  local endpoint="${2}"
  local payload="${3:-}"
  shift 3

  local auth_header
  auth_header="Basic $(printf '%s:%s' "${JIRA_USER}" "${JIRA_API_TOKEN}" | base64 | tr -d '\n')"

  local -a curl_opts=(
    -s
    -w "%{http_code}"
    -X "${method}"
    -H "Authorization: ${auth_header}"
    -H "Content-Type: application/json"
    -H "Accept: application/json"
    "$@"
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
  trap 'rm -f "${response_file}"' EXIT

  local http_code
  http_code=$(curl "${curl_opts[@]}" -o "${response_file}" "${endpoint}")
  local response
  response=$(<"${response_file}")
  rm -f "${response_file}"
  trap - EXIT

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

#######################################
# Search for issues using JQL.
# Arguments:
#   <query> - JQL query string.
#   --max-results <int> - Max results.
#   --fields <list> - Fields to include.
#   --expand <list> - Expand options.
#   --full-issue - Include original JSON.
#   --param <k=v> - Extra API params.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_jql() {
  local query=""
  local max_results=50
  local fields=""
  local expand=""
  local full_issue=0
  declare -A extra_params

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --max-results) max_results="${2}"; shift 2 ;;
      --fields) fields="${2}"; shift 2 ;;
      --expand) expand="${2}"; shift 2 ;;
      --full-issue) full_issue=1; shift ;;
      --param)
        if [[ "$2" != *=* ]]; then
          die "Error: --param requires key=value format (got: ${2})"
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

  # Mandatory fields always included
  local -r mandatory_fields="parent,summary,description,status,assignee,issuetype,comment,created,updated,priority,labels,components"
  if [[ -n "${fields}" ]]; then
    fields="${mandatory_fields},${fields}"
  else
    fields="${mandatory_fields}"
  fi

  local -a jq_args=()
  local k
  for k in "${!extra_params[@]}"; do
    jq_args+=(--arg "${k}" "${extra_params[$k]}")
  done

  local jq_filter
  jq_filter=$(cat <<'EOF'
    ($ARGS.named | del(.jql_query, .max_results, .field_list, .expand_list)
     | map_values(if type == "string" and test("^[0-9]+$") then tonumber else . end)) as $extras |
    ({
      "jql": $jql_query,
      "maxResults": ($max_results | tonumber),
      "fields": ($field_list | split(",") | map(select(length > 0)) | unique)
    }
    + (if $expand_list != "" then {"expand": ($expand_list | split(",") | map(select(length > 0)) | join(","))} else {} end)
    + $extras)
    | del(.jql_query, .max_results, .field_list, .expand_list)
EOF
)

  local payload
  payload=$(jq -n \
    --arg jql_query "${query}" \
    --arg max_results "${max_results}" \
    --arg field_list "${fields}" \
    --arg expand_list "${expand}" \
    "${jq_args[@]}" \
    "${jq_filter}")

  local response
  response=$(_call_api "POST" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/search/jql" "${payload}")

  _process_output "${response}" "${ISSUE_PROCESSOR_JQ}" \
    --argjson full_issue "${full_issue}" \
    --arg expand "${expand}"
}

#######################################
# Fetch details for specific issue(s).
# Arguments:
#   <id/key>... - Issue IDs or keys.
#   --fields <list> - Fields to include.
#   --expand <list> - Expand options.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_issues() {
  local -a issue_ids=()
  local fields=""
  local expand=""
  local full_issue=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fields) fields="${2}"; shift 2 ;;
      --expand) expand="${2}"; shift 2 ;;
      --full-issue) full_issue=1; shift ;;
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

  _process_output "${response}" "${ISSUE_PROCESSOR_JQ}" \
    --argjson full_issue "${full_issue}" \
    --arg expand "${expand}"
}

#######################################
# Internal helper for simple metadata subcommands.
# Arguments:
#   $1 - Jira API endpoint path.
#   $2 - JQ filter for transformation.
#   $@ - Additional JQ arguments.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
_cmd_metadata() {
  local endpoint="${1}"
  local jq_filter="${2}"
  shift 2

  local response
  response=$(_call_api "GET" "${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/${endpoint}")

  _process_output "${response}" "${jq_filter}" "$@"
}

#######################################
# List or search for Jira fields.
# Arguments:
#   $1 - Optional filter string.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_fields() {
  local filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw|--verbose|-v|--help|-h) shift ;;
      -*) die "Unknown option for 'fields': $1" ;;
      *) filter="$1"; shift ;;
    esac
  done

  local jq_filter='map({(.id): .name}) | add'
  local -a jq_args=()

  if [[ -n "${filter}" ]]; then
    jq_filter='map(select(.name | test($filter; "i"))) | map({(.id): .name}) | add // {}'
    jq_args+=(--arg filter "${filter}")
  fi

  _cmd_metadata "field" "${jq_filter}" "${jq_args[@]}"
}

#######################################
# List Jira statuses and their categories.
# Arguments:
#   --category <name> - Filter by category.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_statuses() {
  local category=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --category|--params) category="${2}"; shift 2 ;;
      --raw|--verbose|-v|--help|-h) shift ;;
      *) die "Unknown option for 'statuses': $1" ;;
    esac
  done

  local endpoint="status"
  local jq_filter="map({(.id): {name: .name, category: .statusCategory.name}}) | add"

  if [[ -n "${JIRA_PROJECT:-}" ]]; then
    endpoint="project/${JIRA_PROJECT}/statuses"
    jq_filter="map(.statuses[]) | unique_by(.id) | map({(.id): {name: .name, category: .statusCategory.name}}) | add"
  fi

  local -a jq_args=()
  if [[ -n "${category}" ]]; then
    jq_filter="${jq_filter} | with_entries(select((.value.category | ascii_downcase | gsub(\" \"; \"-\")) == \$cat))"
    jq_args+=(--arg cat "${category}")
  fi

  _cmd_metadata "${endpoint}" "${jq_filter}" "${jq_args[@]}"
}

#######################################
# List available issue types.
# Arguments:
#   None.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_types() {
  _cmd_metadata "issuetype" "map({(.id): {name: .name, subtask: .subtask}}) | add"
}

#######################################
# List priority levels.
# Arguments:
#   None.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_priorities() {
  _cmd_metadata "priority" "map({(.id): .name}) | add"
}

#######################################
# List resolution types.
# Arguments:
#   None.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_resolutions() {
  _cmd_metadata "resolution" "map({(.id): .name}) | add"
}

#######################################
# Search for Jira users.
# Arguments:
#   <query> - Search string for display name or email.
#   --exact - Perform an exact match.
#   --expand <fields> - Fields to expand.
#   --full - Display the full user object.
#   --max-results <int> - Max results.
#   --project <key> - Project key for assignable search.
# Outputs:
#   Writes processed JSON to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_users() {
  local query=""
  local max_results=50
  local project="${JIRA_PROJECT:-}"
  local expand=""
  local full=0
  local exact=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --max-results) max_results="${2}"; shift 2 ;;
      --project) project="${2}"; shift 2 ;;
      --expand) expand="${2}"; shift 2 ;;
      --full) full=1; shift ;;
      --exact) exact=1; shift ;;
      --raw|--verbose|-v|--help|-h) shift ;;
      -*) die "Unknown option for 'users': $1" ;;
      *) query="$1"; shift ;;
    esac
  done

  local endpoint="user/search"
  [[ -n "${project}" ]] && endpoint="user/assignable/search"
  local url="${JIRA_URL%/}/rest/api/${JIRA_API_VERSION}/${endpoint}"

  local -a curl_args=(--get)
  curl_args+=(--data-urlencode "maxResults=${max_results}")
  [[ -n "${query}" ]] && curl_args+=(--data-urlencode "query=${query}")
  [[ -n "${project}" ]] && curl_args+=(--data-urlencode "project=${project}")
  [[ -n "${expand}" ]] && curl_args+=(--data-urlencode "expand=${expand}")

  local response
  response=$(_call_api "GET" "${url}" "" "${curl_args[@]}")

  local jq_filter
  jq_filter=$(cat <<'EOF'
    (if $exact == 1 and $query != "" then
      map(select(.displayName == $query or .emailAddress == $query))
     else . end)
    | if $full == 1 then .
      else map({(.accountId): .displayName}) | add // {}
      end
EOF
)

  _process_output "${response}" "${jq_filter}" \
    --argjson exact "${exact}" \
    --arg query "${query}" \
    --argjson full "${full}"
}

#######################################
# Direct API call (advanced).
# Arguments:
#   $1 - HTTP method (GET, POST, PUT, DELETE).
#   $2 - Relative or absolute API endpoint.
#   $3 - Optional JSON payload string.
# Outputs:
#   Writes API response to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
cmd_call() {
  local method="${1:-}"
  local endpoint="${2:-}"
  local payload="${3:-}"

  [[ -z "${method}" || -z "${endpoint}" ]] && die "Usage: df.jira call <METHOD> <ENDPOINT> [PAYLOAD]"

  # If endpoint is relative, prepend JIRA_URL
  if [[ ! "${endpoint}" =~ ^https?:// ]]; then
    endpoint="${JIRA_URL%/}/${endpoint#/}"
  fi

  local response
  response=$(_call_api "${method}" "${endpoint}" "${payload}")
  printf '%s\n' "${response}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Print usage information and exit.
# Arguments:
#   None.
# Outputs:
#   Writes usage help to stdout.
# Returns:
#   Exits with status 1.
#######################################
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
  users                 Search for Jira users
  call                  Direct API call (advanced)

General Options:
  --url <url>           Jira workspace URL
  --user <email>        Jira user email
  --token <api-token>   Jira API token
  --project <key>       Jira project key (Required)
  --raw                 Output raw response from API
  -v, --verbose         Show verbose request/response details
  -h, --help            Show this help

'jql' Options:
  <query>               JQL query string (positional, required)
  --max-results <int>   Maximum number of results (default: 50)
  --fields <list>       Comma-separated list of fields to include
  --expand <list>       Comma-separated list of expand options
  --full-issue          Include original issue JSON in output
  --param <key=val>     Additional parameters to pass to the API

'issues' Options:
  <id/key>...           One or more issue IDs or keys (positional, required)
  --fields <list>       Comma-separated list of fields to include
  --expand <list>       Comma-separated list of expand options

'fields' Options:
  <filter>              Optional search pattern to filter fields by name

'statuses' Options:
  --category <name>     Filter by category (e.g., in-progress, to-do, done)

'users' Options:
  <query>               Optional search string for display name or email
  --exact               Perform an exact match on display name or email
  --expand <fields>     Comma-separated list of fields to expand
  --full                Display the full user object (JSON array)
  --max-results <int>   Maximum number of results (default: 50)

'call' Options:
  <method>              HTTP method (GET, POST, PUT, DELETE)
  <endpoint>            Relative or absolute API endpoint
  <payload>             Optional JSON payload string

Authentication:
  Can be provided via flags or environment variables:
  JIRA_URL, JIRA_USER, JIRA_API_TOKEN (or JIRA_API_KEY), JIRA_PROJECT
EOF
  exit 1
}

#######################################
# Entry point for the script.
# Arguments:
#   $@ - All script arguments.
# Outputs:
#   Executes subcommands which may write to stdout.
# Returns:
#   0 on success, non-zero on error.
#######################################
main() {
  check_deps

  # Manual option parsing for Bash
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url) JIRA_URL="${2}"; shift 2 ;;
      --user) JIRA_USER="${2}"; shift 2 ;;
      --token) JIRA_API_TOKEN="${2}"; shift 2 ;;
      --project) JIRA_PROJECT="${2}"; shift 2 ;;
      --raw) RAW_OUTPUT=1; shift ;;
      -v|--verbose) VERBOSE=1; shift ;;
      -h|--help) usage ;;
      --) shift; break ;;
      -*) die "Unknown option: $1" ;;
      *) break ;;
    esac
  done

  local subcommand="${1:-}"
  [[ -z "${subcommand}" ]] && usage
  shift

  # Resolve secrets if not already in env
  resolve_secret "JIRA_URL" || die "Error: Failed to resolve JIRA_URL."
  resolve_secret "JIRA_USER" || die "Error: Failed to resolve JIRA_USER."
  resolve_secret "JIRA_API_TOKEN" || die "Error: Failed to resolve JIRA_API_TOKEN."
  resolve_secret "JIRA_PROJECT" || die "Error: Failed to resolve JIRA_PROJECT."

  # Final validation of mandatory credentials
  [[ -z "${JIRA_URL:-}" ]]      && die "Error: Jira URL is required (or set JIRA_URL)."
  [[ -z "${JIRA_USER:-}" ]]     && die "Error: Jira User is required (or set JIRA_USER)."
  [[ -z "${JIRA_API_TOKEN:-}" ]] && die "Error: Jira API Token is required (or set JIRA_API_TOKEN/JIRA_API_KEY)."
  [[ -z "${JIRA_PROJECT:-}" ]]  && die "Error: Jira Project key is required (or set JIRA_PROJECT)."

  if [[ ! "${JIRA_URL}" =~ ^https?:// ]]; then
    JIRA_URL="https://${JIRA_URL}"
  fi

  if [[ "$(type -t "cmd_${subcommand}")" == "function" ]]; then
    "cmd_${subcommand}" "$@"
  else
    die "Unknown subcommand: ${subcommand}"
  fi
}

main "$@"
