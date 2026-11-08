Plan:
1. Update `get_first_commit` in `extract-git-history.py` to handle empty repos (no commits) safely:
   ```python
   def get_first_commit(cwd: Optional[Path] = None) -> str:
       """Get the initial root commit in git history."""
       lines = run_git_cmd(["rev-list", "--max-parents=0", "HEAD"], cwd=cwd).splitlines()
       return lines[0] if lines else ""
   ```
2. Update `fetch_git_commits` in `extract-git-history.py` to fix the `from_ref` logic so that if `from_ref` is the first commit, it just uses `to_ref` for the `git log` command instead of `f"{from_ref}..{to_ref}"`, and returns empty list if `from_ref` is empty.
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

       if from_ref == get_first_commit(cwd):
           rev_range = to_ref
       else:
           rev_range = f"{from_ref}..{to_ref}"

       # ...
   ```
3. Update `main` in `extract-git-history.py` to exit cleanly if `base_ref` is empty:
   ```python
       base_ref = args.from_ref or get_latest_tag()
       if not base_ref:
           base_ref = get_first_commit()

       if not base_ref:
           print("No commits found in repository.", file=sys.stderr)
           sys.exit(0)
   ```
4. Write tests for `extract-git-history.py` to verify this behavior for both 0 commits and 1 commit repos.
