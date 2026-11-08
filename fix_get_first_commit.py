def test_fix_fetch_git_commits():
    import importlib.util
    import sys

    spec = importlib.util.spec_from_file_location('extract_git_history', '.github/skills/changelog-authoring/scripts/extract-git-history.py')
    extract_git_history = importlib.util.module_from_spec(spec)
    sys.modules['extract_git_history'] = extract_git_history
    spec.loader.exec_module(extract_git_history)

    print("Before fix:", len(extract_git_history.fetch_git_commits(from_ref=None, to_ref='HEAD', cwd='test-repo-2')))

test_fix_fetch_git_commits()
