# HTML → Markdown Element Mapping

Complete reference for LLM-native conversion and verification. Derived from
the Obsidian Web Clipper / defuddle conversion pipeline.

---

## Table of Contents

1. [Block Elements](#block-elements)
2. [Inline Elements](#inline-elements)
3. [Links and Images](#links-and-images)
4. [Code](#code)
5. [Tables](#tables)
6. [Lists](#lists)
7. [Footnotes](#footnotes)
8. [Math](#math)
9. [Callouts](#callouts)
10. [Elements to Strip](#elements-to-strip)
11. [Entities](#entities)
12. [Edge Cases](#edge-cases)

---

## Block Elements

| HTML | Markdown | Notes |
|------|----------|-------|
| `<h1>text</h1>` | `# text` | ATX style only |
| `<h2>text</h2>` | `## text` | |
| `<h3>text</h3>` | `### text` | |
| `<h4>text</h4>` | `#### text` | |
| `<h5>text</h5>` | `##### text` | |
| `<h6>text</h6>` | `###### text` | |
| `<p>text</p>` | `text` + blank line | One blank line after |
| `<br>` | `\n` | Or two trailing spaces + `\n` |
| `<hr>` | `---` | Blank line before and after |
| `<blockquote>text</blockquote>` | `> text` | Nested: `>> text` |
| `<div>`, `<section>`, `<article>` | (block boundary) | Treat as paragraph separator |
| `<pre>text</pre>` | ` ```\ntext\n``` ` | Always fenced; see §Code |

### Heading rules (defuddle behaviour)

- If `<h1>` content matches the page `<title>`, **remove** it (avoid duplication with frontmatter).
- If `<h2>` content matches the page `<title>`, **remove** it.
- Anchor links inside headings (`<a name="...">`) → strip the `<a>`, keep text.
- `<h1>` within article body → convert to `##` (promote to avoid competing with note title).

---

## Inline Elements

| HTML | Markdown | Notes |
|------|----------|-------|
| `<strong>`, `<b>` | `**text**` | |
| `<em>`, `<i>` | `*text*` | |
| `<s>`, `<del>`, `<strike>` | `~~text~~` | GFM extension |
| `<mark>` | `==text==` | Obsidian only; plain MD: `**text**` |
| `<sup>` | `^text^` | Obsidian only; or use footnote ref |
| `<sub>` | `~text~` | Obsidian only |
| `<u>` | `<u>text</u>` | No Markdown equivalent; keep as HTML or drop |
| `<abbr title="X">Y</abbr>` | `Y (X)` | Expand abbreviation inline |
| `<cite>` | `*text*` | Italicise |
| `<q>text</q>` | `"text"` | Replace with smart quotes |
| `<kbd>key</kbd>` | `` `key` `` | Treat as inline code |
| `<var>` | `*text*` | Italicise |
| `<small>` | `text` | Strip tag, keep text |
| `<span>` | `text` | Strip tag, keep text (unless class carries meaning) |

---

## Links and Images

### Links

```
<a href="URL">text</a>  →  [text](URL)
<a href="URL" title="T">text</a>  →  [text](URL "T")
<a href="#anchor">text</a>  →  [text](#anchor)   ← keep anchors
```

**URL resolution rules:**

```
IF href starts with "http://" or "https://"  → use as-is
IF href starts with "/"                       → prepend base origin
IF href starts with "./", "../"               → resolve relative to base URL
IF href is "#fragment"                        → keep as-is (anchor link)
IF href is "mailto:" or "tel:"               → keep as-is
```

When no base URL is known and href is relative, keep the relative path and add
a `⚠ relative URL` comment after the link if the document will be moved.

### Images

```
<img src="URL" alt="text">          →  ![text](URL)
<img src="URL" alt="">              →  ![](URL)        ← empty alt is valid
<img src="URL">                     →  ![](URL)        ← no alt → empty
<img src="URL" width="1">           →  (strip)         ← tracking pixel
<img src="URL" height="1">          →  (strip)         ← tracking pixel
```

Tracking pixel detection: strip `<img>` where `width` or `height` attribute is
`"1"` (exact string match), OR where `src` contains known tracker domains.

```
<figure>
  <img src="URL" alt="alt">
  <figcaption>Caption text</figcaption>
</figure>
→
![alt](URL)
*Caption text*
```

---

## Code

### Inline code

```
<code>text</code>               →  `text`
<tt>text</tt>                   →  `text`
```

If `<code>` is inside a `<pre>`, it is a code block (see below) — not inline.

### Code blocks

```
<pre><code>text</code></pre>    →  ```\ntext\n```

With language class:
<pre><code class="language-python">…</code></pre>
→
```python
…
```

<pre><code class="lang-bash">…</code></pre>
→
```bash
…
```
```

**Language extraction rules:**
1. Check `class` attribute on `<code>` for `language-X` or `lang-X` pattern.
2. Check `data-lang`, `data-language` attributes on `<pre>` or `<code>`.
3. Check `class` attribute on `<pre>` itself.
4. If none found: use bare ` ``` ` (no language specifier).

**Content rules:**
- Strip syntax-highlighting `<span>` wrappers inside `<pre>` — keep only text content.
- Strip line-number elements (e.g. `<td class="line-number">`, `<span class="ln">`) before extracting text.
- Preserve indentation (tabs and spaces) exactly as-is.
- Do NOT HTML-decode entities a second time if they are already decoded — `&lt;` in source = `<` in output.

---

## Tables

GFM pipe table syntax. Always include header separator row.

```html
<table>
  <thead>
    <tr><th>Col A</th><th>Col B</th></tr>
  </thead>
  <tbody>
    <tr><td>1</td><td>2</td></tr>
    <tr><td>3</td><td>4</td></tr>
  </tbody>
</table>
```

→

```markdown
| Col A | Col B |
|-------|-------|
| 1     | 2     |
| 3     | 4     |
```

### Alignment

```html
<th style="text-align:left">   →  |:---|
<th style="text-align:center"> →  |:---:|
<th style="text-align:right">  →  |---:|
<th> (no alignment)            →  |---|
```

### No-header tables

If `<table>` has no `<thead>`, use the first `<tr>` as the header row:

```
| (row 1 cells) |
|---|---|
| (row 2 cells) |
```

### Complex tables

If a table contains merged cells (`colspan`, `rowspan`), nested tables, or block
content inside cells: **do not attempt GFM conversion**. Preserve as HTML verbatim
with a `<!-- complex table -->` comment, or flatten to a definition list.

---

## Lists

### Unordered

```html
<ul>
  <li>Item A</li>
  <li>Item B
    <ul>
      <li>Nested</li>
    </ul>
  </li>
</ul>
```

→

```markdown
- Item A
- Item B
  - Nested
```

Bullet character: `-` (preferred), or `*`, `+`. Be consistent within a document.
Nesting indent: 2 spaces per level.

### Ordered

```html
<ol>
  <li>First</li>
  <li>Second</li>
</ol>
```

→

```markdown
1. First
2. Second
```

For `<ol start="5">`, begin numbering at 5:

```markdown
5. Fifth
6. Sixth
```

### Task lists (GFM)

```html
<input type="checkbox" checked> Done
<input type="checkbox"> Pending
```

→

```markdown
- [x] Done
- [ ] Pending
```

### Definition lists

No standard Markdown equivalent. Options:
- Convert to bold term + indented definition:
  ```
  **Term**
    Definition text
  ```
- Or keep as HTML `<dl><dt><dd>` verbatim.

---

## Footnotes

HTML footnote patterns vary. Target output is standard Markdown footnote syntax
(supported by Obsidian and most extended Markdown parsers).

### Pattern A — inline superscript + endnotes section

```html
Text<sup id="fnref:1"><a href="#fn:1">1</a></sup> more text.

<div class="footnotes">
  <ol>
    <li id="fn:1">Footnote content. <a href="#fnref:1">↩</a></li>
  </ol>
</div>
```

→

```markdown
Text[^1] more text.

[^1]: Footnote content.
```

### Pattern B — Wikipedia-style

```html
<sup class="reference"><a href="#cite_note-1">[1]</a></sup>
```

→ Keep as `[1]` inline reference; list references at end as a numbered list if
a references section exists. Wikipedia-style citations do not map cleanly to
Markdown footnotes.

### Rules

- Strip the back-arrow link (`↩`, `↵`, `⬆`) from footnote content.
- Strip the `<div class="footnotes">` / `<section class="footnotes">` wrapper.
- Renumber footnotes sequentially from 1 if numbering is non-sequential.

---

## Math

Obsidian uses KaTeX. Target: LaTeX delimited by `$` (inline) and `$$` (block).

### MathJax / KaTeX rendered HTML → LaTeX

If the original `<script type="math/tex">` or `data-latex` attribute is preserved
in the HTML, extract from there (lossless). Otherwise fallback to MathML conversion
(lossy).

```html
<!-- MathJax script source (preferred) -->
<script type="math/tex">x^2 + y^2 = z^2</script>
→  $x^2 + y^2 = z^2$

<script type="math/tex; mode=display">
  \int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
</script>
→
$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$
```

```html
<!-- KaTeX data attribute -->
<span class="katex" data-latex="E=mc^2">…</span>
→  $E=mc^2$
```

If only rendered MathML `<math>` is available with no source expression, flag
with `<!-- math: conversion required -->` and include the MathML verbatim. Do
NOT attempt to reconstruct LaTeX from rendered MathML — this is extremely lossy.

---

## Callouts

Obsidian callout syntax: `> [!type] Optional Title`

### GitHub Markdown alerts → Obsidian callouts

```html
<div class="markdown-alert markdown-alert-note">
  <p class="markdown-alert-title">Note</p>
  <p>Content here</p>
</div>
```

→

```markdown
> [!note] Note
> Content here
```

### Bootstrap / common alert divs

```html
<div class="alert alert-warning">Warning message</div>
→
> [!warning]
> Warning message

<div class="alert alert-info">Info message</div>
→
> [!info]
> Info message

<div class="alert alert-danger">Error!</div>
→
> [!danger]
> Error!
```

### Callout type mapping

| HTML class / role | Obsidian type |
|-------------------|---------------|
| `alert-info`, `note`, `tip` | `info` |
| `alert-warning`, `warning`, `caution` | `warning` |
| `alert-danger`, `alert-error`, `danger` | `danger` |
| `alert-success`, `success`, `important` | `success` |
| `alert-tip`, `hint` | `tip` |
| `blockquote` (generic) | `> text` (plain blockquote) |

---

## Elements to Strip

Remove entirely (including all children):

```
<script>        JavaScript
<style>         CSS
<noscript>      Fallback content for no-JS (usually nav duplicates)
<iframe>        Embedded frames
<embed>         Plugins
<object>        Plugins
<canvas>        Rendered graphics (no text content)
<svg>           (strip unless it contains meaningful text via <text> elements)
<video>         Replace with image or text fallback if <poster> available
<audio>         Strip
<form>          Forms (strip entire subtree unless content-bearing)
<button>        UI buttons
<input>         Form inputs
<select>        Dropdowns
<textarea>      Form text areas
<nav>           Navigation menus
<aside>         Sidebars (unless content-bearing article asides)
<footer>        Page footers
<header>        Page headers (not article headers)
<template>      HTML templates
```

Remove tag but **keep text content:**

```
<span>          Strip tag, keep text
<div>           Strip tag, keep text (treat as block boundary)
<font>          Strip tag, keep text
<center>        Strip tag, keep text
<big>           Strip tag, keep text
<small>         Strip tag, keep text
<bdi>           Strip tag, keep text
<bdo>           Strip tag, keep text
<wbr>           Strip entirely (optional line break hint)
```

---

## Entities

Decode HTML entities to their Unicode equivalents:

| Entity | Character |
|--------|-----------|
| `&amp;` | `&` |
| `&lt;` | `<` |
| `&gt;` | `>` |
| `&quot;` | `"` |
| `&apos;` | `'` |
| `&nbsp;` | ` ` (regular space, or `\u00A0` → space) |
| `&mdash;` | `—` |
| `&ndash;` | `–` |
| `&hellip;` | `…` |
| `&laquo;` | `«` |
| `&raquo;` | `»` |
| `&#NNN;` | Unicode codepoint NNN |
| `&#xHHH;` | Unicode codepoint 0xHHH |

---

## Edge Cases

### Empty elements

```html
<p></p>             →  (skip — emit nothing)
<li></li>           →  - (empty list item — keep, unusual)
<td></td>           →  |  | (empty cell — keep pipe structure)
```

### Nested blockquotes

```html
<blockquote>
  Outer
  <blockquote>Inner</blockquote>
</blockquote>
→
> Outer
>> Inner
```

### Paragraphs inside list items

```html
<li><p>First paragraph</p><p>Second paragraph</p></li>
→
- First paragraph

  Second paragraph
```

Indent continuation content by 2 spaces (matching bullet width).

### Images inside links

```html
<a href="url"><img src="img.png" alt="alt"></a>
→
[![alt](img.png)](url)
```

### Preformatted text without code

```html
<pre>ASCII art or plain preformatted text</pre>
→
```
ASCII art or plain preformatted text
```
```

(Use bare fenced block with no language specifier.)

### Data URLs

```html
<img src="data:image/png;base64,…">
→  (strip — data URLs do not work in Obsidian or most Markdown renderers)
```

### Mailto links

```html
<a href="mailto:user@example.com">Contact</a>
→  [Contact](mailto:user@example.com)
```

### Escaped Markdown characters in content

If text content contains `[`, `]`, `*`, `_`, `` ` ``, `#`, `\`, `|` as literal
characters (not intended as Markdown), escape them with `\`:

```
text containing [brackets] → text containing \[brackets\]
```

Exception: do NOT escape characters inside code spans or fenced code blocks.
