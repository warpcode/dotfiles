---
name: html-to-markdown
description: >
  Convert HTML snippets, web pages, or API responses into clean Markdown,
  GFM tables, and Obsidian notes. Use when converting HTML to markdown,
  clipping web content, or cleaning HTML formatting.
---

# HTML to Markdown Knowledge Centre

Universal guide for converting HTML to clean Markdown and GFM across three modes: `defuddle` CLI, Python (`markdownify` / `html2text`), and LLM-native conversion.

## Mode Selection

| Input Context | Preferred Mode | Notes |
|---|---|---|
| File or URL on disk | `defuddle` CLI | Always try first; removes nav/ads/sidebars |
| Piped HTML string | `defuddle` CLI (stdin) or Python | Use `defuddle` for noisy pages |
| Embedded in Python script | `markdownify` / `html2text` | `markdownify` for fragments, `html2text` for pages |
| No shell execution available | LLM-native conversion | Follow Conversion Order + `@references/element-mapping.md` |
| Obsidian vault web clipping | Any mode + Obsidian schema | Apply `@references/obsidian-clippings.md` |

---

## Mode 1 — `defuddle` CLI (Primary)

`defuddle` (the Obsidian Web Clipper engine) handles noise removal, HTML standardisation, and Markdown conversion in one pass.

```bash
# One-shot via npx (no global install needed)
npx defuddle parse page.html --markdown
npx defuddle parse https://example.com/article --markdown
curl -s https://example.com/article | npx defuddle parse - --markdown
```

Key flags: `--markdown` (required for Markdown instead of JSON), `--url <url>` (base URL for relative links), `--title` (prepend H1), `--no-remove` (keep nav/footer). See `@references/defuddle-options.md` for Node.js API, JSON fields, and shell pipeline scripts, and verify flags against `npx defuddle --help`.

---

## Mode 2 — Python

Use when embedding HTML conversion in Python scripts. Neither library removes page boilerplate — pipe full web pages through `defuddle` first if noisy.

| Feature | `markdownify` (fragments) | `html2text` (full pages) |
|---|---|---|
| GFM tables & style stripping | Yes | Yes |
| Code block language hints | Partial | No |
| Noise removal / footnotes | No | No |

- **`markdownify`**: `md(html, heading_style="ATX", bullets="-", strip=["script", "style"])`
- **`html2text`**: Set `h.body_width = 0`, `h.unicode_snob = True`, `h.bypass_tables = False`

---

## Mode 3 — LLM-Native Conversion

When no shell is available, convert inline HTML in this sequence against `@references/element-mapping.md`:

1. Strip `<script>`, `<style>`, `<noscript>`, `<iframe>`, `<form>`, `<button>`, and HTML comments (`<!-- ... -->`).
2. Strip inline styles and `class`/`id` attributes (retain `href`, `src`, `alt`, `lang`).
3. Convert block elements (headings, paragraphs, lists, blockquotes, GFM pipe tables) and inline elements.
4. Convert fenced code blocks, preserving language hints from `class="language-X"` / `class="lang-X"`.
5. Resolve relative URLs against any known base URL, collapse 3+ blank lines to 2, and trim block whitespace.

**Critical invariants**: Never invent content, never drop `href` values, always render images as `![alt](src)` (empty alt allowed), and indent nested lists by 2 spaces per level.

---

## Output Quality Checklist

- [ ] No stray raw `<tag>` strings or un-decoded `&amp;` / `&lt;` / `&gt;` entities
- [ ] Links resolved (absolute or valid relative) and images use `![alt](url)`
- [ ] Fenced code blocks (` ``` `) closed; GFM tables include `|---|---|` header separators
- [ ] No 3+ consecutive blank lines; heading hierarchy intact

## Reference Files

| File | Load When |
|---|---|
| `@references/element-mapping.md` | LLM-native conversion, or checking specific HTML elements, tables, math, or callouts |
| `@references/defuddle-options.md` | Scripting `defuddle` in Node.js, shell pipelines, or verifying CLI options |
| `@references/obsidian-clippings.md` | Output targets an Obsidian vault (`==highlights==`, wikilinks, YAML clipping frontmatter) |
