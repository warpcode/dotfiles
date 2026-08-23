# OpenCode Rule & Instruction Reference

Source: <https://opencode.ai/docs/configuration>

OpenCode provides persistent project guidance through `AGENTS.md`, multi-file glob importing via `opencode.json`, and dynamic rule injection via TypeScript plugins.

---

## 1. File Locations & Hierarchy

| Scope | Path | Purpose |
|---|---|---|
| **Project House Rules** | `AGENTS.md` (project root) | Primary project conventions, build commands, and rules |
| **Directory Rules** | `<sub-dir>/AGENTS.md` | Specific guidelines applied when operating in subdirectories |
| **Compatibility Fallback** | `CLAUDE.md` | Fallback memory loaded if `AGENTS.md` is not present |
| **User Global Rules** | `~/.config/opencode/AGENTS.md` | Global preferences applied across all OpenCode sessions |

---

## 2. Multi-Rule Loading via `opencode.json`

OpenCode can import external rule and instruction files across the workspace using the `instructions` array in `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "docs/architecture.md",
    ".github/instructions/*.instructions.md",
    ".cursor/rules/*.mdc"
  ],
  "permissions": {
    "read": "allow",
    "edit": "allow",
    "bash": {
      "npm test": "allow",
      "git status": "allow",
      "rm -rf *": "deny",
      "*": "ask"
    }
  }
}
```

- Paths in `instructions` can reference local files, globs, or remote URLs.
- OpenCode concatenates these files into the initial context window.

---

## 3. Simulating Path-Scoped Rules via TypeScript Plugins

For advanced path-scoped rule injection that only loads when specific files are edited, OpenCode supports **TypeScript plugins** in `.opencode/plugins/`:

### Plugin Example (`.opencode/plugins/scoped-rules.ts`)

```typescript
import { Plugin, PluginContext } from '@opencode/plugin-api';
import * as fs from 'fs';
import * as path from 'path';

export default class ScopedRulesPlugin implements Plugin {
  name = 'scoped-rules-injector';

  async onPrePrompt(context: PluginContext) {
    const activeFile = context.session.activeFile;
    if (!activeFile) return;

    if (activeFile.endsWith('.ts') || activeFile.endsWith('.tsx')) {
      const rulePath = path.join(context.workspaceRoot, '.github/instructions/typescript.instructions.md');
      if (fs.existsSync(rulePath)) {
        const ruleContent = fs.readFileSync(rulePath, 'utf-8');
        context.injectContextSnippet({
          title: 'TypeScript Scoped Rules',
          content: ruleContent
        });
      }
    }
  }
}
```

For complete recipes and hook patterns, see [references/hooks-and-simulation.md](../hooks-and-simulation.md).
