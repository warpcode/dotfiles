import { type Plugin } from "@opencode-ai/plugin"

export const SecurityGuardPlugin: Plugin = async ({ directory }) => {
  const PROTECTED_PATTERNS = [/\.env($|\.)/, /\.pem$/, /id_rsa/, /credentials\.json/]

  return {
    "tool.execute.before": async (input, output) => {
      // 1. Protect secrets from file reads and edits
      const targetPath = output.args?.filePath || output.args?.path || ""
      if (typeof targetPath === "string" && PROTECTED_PATTERNS.some((re) => re.test(targetPath))) {
        throw new Error(`SECURITY POLICY: Access to sensitive file '${targetPath}' is forbidden.`)
      }

      // 2. Intercept destructive bash commands
      if (input.tool === "bash" || input.tool === "execute_command") {
        const cmd = String(output.args?.command || "")
        if (/(rm\s+-rf\s+[/~]|DROP\s+TABLE|DELETE\s+FROM)/i.test(cmd)) {
          throw new Error(`CRITICAL GUARD: Destructive shell command was blocked: ${cmd}`)
        }
      }
    },

    "shell.env": async (_input, output) => {
      output.env.WORKSPACE_ROOT = directory
    }
  }
}
