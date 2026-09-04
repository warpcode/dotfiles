import { type Plugin } from "@opencode-ai/plugin"
import { spawnSync } from "child_process"
import * as fs from "fs"
import * as os from "os"
import * as path from "path"

function resolveBinary(name: string): string {
  // 1. Check which
  try {
    const whichRes = spawnSync("which", [name], { encoding: "utf-8" })
    if (whichRes.status === 0 && whichRes.stdout.trim()) {
      return whichRes.stdout.trim()
    }
  } catch {
    // Ignore which errors
  }

  // 2. Check ~/.local/bin/<name>
  const localBin = path.join(os.homedir(), ".local", "bin", name)
  if (fs.existsSync(localBin)) {
    return localBin
  }

  // 3. Fallback to repo source scripts if running in repo context
  const repoCandidates = [
    path.resolve(__dirname, "../../dot_local/bin/executable_" + name),
    path.resolve(__dirname, "../../../dot_local/bin/executable_" + name)
  ]
  for (const candidate of repoCandidates) {
    if (fs.existsSync(candidate)) {
      return candidate
    }
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
      }
    },

    "shell.env": async (_input, output) => {
      output.env.DOTFILES_AI_GUARD = "1"
      output.env.WORKSPACE_ROOT = directory
    }
  }
}
