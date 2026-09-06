import { type Plugin } from "@opencode-ai/plugin"
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

export const SecuritySuitePlugin: Plugin = async ({ directory }) => {
  const aiGuardBin = resolveBinary("df.ai-guard")

  return {
    "tool.execute.before": async (input, output) => {
      const payload = JSON.stringify({
        tool: input.tool,
        args: output.args,
        directory,
        cwd: directory
      })

      // 1. File guard check
      const fileRes = spawnSync(aiGuardBin, ["file"], {
        input: payload,
        encoding: "utf-8"
      })

      if (fileRes.error || fileRes.status !== 0) {
        const msg = fileRes.stderr?.trim() || fileRes.error?.message || "SECURITY GUARD: Access blocked by file guard."
        throw new Error(msg)
      }

      if (fileRes.stdout && fileRes.stdout.trim()) {
        try {
          const data = JSON.parse(fileRes.stdout.trim())
          if (data.decision === "deny") {
            throw new Error(data.reason || "SECURITY GUARD: Access blocked by file guard.")
          }
          if (data.decision === "ask") {
            throw new Error(`SECURITY GUARD: Operation requires manual confirmation: ${data.reason || "Access requires approval."}`)
          }
        } catch (e: any) {
          if (e.message?.startsWith("SECURITY GUARD:")) throw e
        }
      }

      // 2. Command gate check for terminal/command execution tools
      if (COMMAND_TOOLS.has(input.tool)) {
        const cmdRes = spawnSync(aiGuardBin, ["command"], {
          input: payload,
          encoding: "utf-8"
        })

        if (cmdRes.error || cmdRes.status !== 0) {
          const msg = cmdRes.stderr?.trim() || cmdRes.error?.message || "SECURITY GUARD: Command execution blocked by command gate."
          throw new Error(msg)
        }

        if (cmdRes.stdout && cmdRes.stdout.trim()) {
          try {
            const data = JSON.parse(cmdRes.stdout.trim())
            if (data.decision === "deny") {
              throw new Error(data.reason || "SECURITY GUARD: Command execution blocked by command gate.")
            }
            if (data.decision === "ask") {
              throw new Error(`SECURITY GUARD: Operation requires manual confirmation: ${data.reason || "Command requires confirmation."}`)
            }
            if (data.decision === "replace" && (data.command || data.modified || data.CommandLine)) {
              if (output.args && typeof output.args === "object") {
                const rep = data.command || data.modified || data.CommandLine
                if ("command" in output.args) output.args.command = rep
                else if ("CommandLine" in output.args) output.args.CommandLine = rep
                else if ("cmd" in output.args) output.args.cmd = rep
              }
            }
          } catch (e: any) {
            if (e.message?.startsWith("SECURITY GUARD:")) throw e
          }
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (!output || output.result === undefined || output.result === null) {
        return
      }

      const isString = typeof output.result === "string"
      const payload = JSON.stringify({
        tool: input.tool,
        result: output.result,
        output: output.result,
        directory,
        cwd: directory
      })

      const scrubRes = spawnSync(aiGuardBin, ["output"], {
        input: payload,
        encoding: "utf-8"
      })

      if (scrubRes.error || scrubRes.status !== 0) {
        const msg = scrubRes.stderr?.trim() || scrubRes.error?.message || "SECURITY GUARD: Output scrubbing failed."
        throw new Error(msg)
      }

      if (scrubRes.stdout && scrubRes.stdout.trim()) {
        try {
          const data = JSON.parse(scrubRes.stdout.trim())
          if (data.decision === "replace") {
            if (isString) {
              output.result = data.sanitized ?? data.result ?? data.output ?? output.result
            } else if (data.payload && data.payload.result !== undefined) {
              output.result = data.payload.result
            } else if (data.sanitized) {
              try {
                output.result = JSON.parse(data.sanitized)
              } catch {
                output.result = data.sanitized
              }
            }
          }
        } catch (e: any) {
          throw new Error("SECURITY GUARD: Failed to parse sanitized output: " + e.message)
        }
      }
    },

    "shell.env": async (_input, output) => {
      output.env.DOTFILES_AI_GUARD = "1"
      output.env.WORKSPACE_ROOT = directory
    }
  }
}
