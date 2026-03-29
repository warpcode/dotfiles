##
# Universal Secret Manager
# Abstract wrapper for OS-level keychains (macOS Keychain, Linux Secret Service)
##

# Internal helper to execute platform-specific commands
_secret_exec() {
  local op=$1 svc=$2 acct=$3 val=$4
  if (( $+commands[security] )); then
    case $op in
      get) security find-generic-password -a "$acct" -s "$svc" -w 2>/dev/null ;;
      del) security delete-generic-password -a "$acct" -s "$svc" &>/dev/null ;;
      set) security delete-generic-password -a "$acct" -s "$svc" &>/dev/null
           security add-generic-password -a "$acct" -s "$svc" -w "$val" -U &>/dev/null ;;
    esac
  elif (( $+commands[secret-tool] )); then
    case $op in
      get) secret-tool lookup service "$svc" account "$acct" 2>/dev/null ;;
      del) secret-tool clear service "$svc" account "$acct" &>/dev/null ;;
      set) printf '%s' "$val" | secret-tool store --label="Dotfiles: $svc" service "$svc" account "$acct" ;;
    esac
  else
    return 127 # Command not found
  fi
}

secret.get() {
  local svc=$1 acct=${2:-$USER}
  [[ -z $svc ]] && { echo "Usage: secret.get <service> [account]" >&2; return 1 }
  _secret_exec get "$svc" "$acct"
}

secret.store() {
  local svc=$1 pass=$2 acct=${3:-$USER}
  [[ -z $svc || -z $pass ]] && { echo "Usage: secret.store <service> <password> [account]" >&2; return 1 }

  if [[ $pass == "-" ]]; then
    read -rs "pass?Enter password for '$svc' ($acct): "; echo >&2
    [[ -z $pass ]] && return 1
  fi

  _secret_exec set "$svc" "$acct" "$pass" || { echo "Error: No OS keychain tool found." >&2; return 1 }
  echo "Saved to $( (( $+commands[security] )) && echo "macOS Keychain" || echo "Secret Service" )." >&2
}

secret.delete() {
  local svc=$1 acct=${2:-$USER}
  [[ -z $svc ]] && { echo "Usage: secret.delete <service> [account]" >&2; return 1 }

  _secret_exec del "$svc" "$acct" && \
    echo "Removed from $( (( $+commands[security] )) && echo "macOS Keychain" || echo "Secret Service" )." >&2
}
