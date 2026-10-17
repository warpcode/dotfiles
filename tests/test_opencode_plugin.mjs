#!/usr/bin/env node
/**
 * Automated test suite for dot_config/opencode/plugins/security-suite.ts
 *
 * Exercises the real df.ai-guard binary through the OpenCode 2 plugin API: the
 * default export's setup(ctx) registers one hook per operation, and each hook
 * receives a single mutable event.
 *
 * Tests:
 * 1. Safe file reads/writes allowed (do not throw).
 * 2. Sensitive file access blocked (throws Error with SECURITY GUARD message).
 * 3. Safe shell commands allowed (do not throw).
 * 4. Dangerous / blocked shell commands blocked (throws Error with SECURITY GUARD message).
 * 5. shell create.before hook sets DOTFILES_AI_GUARD = "1" and WORKSPACE_ROOT = directory.
 * 6. execute.after scrubs secrets out of tool output.
 */

import assert from "node:assert"
import path from "node:path"
import { fileURLToPath } from "node:url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const REPO_ROOT = path.resolve(__dirname, "..")
const PLUGIN_PATH = path.join(REPO_ROOT, "dot_config", "opencode", "plugins", "security-suite.ts")

// OpenCode runs plugins under Bun, which supplies __dirname to modules. Node's
// ESM loader does not, so provide it before setup() calls resolveBinary().
globalThis.__dirname = path.dirname(PLUGIN_PATH)
globalThis.__filename = PLUGIN_PATH

const plugin = (await import(PLUGIN_PATH)).default

// Collects the hooks a plugin registers, standing in for the plugin context.
async function loadHooks(directory) {
  const tool = {}
  const shell = {}
  const ctx = {
    location: { directory },
    tool: { hook: async (name, callback) => ((tool[name] = callback), { dispose: async () => {} }) },
    shell: { hook: async (name, callback) => ((shell[name] = callback), { dispose: async () => {} }) }
  }
  await plugin.setup(ctx)
  assert.equal(typeof plugin.id, "string", "plugin must expose an id")
  assert.equal(typeof tool["execute.before"], "function", "plugin must register tool execute.before")
  assert.equal(typeof tool["execute.after"], "function", "plugin must register tool execute.after")
  assert.equal(typeof shell["create.before"], "function", "plugin must register shell create.before")
  return { before: tool["execute.before"], after: tool["execute.after"], shell: shell["create.before"] }
}

