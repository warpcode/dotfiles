# secrets.zsh - Universal Secret Manager

_secrets_exec() {
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
      set) print -nr "$val" | secret-tool store --label="Dotfiles: $svc" service "$svc" account "$acct" ;;
    esac
  else
    return 127
  fi
}

secrets.get() {
  local svc=$1 acct=${2:-$USER}
  [[ -z $svc ]] && return 1
  _secrets_exec get "$svc" "$acct"
}

secrets.store() {
  local svc=$1 pass=$2 acct=${3:-$USER}
  [[ -z $svc || -z $pass ]] && return 1

  if [[ $pass == "-" ]]; then
    read -rs "pass?Enter password for '$svc' ($acct): "; echo >&2
    [[ -z $pass ]] && return 1
  fi

  _secrets_exec set "$svc" "$acct" "$pass" || return 1
  print -P "    %F{green}✅ Saved to OS keychain.%f" >&2
}

secrets.delete() {
  local svc=$1 acct=${2:-$USER}
  [[ -z $svc ]] && return 1
  _secrets_exec del "$svc" "$acct" && print -P "    %F{yellow}🗑️ Removed from OS keychain.%f" >&2
}
