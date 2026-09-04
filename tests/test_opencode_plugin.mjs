#!/usr/bin/env node
/**
 * Automated test suite for dot_config/opencode/plugins/security-suite.ts
 *
 * Tests:
 * 1. Safe file reads/writes allowed (do not throw).
 * 2. Sensitive file access blocked (throws Error with SECURITY GUARD message).
 * 3. Safe shell commands allowed (do not throw).
 * 4. Dangerous / blocked shell commands blocked (throws Error with SECURITY GUARD message).
 * 5. shell.env hook sets DOTFILES_AI_GUARD = "1" and WORKSPACE_ROOT = directory.
 */

import assert from "node:assert"
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import { spawnSync } from "node:child_process"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const REPO_ROOT = path.resolve(__dirname, "..")
const PLUGIN_PATH = path.join(REPO_ROOT, "dot_config", "opencode", "plugins", "security-suite.ts")

// Helper to load and evaluate security-suite.ts in Node
async function loadSecurityPlugin() {
  const tsContent = fs.readFileSync(PLUGIN_PATH, "utf-8")
  
  // Strip TS types & import statements for pure JS runtime execution
  const jsContent = tsContent
    .replace(/^import\s+.*$/gm, "")
    .replace(/: Plugin\b/g, "")
    .replace(/: string\b/g, "")
    .replace(/: void\b/g, "")
    .replace(/: any\b/g, "")
    .replace(/export const SecuritySuitePlugin/, "const SecuritySuitePlugin") +
    "\nreturn { SecuritySuitePlugin, resolveBinary };"

  const factory = new Function("require", "__dirname", "__filename", "spawnSync", "fs", "os", "path", jsContent)
  const os = await import("node:os")
  const moduleExports = factory(
    (mod) => {
      if (mod === "child_process") return { spawnSync }
      if (mod === "fs") return fs
      if (mod === "os") return os
      if (mod === "path") return path
      throw new Error(`Unexpected require: ${mod}`)
    },
    path.dirname(PLUGIN_PATH),
    PLUGIN_PATH,
    spawnSync,
    fs,
    os,
    path
  )

  return moduleExports.SecuritySuitePlugin
}

async function runTests() {
  console.log("=== Testing OpenCode Security Suite Plugin ===")
  const SecuritySuitePlugin = await loadSecurityPlugin()
  assert(typeof SecuritySuitePlugin === "function", "SecuritySuitePlugin must be a function")

  const mockDirectory = REPO_ROOT
  const plugin = await SecuritySuitePlugin({ directory: mockDirectory })
  assert(plugin["tool.execute.before"], "Plugin must define tool.execute.before hook")
  assert(plugin["shell.env"], "Plugin must define shell.env hook")

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
      const input = { tool: sf.tool }
      const output = { args: sf }
      await plugin["tool.execute.before"](input, output)
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
      const input = { tool: sf.tool }
      const output = { args: sf }
      let threw = false
      try {
        await plugin["tool.execute.before"](input, output)
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
      const input = { tool: sc.tool }
      const output = { args: sc }
      await plugin["tool.execute.before"](input, output)
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
    { tool: "execute_command", command: 'mysql -e "TRUNCATE TABLE users;"' }
  ]

  for (const dc of dangerousCommands) {
    await testCase(`Dangerous command blocked: ${dc.tool} (${dc.command || dc.CommandLine})`, async () => {
      const input = { tool: dc.tool }
      const output = { args: dc }
      let threw = false
      try {
        await plugin["tool.execute.before"](input, output)
      } catch (err) {
        threw = true
        assert(
          err.message.includes("SECURITY GUARD") || err.message.includes("blocked"),
          `Expected SECURITY GUARD error, got: ${err.message}`
        )
      }
      assert(threw, `Expected '${dc.command || dc.CommandLine}' to throw security error`)
    })
  }

  // 5. shell.env hook
  console.log("\n[5] shell.env Hook Tests")
  await testCase("shell.env sets DOTFILES_AI_GUARD and WORKSPACE_ROOT", async () => {
    const output = { env: {} }
    await plugin["shell.env"]({}, output)
    assert.strictEqual(output.env.DOTFILES_AI_GUARD, "1", "DOTFILES_AI_GUARD should be '1'")
    assert.strictEqual(output.env.WORKSPACE_ROOT, mockDirectory, "WORKSPACE_ROOT should match directory")
  })

  console.log(`\n========================================`)
  console.log(`Results: ${passed}/${total} assertions passed!`)
  console.log(`========================================\n`)
}

runTests().catch((err) => {
  console.error("Test suite failed:", err)
  process.exit(1)
})
