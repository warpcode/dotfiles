# Obsidian Web-Clipping Conventions

Apply these rules when HTML-to-Markdown output targets an Obsidian vault. For HTML element/callout conversion rules and `defuddle` metadata extraction pipelines, see `@references/element-mapping.md` and `@references/defuddle-options.md`.

---

## Inline & Block Extensions

- **Highlights**: `<mark>text</mark>` -> `==text==`
- **Callouts**: Convert GitHub Markdown alerts and alert divs to `> [!type]` syntax per `@references/element-mapping.md` §Callouts.
- **Wikilinks**: Do NOT alter existing `[[...]]` links.

---

## Clipping Frontmatter Schema

Prepend a YAML frontmatter block when page metadata is available, using this exact structure:

```yaml
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
```

### Metadata Field Rules

- **title**: Article title, double-quoted.
- **source**: Canonical article URL, double-quoted.
- **author**: List of authors formatted as double-quoted Obsidian wikilinks (e.g., `- "[[Rachel Flynn]]"`). Split comma-separated names, `"and"`, or list items into separate list items. If no author is found, omit the field or use `[]`.
- **published**: Publication date in `YYYY-MM-DD` format.
- **created**: Note creation date in `YYYY-MM-DD` format.
- **description**: Concise article summary/description, double-quoted.
- **tags**: YAML list containing `- "clippings"` by default.
