The bug:
If a repository has only 1 commit and no tags, `git rev-list --max-parents=0 HEAD` returns that commit. If we use this as `from_ref` for `git log {from_ref}..HEAD`, git returns empty output because `..` means "commits reachable from HEAD but not from from_ref". Since HEAD and from_ref are the same commit, the result is empty.
Thus, a repo with 1 commit generates an empty changelog.

In fact, even for a repo with >1 commits and no tags, `from_ref` is `get_first_commit()`. So `git log {from_ref}..HEAD` will omit the first commit from the changelog! A changelog generated for a project's first release should probably include all commits, not skip the very first one.

Wait, if we change `fetch_git_commits` to use `git log` WITHOUT a range when there is no tag, it will include all commits, including the first one. But wait! `from_ref` is used throughout the script. For example, `build_provenance_and_changelog` prints the range and needs `from_ref`.
If we change `from_ref` to be `get_first_commit()` but change `rev_range` to just be `to_ref` when `from_ref == get_first_commit()`, it won't work in cases where someone wants only a subrange? But if they specify `from_ref`, they usually want `from_ref..to_ref`. If they explicitly specify the first commit, they get the behavior `FIRST_COMMIT..to_ref` which drops the first commit. This is consistent with git.

But when `from_ref` is *defaulted* by our code to `get_first_commit()`, we should probably include the first commit!
Actually, how does `fetch_git_commits` handle `from_ref` if it's explicitly passed as the first commit?

```python
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        is_all_commits = True if not base_tag else False
        from_ref = base_tag if base_tag else get_first_commit(cwd)

    if from_ref == get_first_commit(cwd):
        # We want to include the first commit, so we don't exclude it in the range!
        # git log HEAD will show all commits
        pass
```

Wait, `git log FIRST_COMMIT..HEAD` excludes FIRST_COMMIT.
Is there a way to say `git log FIRST_COMMIT^..HEAD`? No, FIRST_COMMIT has no parent, so `FIRST_COMMIT^` is an error.
To include FIRST_COMMIT in the git log output, we can just run `git log HEAD` (i.e. just pass `to_ref` and NO range).

So we can do:
```python
def fetch_git_commits(
    from_ref: Optional[str],
    to_ref: str,
    path_filter: Optional[str] = None,
    cwd: Optional[Path] = None,
) -> List[Dict[str, Any]]:
    """Retrieve commits between from_ref and to_ref."""
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        from_ref = base_tag if base_tag else get_first_commit(cwd)

    first_commit = get_first_commit(cwd)
    if from_ref == first_commit:
        rev_range = to_ref
    else:
        rev_range = f"{from_ref}..{to_ref}"
```
Wait, if `from_ref` equals `first_commit`, should we ALWAYS just use `to_ref`?
Yes, because if the user manually specifies `from_ref = first_commit`, doing `FIRST_COMMIT..HEAD` drops the first commit. But `git log to_ref` gets all commits, which includes the first commit. If they want to drop the first commit, they are trying to do something weird. In almost all cases, if they ask for `FIRST_COMMIT..HEAD`, they expect all commits from the first commit to HEAD. Wait, in git, `A..B` *always* excludes `A`. But `extract-git-history.py` presents `from_ref` as the start of the range. If they specify the first commit, they probably want it included.
Even if we just change the case where `from_ref` is *defaulted*:
```python
def fetch_git_commits(
    from_ref: Optional[str],
    to_ref: str,
    path_filter: Optional[str] = None,
    cwd: Optional[Path] = None,
) -> List[Dict[str, Any]]:
    """Retrieve commits between from_ref and to_ref."""
    is_default_first = False
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        if base_tag:
            from_ref = base_tag
        else:
            from_ref = get_first_commit(cwd)
            is_default_first = True

    if is_default_first or from_ref == get_first_commit(cwd):
        rev_range = to_ref
    else:
        rev_range = f"{from_ref}..{to_ref}"
```
Actually, we can just do:
```python
    first_commit = get_first_commit(cwd)
    if from_ref == first_commit:
        rev_range = to_ref
    else:
        rev_range = f"{from_ref}..{to_ref}"
```
Wait, another issue: `get_first_commit()` throws `IndexError` if the repository is completely empty (0 commits).
```python
def get_first_commit(cwd: Optional[Path] = None) -> Optional[str]:
    """Get the initial root commit in git history."""
    lines = run_git_cmd(["rev-list", "--max-parents=0", "HEAD"], cwd=cwd).splitlines()
    return lines[0] if lines else None
```
Let's see the current `get_first_commit()`:
```python
def get_first_commit(cwd: Optional[Path] = None) -> str:
    """Get the initial root commit in git history."""
    return run_git_cmd(["rev-list", "--max-parents=0", "HEAD"], cwd=cwd).splitlines()[0]
```
If `run_git_cmd` returns empty string (because there are no commits yet), `.splitlines()` returns an empty list, so `[0]` raises `IndexError: list index out of range`. This crashes the script.
So we should fix this too.

