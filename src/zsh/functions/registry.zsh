# Generic Registry Abstraction Library — Zsh 5.8+
# Namespace-scoped registries: define, query, dispatch, aggregate.

# --- Internal Helpers ---

_registry.ns_var() {
    printf '%s_%s_%s' "registry" "$1" "$2"
}

_registry.norm() {
    print -r -- "${1//-/_}"
}

_registry.validate_name() {
    [[ "$1" == "registry" ]] && { print "Invalid namespace: 'registry' is reserved" >&2; return 1; }
    [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { print "Invalid namespace: $1" >&2; return 1; }
}

_registry.validate_exists() {
    _registry.validate_name "$1" || return 1
    local list_var="$(_registry.ns_var "$1" "list")"
    typeset -p "$list_var" >/dev/null 2>&1 || { print "Unknown namespace: $1" >&2; return 1; }
}

# Read associative array value: _registry.aa_get <varname> <key>
_registry.aa_get() {
    local ref="${1}[${2}]"
    print -r -- "${(P)ref}"
}

# Write associative array value: _registry.aa_set <varname> <key> <value>
_registry.aa_set() {
    eval "${1}[${2}]=${(q)3}"
}

# Read array elements: _registry.arr_get <varname> → prints elements one per line
_registry.arr_get() {
    local ref="${1}[@]"
    local -a elems
    elems=("${(P@)ref}")
    local e
    for e in "${elems[@]}"; do
        print -r -- "$e"
    done
}

# --- Core API ---

# registry.define <namespace> <id> <key>=<value> ...
registry.define() {
    local ns="$1" id; id="$(_registry.norm "$2")"; shift 2
    _registry.validate_name "$ns" || return 1

    local data_var exists_var list_var
    data_var="$(_registry.ns_var "$ns" "data")"
    exists_var="$(_registry.ns_var "$ns" "exists")"
    list_var="$(_registry.ns_var "$ns" "list")"

    # Ensure arrays exist
    typeset -gA "$data_var" "$exists_var"
    typeset -ga "$list_var"

    local add_to_list=1
    local exists_ref="${exists_var}[${id}]"
    [[ -n "${(P)exists_ref}" ]] && add_to_list=0

    local pair k v
    for pair in "$@"; do
        [[ "$pair" == *=* ]] || continue
        k="${pair%%=*}" v="${pair#*=}"
        _registry.aa_set "$data_var" "${id}:${k}" "$v"
    done

    _registry.aa_set "$exists_var" "$id" "1"

    if (( add_to_list )); then
        eval "${list_var}+=(\"\${id}\")"
    fi
}

# registry.exists <namespace> <id>
registry.exists() {
    _registry.validate_exists "$1" || return 1
    local id; id="$(_registry.norm "$2")"
    local exists_var="$(_registry.ns_var "$1" "exists")"
    local exists_ref="${exists_var}[${id}]"
    [[ -n "${(P)exists_ref}" ]]
}

# registry.list <namespace>
registry.list() {
    _registry.validate_exists "$1" || return 1
    _registry.arr_get "$(_registry.ns_var "$1" "list")"
}

# registry.get <namespace> <id> <key>
registry.get() {
    _registry.validate_exists "$1" || return 1
    local id; id="$(_registry.norm "$2")"
    local data_var
    data_var="$(_registry.ns_var "$1" "data")"
    _registry.aa_get "$data_var" "${id}:${3}"
}

# registry.is_enabled <namespace> <id> <func_prefix>
registry.is_enabled() {
    _registry.validate_exists "$1" || return 1
    local id; id="$(_registry.norm "$2")"
    local fn="$3.$id.enabled"
    if (( $+functions[$fn] )); then
        "$fn"
        return $?
    fi
    return 0
}

_registry.dispatch() {
    local ns="$1" prefix="$2" method="$3" mode="$4"; shift 4
    _registry.validate_exists "$ns" || return 1

    local -a ids
    ids=($(_registry.arr_get "$(_registry.ns_var "$ns" "list")"))

    local id fn out rc
    local filter_enabled=0
    [[ "$mode" == *_enabled ]] && filter_enabled=1

    for id in "${ids[@]}"; do
        if (( filter_enabled )); then
            registry.is_enabled "$ns" "$id" "$prefix" || continue
        fi

        fn="$prefix.$id.$method"
        if (( $+functions[$fn] )); then
            case "$mode" in
                call*)
                    "$fn" "$@"; rc=$?
                    (( rc != 0 )) && return "$rc"
                    ;;
                collect*)
                    out="$("$fn" "$@")"; rc=$?
                    (( rc != 0 )) && return "$rc"
                    print -r -- "$out"
                    ;;
                all_true)
                    "$fn" "$@" >/dev/null 2>&1 || return 1
                    ;;
                all_false)
                    "$fn" "$@" >/dev/null 2>&1 && return 1
                    ;;
                any_true)
                    "$fn" "$@" >/dev/null 2>&1 && return 0
                    ;;
                any_false)
                    "$fn" "$@" >/dev/null 2>&1 || return 0
                    ;;
                list_enabled)
                    print -r -- "$id"
                    ;;
            esac
        else
            case "$mode" in
                all_true|all_false|call*|collect*) return 1 ;;
            esac
        fi
    done

    case "$mode" in
        any_true|any_false) return 1 ;;
        *) return 0 ;;
    esac
}

# registry.enabled <namespace> <func_prefix>
registry.enabled() {
    _registry.dispatch "$1" "$2" "enabled" "list_enabled"
}

# registry.call_all <namespace> <func_prefix> <method> [args...]
registry.call_all() {
    _registry.dispatch "$@" "call"
}

# registry.call_enabled <namespace> <func_prefix> <method> [args...]
registry.call_enabled() {
    _registry.dispatch "$@" "call_enabled"
}

# registry.collect <namespace> <func_prefix> <method> [args...]
registry.collect() {
    _registry.dispatch "$@" "collect"
}

# registry.collect_enabled <namespace> <func_prefix> <method> [args...]
registry.collect_enabled() {
    _registry.dispatch "$@" "collect_enabled"
}

# registry.collect_parallel <namespace> <func_prefix> <method> [args...]
registry.collect_parallel() {
    local ns="$1" func_prefix="$2" method="$3"; shift 3
    _registry.validate_exists "$ns" || return 1
    local -a ids
    ids=($(_registry.arr_get "$(_registry.ns_var "$ns" "list")"))

    [[ -o monitor ]] && local restore_monitor=1 && unsetopt monitor

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local id
    for id in "${ids[@]}"; do
        (
            local fn="$func_prefix.$id.$method"
            if (( $+functions[$fn] )); then
                "$fn" "$@" > "$tmp_dir/$id.out" 2>/dev/null
            else
                : > "$tmp_dir/$id.out"
            fi
            ) &
        done
        wait

        [[ -n "$restore_monitor" ]] && setopt monitor

        for id in "${ids[@]}"; do
            [[ -f "$tmp_dir/$id.out" ]] && cat "$tmp_dir/$id.out"
        done
        rm -rf "$tmp_dir"
    }

# registry.all_true <namespace> <func_prefix> <method> [args...]
registry.all_true() {
    _registry.dispatch "$@" "all_true"
}

# registry.all_false <namespace> <func_prefix> <method> [args...]
registry.all_false() {
    _registry.dispatch "$@" "all_false"
}

# registry.any_true <namespace> <func_prefix> <method> [args...]
registry.any_true() {
    _registry.dispatch "$@" "any_true"
}

# registry.any_false <namespace> <func_prefix> <method> [args...]
registry.any_false() {
    _registry.dispatch "$@" "any_false"
}
