# EXTERNAL TOOL COMMANDS (Run Locally - NOT by the agent)

## CODESPELL (Fast Typo Fixer)
- **Install**: `pip install codespell`
- **Basic Usage**: `codespell README.md`
- **Directory**: `codespell --ignore-words-list=words.txt docs/`
- **Custom Dictionary**: `codespell --dictionary custom_dict.txt file.txt`
- **Batch**: `find . -name "*.md" -exec codespell {} \;`

## CSPELL (Configurable Spell Checker for Code/Docs)
- **Install**: `npm install -g cspell` OR use `npx`
- **Basic**: `npx cspell "docs/**/*.md" "**/*.md"`
- **Config**: Add `cspell.json` or `.cspell.json` in repo root for custom dictionary
- **Project**: Configure project-specific terms to avoid false positives

## LANGUAGETOOL (Grammar & Style)
- **Install (CLI)**: https://languagetool.org
- **Run**: `languagetool -l en-US docs/guide.md`
- **Use Case**: Deep grammar and style checking

## VALE (Prose Linter)
- **Install**: https://docs.errata.ai/vale/about
- **Run**: `vale --config .vale.ini docs/`
- **Config**: Style guide enforcement for documentation

## ASPELL (Traditional Spell Checker)
- **Install**: `apt-get install aspell` (Linux), `brew install aspell` (macOS)
- **Run**: `aspell check README.md`

## HUNSPELL (Enhanced Spell Checker)
- **Install**: `apt-get install hunspell` (Linux), `brew install hunspell` (macOS)
- **Run**: `hunspell -l file.txt`

## ALEX (Inclusive Language Checker)
- **Install**: `npm install -g alex` OR use `npx`
- **Run**: `npx alex docs/README.md`
- **Use Case**: Detect non-inclusive language patterns

## CI INTEGRATION NOTES
- **Pipeline**: Run `codespell` and `cspell` as part of docs pipeline
- **Staged**: Run `languagetool` or `vale` as staged checks (pre-commit)
- **Custom Dictionaries**: Provide custom dictionaries/terminology files to avoid false positives for technical terms

## CUSTOMIZATION RECOMMENDATIONS
- Add technical terms to project-specific dictionaries
- Configure tool exclusions for code blocks, code comments
- Set severity thresholds appropriate for project needs
- Integrate with pre-commit hooks for automated checking
