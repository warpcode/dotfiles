---
description: >-
  Summarise Pull Requests merged today into main/master branch.
  Generates business-friendly bullet points with emojis.
  Target audience: Non-technical business owners.
---

1. Date: TODAY=!`date +%Y-%m-%d`
2. Query: PRS=!`ghs pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
3. IF $PRS == "none" → Report(No merged PRs today on $TODAY) → EXIT
4. Transform: Each PR → Single sentence, plain English, business benefit-focused
5. Add relevant emoji per PR (🚀 Feature, 🐛 Fix, ⚡ Optimisation, etc.)
6. Output: Formatted bullet list with positive, clear tone
