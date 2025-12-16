Recommended external commands to run locally (do NOT execute inside Claude):

codespell (fast typo fixer):
- Install: `pip install codespell`
- Run: `codespell README.md` or `codespell --ignore-words-list=words.txt docs/`

cspell (configurable spell checker for code/docs):
- Install: `npm install -g cspell` or use `npx`
- Run: `npx cspell "docs/**/*.md" "**/*.md"`
- Add custom dictionary via `cspell.json` or `.cspell.json` in repo root.

LanguageTool (grammar & style):
- Install (CLI): see https://languagetool.org
- Run: `languagetool -l en-US docs/guide.md`

Vale (prose linter):
- Install: https://docs.errata.ai/vale/about
- Run: `vale --config .vale.ini docs/`

Notes:
- Provide custom dictionaries and terminology files to avoid false positives for technical terms.
- For CI integration, run `codespell` and `cspell` as part of the docs pipeline, and run `languagetool` or `vale` as a staged check.
