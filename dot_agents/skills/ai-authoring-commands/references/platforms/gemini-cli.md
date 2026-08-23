# Gemini CLI Commands Reference

Source: <https://antigravity.google/docs/cli>

Gemini CLI defines slash commands declaratively using TOML files.

---

## 1. Locations & Discovery

- **Project / Workspace**: `.gemini/commands/<name>.toml`
- **Global / User**: `~/.gemini/commands/<name>.toml`
- **Namespaces**: Nested subdirectories namespace commands (e.g. `.gemini/commands/git/commit.toml` $\rightarrow$ `/git:commit`).

---

## 2. TOML Schema

```toml
description = "Explain a shell command or code block"
prompt = """
Please provide a clear, concise technical explanation of the following:

{{args}}

Highlight:
1. Core intent and logic flow
2. Performance and safety considerations
3. Potential failure modes
"""
```

---

## 3. Parameter Interpolation

- **`{{args}}`**: Interpolates the argument string passed after the slash command.
