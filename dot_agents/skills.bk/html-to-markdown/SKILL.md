---
name: html-to-markdown
description: >
  Convert HTML content to clean Markdown. Use this skill whenever you need to
  transform HTML strings, fragments, or full web pages into Markdown format —
  including web clipping, content pipeline processing, note ingestion, API
  response cleaning, or any task that takes HTML as input and outputs .md text.
  Trigger on: "convert this HTML", "extract as markdown", "clip this page",
  "turn HTML into markdown", "parse HTML to md", "save this as a note",
  "scrape and convert", or any task where the input is HTML and the desired
  output is readable Markdown. Also trigger when a pipeline step receives HTML
  from curl, a browser, or an API and needs to pass clean text to a downstream
  LLM or file.
---

# HTML → Markdown

Universal skill for converting HTML to Markdown across three modes: CLI (defuddle),
Python (markdownify / html2text), and LLM-native (direct rule-based conversion).

---

## Mode Selection

```
Input available as…         Preferred mode
────────────────────────────────────────────────────────────────
File or URL on disk         defuddle CLI  ← always try this first
Piped HTML string           defuddle CLI (stdin) or Python
Embedded in Python script   markdownify (pip)
No shell/exec available     LLM-native conversion (this SKILL.md)
Full web page + extraction  defuddle CLI (handles noise removal)
Fragment / snippet only     LLM-native or markdownify
```

---

## Mode 1 — defuddle CLI (Primary)

`defuddle` is the library powering the official Obsidian Web Clipper. It handles
noise removal (nav, ads, sidebars), HTML standardisation, and Markdown conversion
in one pass. **Always prefer this when a shell is available.**

### Install / run (zero global install required)

```bash
# One-shot via npx (no install needed)
npx defuddle parse page.html --markdown

# From URL (fetches + converts)
npx defuddle parse https://example.com/article --markdown

# From stdin
curl -s https://example.com/article | npx defuddle parse - --markdown

# Save to file
npx defuddle parse page.html --markdown > output.md

# Global install (faster for repeated use in pipelines)
npm install -g defuddle
defuddle parse page.html --markdown
```

### Useful flags

```bash
--markdown          # Output Markdown (required; default is JSON)
--url <url>         # Base URL for resolving relative links when parsing local HTML
--title             # Prefix output with extracted title as H1
--no-remove         # Skip element removal (keep nav/footer — rarely needed)
```

### In a shell skill / agy pipeline

```bash
#!/usr/bin/env bash
# html_to_md.sh — convert HTML file or URL to Markdown
# Usage: html_to_md.sh <file-or-url> [base-url]

input="${1:?Usage: html_to_md.sh <file|url> [base-url]}"
base_url="${2:-}"

if [[ -n "$base_url" ]]; then
  npx defuddle parse "$input" --markdown --url "$base_url"
else
  npx defuddle parse "$input" --markdown
fi
```

### Node.js API (for agy skills that embed JS)

```javascript
import { Defuddle } from 'defuddle/node';  // requires: npm i defuddle
import { readFileSync } from 'fs';

const html = readFileSync('page.html', 'utf8');
const result = new Defuddle(html, { url: 'https://example.com' }).parse();

console.log(result.content);    // Markdown string
console.log(result.title);      // Extracted title
console.log(result.author);     // Extracted author (if available)
console.log(result.published);  // Extracted date (if available)
```

> **Verify:** defuddle API surface changes with minor versions. Confirm flags
> against `npx defuddle --help` or https://github.com/kepano/defuddle before
> scripting in CI.

---

## Mode 2 — Python

Use when the conversion is embedded in a Python script (e.g. inside a jira_report
pipeline or a Python-based agy skill).

### markdownify (recommended for fragments)

```bash
pip install markdownify
```

```python
from markdownify import markdownify as md

html = "<h1>Title</h1><p>Hello <strong>world</strong></p>"
markdown = md(html, heading_style="ATX")   # ATX = # style headings
print(markdown)
# → # Title\n\nHello **world**
```

Key options:

```python
md(html,
   heading_style="ATX",          # "ATX" (# style) or "SETEXT" (underline style)
   bullets="-",                  # List bullet character: -, *, +
   strip=["script","style"],     # Tags to remove before conversion
   convert=["a","p","h1"],       # Only convert these tags (allowlist mode)
   newline_style="backslash",    # How to handle <br>: "backslash" or "spaces"
)
```

### html2text (recommended for full-page conversion)

```bash
pip install html2text
```

