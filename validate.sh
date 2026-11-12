#!/usr/bin/env bash
#
# Local mirror of CI validation for this repository.
#
# CI splits across three workflows:
#   lint.yml         -> zsh -n over *.zsh, plus dot_zsh/tests/*.zsh suites
#   python-tests.yml -> unittest discovery under .github/skills/*/scripts and tests/
#   test.yml         -> container matrix and macOS integration tests
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

# Guard against rogue test suites or runaway memory allocation.
# Cap virtual memory at 8GB so any infinite allocation loop fails cleanly with MemoryError
# rather than exhausting system RAM and triggering the Linux kernel OOM-killer.
if [ "$(ulimit -v)" = "unlimited" ] || [ "$(ulimit -v)" -gt 8388608 ]; then
    ulimit -v 8388608 2>/dev/null || true
fi

FAST=0
LINT_ONLY=0
JSON=0
CHANGED=0

usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

for arg in "$@"; do
    case "$arg" in
        --fast) FAST=1 ;;
        --lint-only) LINT_ONLY=1 ;;
        --json) JSON=1 ;;
        --changed) CHANGED=1 ;;
        -h | --help) usage 0 ;;
        *)
            printf 'validate: unknown argument: %s\n' "$arg" >&2
            usage 2
            ;;
    esac
done

FAILED=()
PASSED=()

CHANGED_FILES=""
if [ "$CHANGED" -eq 1 ]; then
    base_ref="HEAD"
    if git show-ref -q --verify refs/remotes/origin/master; then
        base_ref="origin/master"
    elif git show-ref -q --verify refs/heads/master; then
        base_ref="master"
    fi
    # Get modified, added, and deleted files relative to base_ref, plus untracked files
    CHANGED_FILES="$(git diff --name-only "$base_ref"...HEAD 2>/dev/null || true)"
    CHANGED_FILES="$CHANGED_FILES"$'\n'"$(git ls-files --others --exclude-standard 2>/dev/null || true)"
fi

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

