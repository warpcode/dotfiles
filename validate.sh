#!/usr/bin/env bash
#
# Local mirror of CI validation for this repository.
#
# CI splits across three workflows:
#   lint.yml         -> zsh -n over *.zsh, plus dot_zsh/tests/*.zsh suites
#   python-tests.yml -> unittest discovery under .github/skills/*/scripts and tests/
#   (shellcheck)     -> declared in AGENTS.md, not yet a workflow
#
# This script runs the checks locally so a "tests pass" claim is verifiable
# before opening a PR, without hand-assembling five commands each time.
#
# Usage:
#   ./validate.sh              # everything (lint + compile + tests)
#   ./validate.sh --fast       # skip the test suites (lint + compile only)
#   ./validate.sh --lint-only  # shell/zsh syntax + shellcheck only
#   ./validate.sh --json       # machine-readable summary on the final line
#
# Exit codes:
#   0  all selected checks passed
#   1  one or more checks failed
#   2  bad usage

set -uo pipefail

FAST=0
LINT_ONLY=0
JSON=0

usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

for arg in "$@"; do
    case "$arg" in
        --fast) FAST=1 ;;
        --lint-only) LINT_ONLY=1 ;;
        --json) JSON=1 ;;
        -h | --help) usage 0 ;;
        *)
            printf 'validate: unknown argument: %s\n' "$arg" >&2
            usage 2
            ;;
    esac
done

FAILED=()
PASSED=()

# ---------------------------------------------------------------------------
# Check runner
# ---------------------------------------------------------------------------

# run <name> <command...>
# Records the check and its exit status; never aborts, so one failure does
# not hide the rest of the report.
run() {
    local name="$1"
    shift
    printf '\n=== %s ===\n' "$name"
    if "$@"; then
        PASSED+=("$name")
        printf 'PASS %s\n' "$name"
    else
        FAILED+=("$name")
        printf 'FAIL %s\n' "$name" >&2
    fi
}

