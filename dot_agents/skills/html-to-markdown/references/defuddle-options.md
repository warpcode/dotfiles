# defuddle Reference

Complete API and CLI reference for `defuddle` — the extraction and Markdown
conversion library from the Obsidian Web Clipper.

> **Version note:** This reference was compiled against defuddle v0.x.
> The library is actively developed. Always verify against
> `npx defuddle --help` or https://github.com/kepano/defuddle before
> scripting. Treat any flag you haven't personally tested as "verify first".

---

## What defuddle does

defuddle runs two passes over an HTML document:

1. **Extraction** — removes boilerplate (nav, footers, sidebars, ads, cookie
   banners, comment sections) using a scoring algorithm similar to Mozilla
   Readability. Identifies the main content element.

2. **Standardisation** — applies normalisation to the extracted HTML:
   - Heading hierarchy adjustment (first H1/H2 removed if it matches `<title>`)
   - Anchor links stripped from headings
   - Code blocks: syntax highlighting spans stripped, language preserved from class
   - Footnotes: normalised to a single canonical format
   - Math: MathJax/KaTeX expressions extracted from `<script>` tags or `data-latex`
   - Callouts: GitHub alerts / Bootstrap alerts → `> [!type]` syntax

3. **Conversion** — converts cleaned HTML to Markdown via TurndownService with
   the GFM plugin (tables, strikethrough, task lists).

---

## CLI Reference

```bash
npx defuddle <command> [options]
```

### Commands

#### `parse`

Parse and convert a document.

```bash
npx defuddle parse <input> [options]

# input:
#   file path:   page.html
#   URL:         https://example.com/article
#   stdin:       -
```

**Options:**

```
--markdown         Output as Markdown string (instead of default JSON)
--url <url>        Set the base URL for resolving relative links and images.
                   Required when parsing local HTML files that contain
                   relative hrefs/srcs. Use the original page URL.
--title            Prepend the extracted title as a top-level H1 heading
--no-remove        Disable element removal; extract all content as-is
--debug            Output verbose extraction scoring to stderr
```

**JSON output (default — without --markdown):**

```json
{
  "title":       "Article title",
  "author":      "Author name or null",
  "published":   "ISO 8601 date or null",
  "description": "Meta description or first paragraph",
  "image":       "Open Graph image URL or null",
  "favicon":     "Favicon URL or null",
  "domain":      "example.com",
  "content":     "<cleaned HTML>",
  "markdown":    "# Markdown output\n\n…"
}
```

Access specific fields in a pipeline:

```bash
# Get title only
npx defuddle parse page.html | jq -r '.title'

# Get markdown from JSON output
npx defuddle parse page.html | jq -r '.markdown'

# Or use --markdown flag directly (returns plain string, not JSON)
npx defuddle parse page.html --markdown
```

---

## Node.js API

### Installation

```bash
npm install defuddle
```

### Browser usage

Operates on the live DOM — runs in the browser extension context.

```javascript
import { Defuddle } from 'defuddle';

// Uses the current page's document
const result = new Defuddle(document).parse();
```

### Node.js usage

Requires a DOM parser. defuddle ships with a Node.js variant that uses
linkedom internally — no separate DOM library needed.

```javascript
import { Defuddle } from 'defuddle/node';

const html = '<html>…</html>';
const result = new Defuddle(html, {
  url: 'https://example.com/article'   // base URL for relative link resolution
}).parse();
```

### Constructor options

```typescript
new Defuddle(input, options?)

// input:  Document (browser) | string (Node.js)
// options (all optional):
{
  url:      string,   // Base URL for resolving relative hrefs/srcs
  debug:    boolean,  // Emit extraction debug info to console
}
```

### Result object

```typescript
interface DefuddleResult {
  title:       string | null;
  author:      string | null;
  published:   string | null;   // ISO 8601
  description: string | null;
  image:       string | null;   // OG image URL
  favicon:     string | null;
  domain:      string | null;
  content:     string;          // Cleaned HTML
  markdown:    string;          // Markdown-converted output
}
```