Wait, `get_first_commit()` shouldn't return `str` if it can be `None`. But right now it is typed to return `str`.
If we change it to return `str`, we can return `""` if empty.
```python
def get_first_commit(cwd: Optional[Path] = None) -> str:
    """Get the initial root commit in git history."""
    lines = run_git_cmd(["rev-list", "--max-parents=0", "HEAD"], cwd=cwd).splitlines()
    return lines[0] if lines else ""
```
Then in `fetch_git_commits`:
```python
    first_commit = get_first_commit(cwd)
    if not first_commit:
        return []

    if from_ref == first_commit:
        rev_range = to_ref
    else:
        rev_range = f"{from_ref}..{to_ref}"
```
Wait, if `from_ref` was passed in, but the repo has NO commits, `first_commit` is `""`. `from_ref` would not match `""`. It would use `f"{from_ref}..{to_ref}"` which git handles.
Wait, if `not from_ref`:
```python
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        from_ref = base_tag if base_tag else get_first_commit(cwd)

    if not from_ref:
        return []
```
If we do this:
```python
def fetch_git_commits(
    from_ref: Optional[str],
    to_ref: str,
    path_filter: Optional[str] = None,
    cwd: Optional[Path] = None,
) -> List[Dict[str, Any]]:
    """Retrieve commits between from_ref and to_ref."""
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        from_ref = base_tag if base_tag else get_first_commit(cwd)

    if not from_ref:
        return []

    first_commit = get_first_commit(cwd)
    if from_ref == first_commit:
        rev_range = to_ref
    else:
        rev_range = f"{from_ref}..{to_ref}"
```
This correctly handles:
1. `get_first_commit` raising `IndexError` on empty repo (fixed by checking `lines`).
2. Repo with only 1 commit, or repo with no tags (it will use `to_ref` instead of `FIRST..to_ref`, including the first commit correctly).

Wait, I should check `main()` too.
```python
    repo_slug = args.repo or detect_repo_slug()
    base_ref = args.from_ref or get_latest_tag()
    if not base_ref:
        base_ref = get_first_commit()

    if not base_ref:
        # Repo has no commits
        print("No commits found in repository.", file=sys.stderr)
        sys.exit(0)
```
Let's see what happens if `base_ref` is `""`.
In `main()`:
```python
    repo_slug = args.repo or detect_repo_slug()
    base_ref = args.from_ref or get_latest_tag()
    if not base_ref:
        base_ref = get_first_commit()

    commits = fetch_git_commits(
        from_ref=base_ref,
        to_ref=args.to_ref,
        path_filter=args.path,
    )
```
If `base_ref` is `""`, `fetch_git_commits` gets `""` as `from_ref`.
Wait, in `fetch_git_commits`:
```python
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        from_ref = base_tag if base_tag else get_first_commit(cwd)
```
If `from_ref` passed is `""`, `not from_ref` is true, so it tries to find the tag and first commit again! Which is fine.
If repo is empty, `get_first_commit` returns `""`, so `from_ref` becomes `""`.
Then `if not from_ref: return []`.

Let's test this change.
