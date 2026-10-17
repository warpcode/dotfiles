// df.ai-guard enforcement for OpenCode 2.
//
// OpenCode 2 plugin API: the plugin default-exports a definition with a stable
// `id`, and `setup(ctx)` registers each hook on the domain that owns the
// operation it intercepts. V1 returned one object keyed by hook name; V2 passes
// a single mutable event per hook, so the guard now inspects `event.input`,
// `event.result` and `event.env` instead of the old `(input, output)` pair.
//
// The guard's own decision protocol is unchanged: each check feeds a JSON
// payload to the binary on stdin and reads back `{ decision, ... }`, where
// deny/ask throw to block the tool and replace rewrites in place.
//
// No `@opencode/plugin` import on purpose: the loader only needs a default
// export with an `id` and a `setup(ctx)`, so the plugin stays loadable by the
// loader and directly by the Node test suite. `Plugin.define` is typing sugar
// over the same shape.

import { spawnSync } from "child_process"
import * as fs from "fs"
import * as os from "os"
import * as path from "path"

function resolveBinary(name: string): string {
  // 1. Check repo source scripts first if running in repo context
  const repoCandidates = [
    path.resolve(__dirname, "../../dot_local/bin/executable_" + name),
    path.resolve(__dirname, "../../../dot_local/bin/executable_" + name)
  ]
  for (const candidate of repoCandidates) {
    if (fs.existsSync(candidate)) {
      return candidate
    }
  }

  // 2. Check which
  try {
    const whichRes = spawnSync("which", [name], { encoding: "utf-8" })
    if (whichRes.status === 0 && whichRes.stdout.trim()) {
      return whichRes.stdout.trim()
    }
  } catch {
    // Ignore which errors
  }

  // 3. Check ~/.local/bin/<name>
  const localBin = path.join(os.homedir(), ".local", "bin", name)
  if (fs.existsSync(localBin)) {
    return localBin
  }

  return name
}

const COMMAND_TOOLS = new Set([
  "bash",
  "execute_command",
  "runTerminalCommand",
  "terminal",
  "run_command",
  "sh",
  "zsh",
  "shell",
  "exec"
])

const GUARD = "SECURITY GUARD"

// Runs one guard check. `strict` controls how a non-JSON reply is treated:
// the file and command gates have always ignored unparseable output and let the
// call through, while the output scrubber refuses to ship an unsanitised result.
function runGuard(bin: string, kind: "file" | "command" | "output", payload: unknown) {
  const res = spawnSync(bin, [kind], { input: JSON.stringify(payload), encoding: "utf-8" })
  if (res.error || res.status !== 0) {
    throw new Error(res.stderr?.trim() || `${GUARD}: ${kind} check failed.`)
  }
  const stdout = res.stdout?.trim()
  if (!stdout) return undefined
  try {
    return JSON.parse(stdout)
  } catch (err: any) {
    if (kind === "output") throw new Error(`${GUARD}: Failed to parse sanitized output: ${err.message}`)
    return undefined
  }
}

function assertAllowed(data: any, kind: string) {
  if (data?.decision === "deny") {
    throw new Error(data.reason || `${GUARD}: Access blocked by ${kind} guard.`)
  }
  if (data?.decision === "ask") {
    throw new Error(data.reason || `${GUARD}: ${kind} requires manual confirmation.`)
  }
}

// The guard may hand back the replacement result as JSON text; keep the raw
// string when it is not JSON so nothing is lost.
function parseOrKeep(value: string): unknown {
  try {
    return JSON.parse(value)
  } catch {
    return value
  }
}

// Writes scrubbed text into a tool result's content, preserving its shape.
// `content` is either a string or an array of parts; a guard scrubs text, it
// does not re-partition mixed content, so the first text part takes the text
// and any further text parts are blanked.
function scrubContent(result: any, text: string): any {
  if (!result || typeof result !== "object") return text
  const content = result.content
  if (typeof content === "string") {
    result.content = text
    return result
  }
  if (Array.isArray(content)) {
    let written = false
    for (const part of content) {
      if (part?.type !== "text") continue
      part.text = written ? "" : text
      written = true
    }
    if (!written) content.unshift({ type: "text", text })
    return result
  }
  result.content = text
  return result
}

export default {
  id: "security-suite",

  async setup(ctx) {
    const aiGuardBin = resolveBinary("df.ai-guard")
    const directory = ctx.location.directory

    await ctx.tool.hook("execute.before", (event) => {
      const payload = { tool: event.tool, args: event.input, directory, cwd: directory }

      // 1. File guard check
      assertAllowed(runGuard(aiGuardBin, "file", payload), "file")

      // 2. Command gate check for terminal/command execution tools
      if (!COMMAND_TOOLS.has(event.tool)) return
      const decision = runGuard(aiGuardBin, "command", payload)
      assertAllowed(decision, "command")

      if (decision?.decision === "replace") {
        const replacement = decision.command ?? decision.modified ?? decision.CommandLine
        const input = event.input as Record<string, any> | undefined
        if (replacement && input && typeof input === "object") {
          for (const key of ["command", "modified", "cmd"]) {
            if (key in input) {
              input[key] = replacement
              return
            }
          }
        }
      }
    })

    await ctx.tool.hook("execute.after", (event) => {
      if (event.status !== "completed" || event.result === undefined || event.result === null) return

      const result = event.result as any
      const decision = runGuard(aiGuardBin, "output", { tool: event.tool, result, output: result, directory, cwd: directory })
      if (decision?.decision !== "replace") return

      // The guard replies with the scrubbed text, and with a whole replacement
      // result when the incoming one was structured. A text result keeps its
      // shape; a structured result is replaced rather than wrapped.
      const text = decision.sanitized ?? decision.output ?? decision.command ?? decision.modified
      if (typeof result === "string") {
        if (text !== undefined) event.result = text
        return
      }

      const structured = decision.payload?.result ?? decision.overwrite?.result
      if (structured !== undefined) {
        event.result = typeof structured === "string" ? parseOrKeep(structured) : structured
        return
      }
      if (text !== undefined) event.result = scrubContent(result, text)
    })

    await ctx.shell.hook("create.before", (event) => {
      event.env.DOTFILES_AI_GUARD = "1"
      event.env.WORKSPACE_ROOT = directory
    })
  }
}