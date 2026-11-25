# Hermes Agent skill reference

Source: <https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills>

Hermes Agent provides rich runtime extension options, tool gating, and automation directives.

## Top-level frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `version` | No | Semantic version string (e.g. `1.0.0`) |
| `author` | No | Author name, handle, or contact identifier |
| `license` | No | License identifier (e.g. `MIT`, `Apache-2.0`) |
| `platforms` | No | List of supported operating systems: `[macos, linux, windows]`; skill is hidden on non-matching platforms |
| `required_environment_variables` | No | Declared secret variables — prompted securely on load and injected into sandboxes |
| `required_credential_files` | No | Declared credential/token files mounted into execution sandboxes |

### Secret & credential schemas

**`required_environment_variables` item schema:**
- `name` (string, required): Environment variable name (e.g. `GITHUB_TOKEN`, `OPENAI_API_KEY`).
- `prompt` (string): Prompt message presented to the user when the secret is missing.
- `help` (string): Contextual help explaining how to obtain the credential.
- `required_for` (string/list): Specific operations or subcommands requiring the variable.

**`required_credential_files` item schema:**
- `path` (string, required): File path to mount (e.g. `~/.aws/credentials`, `~/.kube/config`).
- `description` (string): Description of the credential file's purpose.

*(Legacy alias: `prerequisites.env_vars`)*

## Options under `metadata.hermes:`

| Key | Required | Purpose |
|---|---|---|
| `tags` | No | List of string tags for categorization and search |
| `related_skills` | No | List of related skill names for cross-linking |
| `requires_toolsets` | No | List of toolsets required for the skill to be available (e.g. `[github, docker]`) |
| `requires_tools` | No | List of specific individual tools that must exist |
| `fallback_for_toolsets` | No | Hide this skill when listed toolsets are present (used for fallback/workaround skills) |
| `fallback_for_tools` | No | Hide this skill when listed tools are present |
| `config` | No | Non-secret settings stored in `config.yaml`, prompted via `hermes config migrate` |
| `blueprint` | No | Marks the skill as a runnable automation or scheduled workflow |

### Configuration & automation schemas

**`config` item schema:**
- `key` (string, required): Configuration key name.
- `description` (string): Explanation of the setting.
- `default` (any): Default value.
- `prompt` (string): Interactive prompt shown during `hermes config migrate`.

**`blueprint` schema:**
- `schedule` (string): Cron expression (e.g. `0 9 * * 1-5`), interval string (e.g. `"every 2h"`), or ISO timestamp.
- `deliver` (string): Output delivery destination (e.g. `telegram`, `discord`, `webhook`, `email`).
- `prompt` (string): Autonomous prompt string executed on schedule.
- `no_agent` (boolean): `true` = run deterministically without interactive agent reasoning.

### Frontmatter examples

**Skill with required secrets, platform gating, and toolset dependencies:**

```yaml
---
version: "1.2.0"
author: ops-guild
license: Apache-2.0
platforms:
  - linux
  - macos
required_environment_variables:
  - name: GITHUB_TOKEN
    prompt: "Enter your GitHub Personal Access Token:"
    help: "Needed for cloning private repositories and creating pull requests."
    required_for: "all operations"
required_credential_files:
  - path: ~/.aws/credentials
    description: "AWS credentials for staging deployment"
metadata:
  hermes:
    tags: [ci, github, deployment]
    related_skills: [git-expert, docker-build]
    requires_toolsets: [github, docker]
    config:
      - key: default_environment
        description: "Default target deployment environment"
        default: "staging"
        prompt: "Choose deployment target (staging/production):"
---
```

**Autonomous scheduled workflow (blueprint):**

```yaml
---
version: "2.0.0"
author: sre-team
metadata:
  hermes:
    tags: [monitoring, backup]
    blueprint:
      schedule: "0 2 * * *"
      deliver: telegram
      prompt: "Run database backup verification and report health status."
      no_agent: false
---
```

## Body features & runtime directives

- **Path & session substitutions**: `${HERMES_SKILL_DIR}` (directory containing the skill), `${HERMES_SESSION_ID}` (current session ID).
- **Inline dynamic command injection**: `` !`command` `` executes shell command and injects output into the prompt (opt-in).
- **Media delivery directive**: `[[as_document]]` delivers generated output file as an attachment rather than inline chat text.