have() {
    command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Shell / Zsh syntax (mirrors lint.yml)
# ---------------------------------------------------------------------------

lint_zsh() {
    local failed=0
    while IFS= read -r f; do
        if ! zsh -n "$f"; then
            failed=1
        fi
    done < <(find . -name '*.zsh' -not -path './.git/*')
    return $failed
}

lint_bash() {
    local failed=0
    while IFS= read -r f; do
        if ! bash -n "$f"; then
            failed=1
        fi
    done < <(find . -name '*.sh' -not -path './.git/*')
    return $failed
}

run "zsh -n (syntax)" lint_zsh
run "bash -n (syntax)" lint_bash

# ---------------------------------------------------------------------------
# Zsh unit tests (mirrors the lint.yml runner step)
# ---------------------------------------------------------------------------

if [ "$LINT_ONLY" -eq 0 ]; then
    run_zsh_tests() {
        [ -d dot_zsh/tests ] || {
            printf 'dot_zsh/tests/ not found\n' >&2
            return 1
        }
        local failed=0 ran=0
        for suite in dot_zsh/tests/*.zsh; do
            [ -f "$suite" ] || continue
            ran=$((ran + 1))
            printf -- '--- %s\n' "$suite"
            if ! zsh "$suite"; then
                failed=1
            fi
        done
        if [ "$ran" -eq 0 ]; then
            printf 'no zsh test suites found\n' >&2
            return 1
        fi
        return $failed
    }
    run "zsh tests (dot_zsh/tests)" run_zsh_tests
fi

# ---------------------------------------------------------------------------
# Static analysis, declared in AGENTS.md but with no workflow running it yet.
# ---------------------------------------------------------------------------

if have shellcheck; then
    # ShellCheck supports sh/bash/dash/ksh only -- feeding it *.zsh yields
    # SC1071, not real findings. Zsh is covered by the `zsh -n` check above.
    shellcheck_all() {
        local failed=0
        # shellcheck disable=SC2046
        shellcheck --severity=warning --external-sources $(git ls-files '*.sh') ||
            failed=1
        return $failed
    }
    run "shellcheck" shellcheck_all
else
    printf '\nSKIP shellcheck (not installed)\n'
fi

# ---------------------------------------------------------------------------
# Python compile (all tracked Python, not just skills/)
# ---------------------------------------------------------------------------

compile_python() {
    python3 -m compileall -q .github/skills tests dot_agents
}

run "py_compile" compile_python

# ---------------------------------------------------------------------------
# Python unit tests (mirrors python-tests.yml discovery)
# ---------------------------------------------------------------------------

if [ "$FAST" -eq 1 ]; then
    printf '\nSKIP unittest (--fast)\n'
elif [ "$LINT_ONLY" -eq 1 ]; then
    printf '\nSKIP unittest (--lint-only)\n'
else
    # Suites already red on master, for reasons unrelated to any change under
    # review. Mirrors python-tests.yml: remove a name only once it is green on
    # master -- do not use this list to hide a new failure.
    skip_root_suites="test_ai_guard test_software_hooks"

    run_python_tests() {
        local failed=0

        for scripts_dir in .github/skills/*/scripts; do
            [ -d "$scripts_dir" ] || continue
            local skill
            skill="$(basename "$(dirname "$scripts_dir")")"

            # Suites use both layouts. Discovery must run from inside scripts/ --
            # most have no tests/__init__.py, so passing -t makes unittest fail
            # with "Start directory is not importable".
            if [ -d "$scripts_dir/tests" ]; then
                printf -- '--- %s tests/\n' "$skill"
                if [ -f "$scripts_dir/pyproject.toml" ]; then
                    (cd "$scripts_dir" && PYTHONPATH=. uv run --locked python -m unittest discover -s tests) ||
                        failed=1
                else
                    (cd "$scripts_dir" && PYTHONPATH=. python3 -m unittest discover -s tests) ||
                        failed=1
                fi
            fi

            for test_file in "$scripts_dir"/test_*.py; do
                [ -e "$test_file" ] || continue
                printf -- '--- %s %s\n' "$skill" "$(basename "$test_file")"
                if [ -f "$scripts_dir/pyproject.toml" ]; then
                    (cd "$scripts_dir" && PYTHONPATH=. uv run --locked python3 -m unittest "$(basename "$test_file" .py)") ||
                        failed=1
                else
                    (cd "$scripts_dir" && PYTHONPATH=. python3 -m unittest "$(basename "$test_file" .py)") ||
                        failed=1
                fi
            done
        done

        # Repo-root tests/ is a flat set of modules with no __init__.py, so it
        # is invoked as tests.<module>.
        for test_file in tests/test_*.py; do
            [ -e "$test_file" ] || continue
            local module
            module="$(basename "$test_file" .py)"
            case " $skip_root_suites " in
                *" $module "*)
                    printf -- '--- tests/%s SKIPPED (pre-existing failures on master)\n' "$module"
                    continue
                    ;;
            esac
            printf -- '--- tests/%s\n' "$module"
            PYTHONPATH=. python3 -m unittest "tests.$module" || failed=1
        done

        return $failed
    }

    run "unittest" run_python_tests
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n=== summary ===\n'
for name in "${PASSED[@]:-}"; do
    [ -n "$name" ] && printf 'PASS %s\n' "$name"
done
for name in "${FAILED[@]:-}"; do
    [ -n "$name" ] && printf 'FAIL %s\n' "$name" >&2
done

if [ "${#FAILED[@]}" -eq 0 ]; then
    printf 'all checks passed\n'
    status=0
else
    printf '%d check(s) failed\n' "${#FAILED[@]}" >&2
    status=1
fi

if [ "$JSON" -eq 1 ]; then
    failures_json="[]"
    if [ "${#FAILED[@]}" -gt 0 ]; then
        failures_json="[\"$(IFS=,; echo "${FAILED[*]}")\"]"
    fi
    printf '{"status":%d,"passed":%d,"failed":%d,"failures":%s}\n' \
        "$status" "${#PASSED[@]}" "${#FAILED[@]}" "$failures_json"
fi

exit $status