---

## Pipeline Patterns

### Fetch + convert in a single command

```bash
# Direct URL (defuddle fetches internally)
npx defuddle parse https://example.com/article --markdown

# Fetch separately (useful for auth, custom headers, cookies)
curl -s -A "Mozilla/5.0" \
     -H "Cookie: session=abc" \
     https://example.com/article \
  | npx defuddle parse - --markdown --url https://example.com/article
```

### Save with metadata frontmatter

```bash
#!/usr/bin/env bash
# clip_page.sh — fetch URL, extract markdown, prepend YAML frontmatter

url="${1:?Usage: clip_page.sh <url>}"
out_dir="${2:-~/notes/web-clips}"

# Get JSON with all metadata (-j flag outputs JSON)
json=$(npx defuddle parse "$url" -j)

title=$(echo "$json" | jq -r '.title // "Untitled"')
markdown=$(echo "$json" | jq -r '.markdown // .contentMarkdown // ""')
created_date=$(date +%Y-%m-%d)

# Build frontmatter using jq
frontmatter=$(echo "$json" | jq -r --arg created "$created_date" --arg source "$url" '
  .title as $title |
  .description as $desc |
  ((.published | if . then sub("T.*"; "") else null end) // $created) as $published |
  (if .author == null then []
   elif (.author | type) == "array" then .author
   elif (.author | type) == "string" then (.author | split(", ") | map(split(" and ")[]))
   else [] end) as $authors |
  "---",
  "title: \($title | @json)",
  "source: \($source | @json)",
  "author:",
  ($authors | map("  - \"[[\(.)]]\"")[]),
  "published: \($published)",
  "created: \($created)",
  "description: \($desc | @json)",
  "tags:",
  "  - \"clippings\"",
  "---"
')

# Build safe filename from title
safe_name=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | cut -c1-60)
out_file="$out_dir/${safe_name}.md"

# Write frontmatter and markdown to file
{
  echo "$frontmatter"
  echo ""
  echo "$markdown"
} > "$out_file"

echo "Saved: $out_file"
```

### Integrate with agy skill pipeline

```bash
# In a skill's action block — convert HTML variable to Markdown
html_to_md() {
  local html_input="$1"
  local base_url="${2:-}"

  if [[ -n "$base_url" ]]; then
    echo "$html_input" | npx defuddle parse - --markdown --url "$base_url"
  else
    echo "$html_input" | npx defuddle parse - --markdown
  fi
}

# Usage
content=$(curl -s "$url")
markdown=$(html_to_md "$content" "$url")
```

---

## What defuddle Does NOT Do

Be aware of these limitations when choosing tools:

- **Does not handle PDFs** — use `pdftotext`, `pymupdf`, or similar
- **Does not execute JavaScript** — static HTML only; dynamic SPAs require a
  headless browser (Playwright, Puppeteer) to pre-render first
- **Does not authenticate** — handle auth with curl/wget before piping to defuddle
- **Does not batch** — process files one at a time; wrap in a shell loop for bulk
- **Footnote/math conversion is best-effort** — complex academic papers may need
  manual review

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Empty output | Dynamic SPA, content loaded by JS | Pre-render with `playwright` or `puppeteer`, then pipe HTML |
| Relative image/link URLs in output | `--url` not set | Add `--url https://source-domain.com` |
| Noise (nav/footer) still present | Unconventional site layout | Use `--no-remove` + manual cleanup, or use Python `markdownify` with a `BeautifulSoup` pre-selector |
| Missing language on code blocks | Classes not matching `language-X` pattern | Post-process with sed: `sed 's/^```$/```text/'` to mark unknown blocks |
| Tables rendered as HTML | Turndown GFM plugin not converting complex tables | Complex tables are left as HTML — see `element-mapping.md §Complex tables` |
| Rate limiting when parsing URLs | defuddle fetches directly | Fetch with curl (with delay/retries) and pipe via stdin instead |