async function runTests() {
  console.log("=== Testing OpenCode Security Suite Plugin ===")
  const mockDirectory = REPO_ROOT
  const hooks = await loadHooks(mockDirectory)
  const before = (tool, input) => hooks.before({ tool, input })

  let passed = 0
  let total = 0

  async function testCase(name, fn) {
    total++
    try {
      await fn()
      console.log(`  ✓ ${name}`)
      passed++
    } catch (err) {
      console.error(`  ✗ ${name}: ${err.message}`)
      throw err
    }
  }

  // 1. Safe file reads/writes
  console.log("\n[1] Safe File Access Tests (Allowed)")
  const safeFiles = [
    { tool: "read", path: "README.md" },
    { tool: "read", path: "src/app.ts" },
    { tool: "write", path: "src/app.ts", content: "console.log('hello')" },
    { tool: "edit", path: "README.md" },
    { tool: "view_file", AbsolutePath: path.join(mockDirectory, "README.md") }
  ]

  for (const sf of safeFiles) {
    await testCase(`Safe access allowed: ${sf.tool} (${sf.path || sf.AbsolutePath})`, async () => {
      await before(sf.tool, sf)
    })
  }

  // 2. Sensitive file access blocked
  console.log("\n[2] Sensitive File Access Tests (Blocked)")
  const sensitiveFiles = [
    { tool: "read", path: ".env" },
    { tool: "read", path: "~/.ssh/id_rsa" },
    { tool: "read", path: "Accounts.kdbx" },
    { tool: "write", path: "cert.key", content: "secret" },
    { tool: "edit", path: ".env.local" },
    { tool: "view_file", AbsolutePath: "/etc/ssl/server.pem" }
  ]

  for (const sf of sensitiveFiles) {
    await testCase(`Sensitive file blocked: ${sf.tool} (${sf.path || sf.AbsolutePath})`, async () => {
      let threw = false
      try {
        await before(sf.tool, sf)
      } catch (err) {
        threw = true
        assert(
          err.message.includes("SECURITY GUARD") || err.message.includes("blocked"),
          `Expected SECURITY GUARD in error message, got: ${err.message}`
        )
      }
      assert(threw, `Expected ${sf.path || sf.AbsolutePath} to throw security error`)
    })
  }

  // 3. Safe shell commands
  console.log("\n[3] Safe Shell Command Tests (Allowed)")
  const safeCommands = [
    { tool: "bash", command: "git status" },
    { tool: "bash", command: "ls -la" },
    { tool: "bash", command: "git diff" },
    { tool: "runTerminalCommand", command: "git log -n 5 --oneline" },
    { tool: "execute_command", command: "pwd" },
    { tool: "run_command", CommandLine: "git status -s" }
  ]

  for (const sc of safeCommands) {
    await testCase(`Safe command allowed: ${sc.tool} (${sc.command || sc.CommandLine})`, async () => {
      await before(sc.tool, sc)
    })
  }

  // 4. Dangerous / blocked shell commands
  console.log("\n[4] Dangerous / Blocked Shell Command Tests (Blocked)")
  const dangerousCommands = [
    { tool: "bash", command: "rm -rf /" },
    { tool: "bash", command: 'psql -c "DROP DATABASE production;"' },
    { tool: "bash", command: "cat ~/.ssh/id_rsa" },
    { tool: "runTerminalCommand", command: "cat .env" },
    { tool: "terminal", command: "rm -rf ~" },
    { tool: "run_command", CommandLine: "rm -rf /" },
    { tool: "bash", command: "git push origin --force-with-lease" },
    { tool: "execute_command", command: 'mysql -e "TRUNCATE TABLE users;"' }
  ]

  for (const dc of dangerousCommands) {
    await testCase(`Dangerous/unconfirmed command blocked: ${dc.tool} (${dc.command || dc.CommandLine})`, async () => {
      let threw = false
      try {
        await before(dc.tool, dc)
      } catch (err) {
        threw = true
        assert(
          err.message.includes("SECURITY GUARD") || err.message.includes("blocked") || err.message.includes("confirmation"),
          `Expected SECURITY GUARD error, got: ${err.message}`
        )
      }
      assert(threw, `Expected '${dc.command || dc.CommandLine}' to throw security error`)
    })
  }

  // 5. shell create.before hook
  console.log("\n[5] shell create.before Hook Tests")
  await testCase("shell create.before sets DOTFILES_AI_GUARD and WORKSPACE_ROOT", async () => {
    const event = { command: "ls", cwd: mockDirectory, timeout: 1000, shell: "bash", env: {} }
    await hooks.shell(event)
    assert.strictEqual(event.env.DOTFILES_AI_GUARD, "1", "DOTFILES_AI_GUARD should be '1'")
    assert.strictEqual(event.env.WORKSPACE_ROOT, mockDirectory, "WORKSPACE_ROOT should match directory")
  })

  // 6. execute.after output scrubbing
  console.log("\n[6] execute.after Output Scrubbing Tests")
  const scrub = async (result) => {
    const event = { tool: "bash", status: "completed", result }
    await hooks.after(event)
    return event.result
  }

  await testCase("scrubs leaked API keys from tool output", async () => {
    const result = await scrub("Process completed. Secret key: sk-proj-1234567890abcdef1234567890")
    assert(!result.includes("sk-proj-1234567890abcdef1234567890"), "Raw secret key should be redacted")
    assert(result.includes("[REDACTED_SECRET_OPENAI_API_KEY]"), "Should contain redacted placeholder")
  })

  await testCase("scrubs multiline private keys completely from tool output", async () => {
    const result = await scrub(
      "Key:\n-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAA...\n-----END OPENSSH PRIVATE KEY-----"
    )
    assert(!result.includes("-----BEGIN OPENSSH PRIVATE KEY-----"), "Header should be removed")
    assert(!result.includes("b3BlbnNzaC1rZXktdjEAAAA..."), "Private key body should be redacted")
    assert(result.includes("[REDACTED_PRIVATE_KEY]"), "Should contain redacted placeholder")
  })

  await testCase("scrubs secrets in structured object tool outputs", async () => {
    const result = await scrub({ message: "Auth failed", token: "ghp_1234567890abcdefghijklmnopqrstuvwxyz" })
    assert(!JSON.stringify(result).includes("ghp_1234567890abcdefghijklmnopqrstuvwxyz"), "Raw token should be redacted")
    assert(JSON.stringify(result).includes("[REDACTED_SECRET_GITHUB_TOKEN]"), "Should contain redacted token placeholder")
  })

  await testCase("preserves safe tool output without modification", async () => {
    assert.strictEqual(await scrub("All 15 tests passed successfully."), "All 15 tests passed successfully.")
  })

  console.log(`\n========================================`)
  console.log(`Results: ${passed}/${total} assertions passed!`)
  console.log(`========================================\n`)
}

runTests().catch((err) => {
  console.error("Test suite failed:", err)
  process.exit(1)
})