```python
import html2text

h = html2text.HTML2Text()
h.ignore_links = False
h.ignore_images = False
h.body_width = 0          # Disable line wrapping
h.unicode_snob = True     # Use Unicode chars instead of ASCII approximations
h.bypass_tables = False   # Convert tables to Markdown GFM tables

with open("page.html") as f:
    markdown = h.handle(f.read())
```

CLI usage:

```bash
html2text page.html > output.md
cat page.html | html2text > output.md
```

### Comparison

| Feature              | markdownify | html2text |
|----------------------|-------------|-----------|
| GFM tables           | ✅           | ✅        |
| Code block language  | ⚠ partial  | ❌        |
| Noise removal        | ❌           | ❌        |
| Inline style strip   | ✅           | ✅        |
| Footnotes            | ❌           | ❌        |
| Best for             | Fragments   | Full pages|

Neither Python library does noise removal. For full pages with nav/footer/sidebar
clutter, **pipe through defuddle first**, then use Python for any post-processing.

---

## Mode 3 — LLM-Native Conversion

Use when no shell execution is available and the HTML is provided directly as text
in the prompt. Apply the element mapping table below to convert inline.

Read `references/element-mapping.md` for the full mapping table.

**Conversion order (process in this sequence):**

```
1. Strip:      <script>, <style>, <noscript>, <iframe>, <form>, <button>
2. Strip:      HTML comments <!-- ... -->
3. Strip:      Inline styles and class/id attributes (keep href, src, alt, lang)
4. Convert:    Block elements (headings, paragraphs, lists, blockquotes, tables)
5. Convert:    Inline elements (bold, italic, code, links, images)
6. Convert:    Code blocks (preserve language hint from class="language-X")
7. Resolve:    Relative URLs → absolute (using known base URL if provided)
8. Collapse:   3+ consecutive blank lines → 2 blank lines
9. Trim:       Leading/trailing whitespace per block
```

**Critical rules:**

- MUST NOT invent content not present in the HTML.
- MUST NOT drop link `href` values — always render as `[text](url)`.
- MUST NOT render `<img>` as text; always render as `![alt](src)`. If `alt` is
  empty, use an empty alt: `![](src)`.
- MUST preserve code block language from `class="language-X"` or `class="lang-X"`.
- Tables MUST use GFM pipe syntax (see `references/element-mapping.md`).
- Nested lists MUST be indented by 2 spaces per level.

---

## Obsidian-Specific Extensions

When the output targets an Obsidian vault, apply these additional rules:

```
Highlights:    <mark>text</mark>           →  ==text==
Callouts:      See references/element-mapping.md §Callouts
Wikilinks:     Do NOT convert — leave [[...]] as-is if already present
Frontmatter:   Prepend YAML block if metadata is available. The YAML block must follow this exact format:
               ---
               title: "{{title}}"
               source: "{{url}}"
               author:
                 - "[[{{author_1}}]]"
                 - "[[{{author_2}}]]"
               published: {{published_date}}
               created: {{created_date}}
               description: "{{description}}"
               tags:
                 - "clippings"
               ---

               Rules for metadata fields:
               - **title**: The title of the article, double quoted.
               - **source**: The URL of the article, double quoted.
               - **author**: A list of authors formatted as double-quoted Obsidian wikilinks (e.g., `- "[[Rachel Flynn]]"`). Split comma-separated names, "and", or list items into separate list items. If no author is found, omit this field or use `[]`.
               - **published**: The publication date of the article in `YYYY-MM-DD` format.
               - **created**: The current date when the note is created in `YYYY-MM-DD` format.
               - **description**: A concise summary/description of the article, double quoted.
               - **tags**: A list of tags, containing `- "clippings"` by default.
```

---

## Output Quality Checklist

Before passing converted Markdown downstream, verify:

- [ ] No raw `<tag>` strings remain (except intentional HTML escapes)
- [ ] All links are absolute URLs or valid relative paths
- [ ] Code blocks have opening and closing fence (` ``` `)
- [ ] Tables have header row separator (`|---|---|`)
- [ ] No 3+ consecutive blank lines
- [ ] Heading hierarchy is intact (no skipped levels if possible)
- [ ] No `&amp;`, `&lt;`, `&gt;` — decoded to `&`, `<`, `>`
- [ ] Images have `![alt](url)` form (empty alt OK, missing `!` is a bug)

---

## Reference Files

| File | Load when |
|------|-----------|
| `references/element-mapping.md` | LLM-native conversion, or checking a specific element |
| `references/defuddle-options.md` | Scripting defuddle in Node.js or verifying CLI flags |
