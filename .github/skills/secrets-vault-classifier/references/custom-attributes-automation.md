# Custom Attribute Schemas for KeePass Automation

Tags filter **which** KeePass/KeePassXC entries to extract; built-in fields and Custom Attributes provide the structured key-value metadata required to render configuration files and environment hydration payloads.

---

## 1. SSH Config Generation (`type:userpass` + `proto:ssh` + `app:ssh-config`)

Extracted from user account entries to generate `~/.ssh/config` stanzas. Individual host logins reference a standalone `type:keypair` entry via `SSH_IdentityFile` or `{REF:...}`.

| Field | Kind | Purpose / Example |
|---|---|---|
| `UserName` | Built-in | Remote SSH login user (e.g. `root`, `jason`) |
| `Password` | Built-in | Account password for login or `sudo` elevation (may be empty if key-only) |
| `URL` | Built-in | `ssh://hostname-or-ip:port` or raw IP/FQDN |
| `SSH_Host` | Custom | Host alias in `~/.ssh/config` (e.g. `pve-01`); defaults to sanitised `Title` if omitted |
| `SSH_IdentityFile` | Custom | Path to local private key (e.g. `~/.ssh/id_ed25519_homelab`) |
| `SSH_ProxyJump` | Custom *(optional)* | Bastion host alias |

---

## 2. OpenAI / LLM API Registration (`type:token` + `spec:openai`)

Extracted for tools such as LiteLLM, OpenHands, or local routing proxies.

| Field | Kind | Purpose / Example |
|---|---|---|
| `Password` | Built-in | API secret key (`sk-...`) |
| `URL` | Built-in | Base API endpoint (e.g. `https://api.openai.com/v1`, `https://openrouter.ai/api/v1`) |
| `LLM_Provider` | Custom | Provider identifier for router config (e.g. `openai`, `openrouter`, `groq`, `anthropic`) |
| `LLM_Models` | Custom *(optional)* | Comma-separated list of exposed model IDs |

---

## 3. Generic `.env` & Homelab Config Hydration (`app:<stack-name>` or `app:dotenv`)

Used by stack hydrators (`df.config` / `df.keepass`) to map vault entries into environment variables.

| Field | Kind | Purpose / Example |
|---|---|---|
| `ENV_VAR` | Custom | Target environment variable name for single-secret `type:token` entries (e.g. `CF_DNS_API_TOKEN`) |
| `ENV_MAP` | Custom *(optional for `type:userpass`)* | Comma-separated field-to-env mapping (e.g. `UserName=DB_USER,Password=DB_PASS,URL=DB_HOST`) |

---

## 4. Cryptographic Key Metadata (`type:keypair`)

Metadata describing standalone cryptographic key material stored once in the vault.

| Field | Kind | Purpose / Example |
|---|---|---|
| `Algorithm` | Custom *(MUST include)* | Cryptographic algorithm (`Ed25519`, `RSA-4096`, `ECDSA`, `Curve25519`, `GPG`) |