is_changed() {
    local target="$1"
    # Remove leading ./ if present in the target for matching
    target="${target#./}"

    if [ "$CHANGED" -eq 1 ]; then
        if echo "$CHANGED_FILES" | grep -F -q -x "$target"; then
            return 0
        fi
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Shell / Zsh syntax (mirrors lint.yml)
# ---------------------------------------------------------------------------

lint_zsh() {
    local failed=0
    while IFS= read -r f; do
        if ! is_changed "$f"; then
            continue
        fi
        zsh -n "$f" || failed=1
    done < <(find . -name '*.zsh' -not -path './.git/*')
    return "$failed"
}

if have zsh; then
    run "zsh -n (syntax)" lint_zsh
else
    printf '\nSKIP zsh -n (syntax) (zsh not installed)\n'
fi

lint_bash() {
    local failed=0
    while IFS= read -r f; do
        if ! is_changed "$f"; then
            continue
        fi
        bash -n "$f" || failed=1
    done < <(find . -name '*.sh' -not -path './.git/*')
    return "$failed"
}

run "bash -n (syntax)" lint_bash

check_stray_artifacts() {
    local strays filtered_strays=""
    strays="$(git ls-files 2>/dev/null | grep -E '\.(rej|orig)$' || true)"

    if [ -n "$strays" ]; then
        for stray in $strays; do
            if is_changed "$stray"; then
                filtered_strays="$filtered_strays$stray"$'\n'
            fi
        done
        # Remove trailing newline
        filtered_strays="${filtered_strays%?}"

        if [ -n "$filtered_strays" ]; then
            printf 'Found stray patch/merge artifact files:\n%s\n' "$filtered_strays" >&2
            return 1
        fi
    fi
    return 0
}

run "stray-artifacts" check_stray_artifacts

# ---------------------------------------------------------------------------
# Zsh unit tests (mirrors the lint.yml runner step)
# ---------------------------------------------------------------------------

run_zsh_tests() {
    [ -d dot_zsh/tests ] || {
        printf 'dot_zsh/tests/ not found\n' >&2
        return 1
    }
    local failed=0 ran=0
    for suite in dot_zsh/tests/*.zsh; do
        [ -f "$suite" ] || continue

        if [ "$CHANGED" -eq 1 ]; then
            local should_run=0
            if is_changed "$suite"; then
                should_run=1
            else
                # Check if the corresponding source file changed
                local suite_basename
                suite_basename="$(basename "$suite" .test.zsh)"
                suite_basename="${suite_basename%.zsh}" # fallback if not .test.zsh
                # Search for any changed file matching the basename
                while IFS= read -r f; do
                    [ -n "$f" ] || continue
                    if [[ "$f" == *"/${suite_basename}.zsh" ]]; then
                        should_run=1
                        break
                    fi
                done <<< "$CHANGED_FILES"
            fi

            [ "$should_run" -eq 1 ] || continue
        fi

        ran=$((ran + 1))
        printf -- '--- %s\n' "$suite"
        zsh "$suite" || failed=1
    done
    if [ "$ran" -eq 0 ]; then
        printf 'no zsh test suites found\n' >&2
        return 1
    fi
    return "$failed"
}

if [ "$LINT_ONLY" -eq 0 ]; then
    if have zsh; then
        run "zsh tests (dot_zsh/tests)" run_zsh_tests
    else
        printf '\nSKIP zsh tests (zsh not installed)\n'
    fi
fi

# ---------------------------------------------------------------------------
# Static analysis, declared in AGENTS.md but with no workflow running it yet.
# ---------------------------------------------------------------------------

# ShellCheck supports sh/bash/dash/ksh only -- feeding it *.zsh yields
# SC1071, not real findings. Zsh is covered by the `zsh -n` check above.
shellcheck_all() {
    local failed=0
    local target_files=""

    for f in $(git ls-files '*.sh'); do
        if is_changed "$f"; then
            target_files="$target_files $f"
        fi
    done

    if [ -z "$target_files" ] && [ "$CHANGED" -eq 1 ]; then
        return 0
    fi

    # shellcheck disable=SC2046
    # shellcheck disable=SC2086
    shellcheck --severity=warning --external-sources $target_files ||
        failed=1
    return "$failed"
}

if have shellcheck; then
    run "shellcheck" shellcheck_all
else
    printf '\nSKIP shellcheck (not installed)\n'
fi

# ---------------------------------------------------------------------------
# Python compile (all tracked Python, not just skills/)
# ---------------------------------------------------------------------------

compile_python() {
    if [ "$CHANGED" -eq 1 ]; then
        local target_files=""
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            # Only consider files ending in .py
            case "$f" in
                *.py) target_files="$target_files $f" ;;
            esac
        done <<< "$CHANGED_FILES"

        if [ -n "$target_files" ]; then
            # shellcheck disable=SC2086
            python3 -m compileall -q $target_files
        fi
    else
        python3 -m compileall -q .github/skills tests dot_agents
    fi
}

run "py_compile" compile_python

# ---------------------------------------------------------------------------
# Python unit tests (mirrors python-tests.yml discovery)
# ---------------------------------------------------------------------------

# Suites already red on master, for reasons unrelated to any change under
# review. Mirrors python-tests.yml: remove a name only once it is green on
# master -- do not use this list to hide a new failure.
skip_root_suites="test_ai_guard test_software_hooks"

exec_skill_unittest() {
    local scripts_dir="$1"
    shift
    if [ -f "$scripts_dir/pyproject.toml" ]; then
        (cd "$scripts_dir" && PYTHONPATH=. uv run --locked python3 -m unittest "$@")
    else
        (cd "$scripts_dir" && PYTHONPATH=. python3 -m unittest "$@")
    fi
}

run_single_skill_tests() {
    local scripts_dir="$1"
    local failed=0
    local skill test_file

    skill="$(basename "$(dirname "$scripts_dir")")"

    # Suites use both layouts. Discovery must run from inside scripts/ --
    # most have no tests/__init__.py, so passing -t makes unittest fail
    # with "Start directory is not importable".
    if [ -d "$scripts_dir/tests" ]; then
        printf -- '--- %s tests/\n' "$skill"
        exec_skill_unittest "$scripts_dir" discover -s tests || failed=1
    fi

    for test_file in "$scripts_dir"/test_*.py; do
        [ -e "$test_file" ] || continue
        printf -- '--- %s %s\n' "$skill" "$(basename "$test_file")"
        exec_skill_unittest "$scripts_dir" "$(basename "$test_file" .py)" || failed=1
    done

    return $failed
}

run_skill_tests() {
    local failed=0
    local scripts_dir

    for scripts_dir in .github/skills/*/scripts; do
        [ -d "$scripts_dir" ] || continue

        if [ "$CHANGED" -eq 1 ]; then
            # Extract the skill directory (one level up from scripts_dir)
            local skill_dir
            skill_dir="$(dirname "$scripts_dir")"
            # Remove leading ./ if present for matching
            skill_dir="${skill_dir#./}"

            local should_run=0
            while IFS= read -r f; do
                [ -n "$f" ] || continue
                if [[ "$f" == "$skill_dir/"* ]]; then
                    should_run=1
                    break
                fi
            done <<< "$CHANGED_FILES"

            [ "$should_run" -eq 1 ] || continue
        fi

        run_single_skill_tests "$scripts_dir" || failed=1
    done

    return $failed
}

run_root_python_tests() {
    local failed=0
    local test_file module

    # Repo-root tests/ is a flat set of modules with no __init__.py, so it
    # is invoked as tests.<module>.
    for test_file in tests/test_*.py; do
        [ -e "$test_file" ] || continue

        if [ "$CHANGED" -eq 1 ]; then
            local should_run=0
            if is_changed "$test_file"; then
                should_run=1
            else
                local module_basename
                module_basename="$(basename "$test_file" .py)"
                # Typical naming: test_foo.py tests foo.py or foo/
                # Check for either test_foo or foo changes
                local src_pattern="${module_basename#test_}"
                local src_pattern2="${src_pattern//_/-}"
                local src_pattern3="${src_pattern//_/.}"
                while IFS= read -r f; do
                    [ -n "$f" ] || continue
                    if [[ "$f" == *"$src_pattern"* ]] || [[ "$f" == *"$src_pattern2"* ]] || [[ "$f" == *"$src_pattern3"* ]]; then
                        should_run=1
                        break
                    fi
                done <<< "$CHANGED_FILES"
            fi

            [ "$should_run" -eq 1 ] || continue
        fi

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

run_python_tests() {
    local failed=0
    run_skill_tests || failed=1
    run_root_python_tests || failed=1
    return $failed
}

if [ "$FAST" -eq 1 ]; then
    printf '\nSKIP unittest (--fast)\n'
elif [ "$LINT_ONLY" -eq 1 ]; then
    printf '\nSKIP unittest (--lint-only)\n'
else
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