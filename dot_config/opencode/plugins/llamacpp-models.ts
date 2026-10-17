// llama.cpp routes by model alias; it has no catalog for opencode to read, so
// the /v1/models list is fetched and published as an OpenCode provider source.
//
// OpenCode 2 plugin API: a plugin default-exports a definition with a stable
// `id` and a `setup(ctx)`. `ctx.provider.transform` contributes provider
// definitions and their model inventory; transforms are replayed on every
// registry rebuild, so the callback is synchronous and only publishes state
// captured beforehand.
//
// No imports on purpose: the loader only requires `{ default: { id, setup } }`,
// so this stays loadable without a `@opencode/plugin` dependency. The shapes
// below mirror the ProviderEditor and Model.Info schemas.

const PROVIDER_ID = "llamacpp"
const PROVIDER_NAME = "llama.cpp (local)"
const PACKAGE = "@opencode/ai/providers/openai-compatible"
const DEFAULT_BASE_URL = "http://127.0.0.1:8081/v1"
const FETCH_TIMEOUT_MS = 2000
const DEFAULT_CONTEXT = 8192
const DEFAULT_OUTPUT = 4096
const MIN_OUTPUT = 1024
const REFRESH_INTERVAL_MS = 60_000

// llama-server's /v1/models lists routing endpoints alongside models; the
// embedding/rerank/asr/tts/ocr families reject chat completions.
const NON_CHAT = /^(embed|rerank|asr|tts|ocr)(-|$)/

const FREE = { input: 0, output: 0, cache: { read: 0, write: 0 } }

function positive(value: unknown): number | undefined {
  const n = Number(value)
  return Number.isFinite(n) && n > 0 ? n : undefined
}

function argValue(args: readonly string[], flag: string): number | undefined {
  const i = args.indexOf(flag)
  return i < 0 ? undefined : positive(args[i + 1])
}

function flagEnabled(args: readonly string[], flag: string): boolean {
  const i = args.indexOf(flag)
  if (i < 0) return false
  const value = args[i + 1]
  return value === undefined || !value.startsWith("-") ? value !== "off" : true
}

// The context the server will actually serve, not the model's ceiling:
//   1. the entry's own `--ctx-size` — routing endpoints (chat, code, fim) each
//      carry one, e.g. chat 131072 vs fim 16384
//   2. the entry's `context_length` — the ceiling of the GGUF it routes to
// bounded by `--fit-ctx` whenever `--fit` is on: llama.cpp then shrinks the
// allocation to what fits, and this server also runs --no-context-shift, so an
// over-reported limit becomes a hard request failure rather than a truncation.
function contextSize(raw: any): number {
  const args: readonly string[] = raw.status?.args ?? []
  const declared = argValue(args, "--ctx-size") ?? positive(raw.context_length)
  const fit = flagEnabled(args, "--fit") ? argValue(args, "--fit-ctx") : undefined
  if (declared && fit) return Math.min(declared, fit)
  return declared ?? fit ?? DEFAULT_CONTEXT
}

// llama-server reports no max-output field and defaults -np to unlimited, so
// this is a cap, not a measurement: a quarter of the served context, between
// 1024 and DEFAULT_OUTPUT.
function outputSize(ctx: number): number {
  return Math.min(DEFAULT_OUTPUT, Math.max(MIN_OUTPUT, Math.floor(ctx / 4)))
}

function releasedAt(raw: any): number {
  // Model.Info.time.released is milliseconds since the Unix epoch.
  const created = Number(raw.created)
  return Number.isFinite(created) && created > 0 ? created * 1000 : 0
}

function toModel(raw: any): ModelInfo {
  const id = String(raw.id)
  const input: string[] = Array.isArray(raw.architecture?.input_modalities) ? raw.architecture.input_modalities : ["text"]
  const output: string[] = Array.isArray(raw.architecture?.output_modalities) ? raw.architecture.output_modalities : ["text"]
  const ctx = contextSize(raw)
  return {
    id,
    modelID: id,
    providerID: PROVIDER_ID,
    name: id,
    capabilities: { tools: true, input, output, temperature: true },
    variants: [],
    time: { released: releasedAt(raw) },
    cost: [{ ...FREE }],
    status: "active",
    enabled: true,
    limit: { context: ctx, output: outputSize(ctx) }
  }
}

async function fetchModels(baseURL: string): Promise<ModelInfo[]> {
  const base = baseURL.replace(/\/$/, "")
  const res = await fetch(`${base}/models`, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) })
  if (!res.ok) throw new Error(`GET ${base}/models -> ${res.status}`)
  const body: any = await res.json()
  return (body.data ?? []).filter((m: any) => m.id && !NON_CHAT.test(m.id)).map(toModel)
}

function sameInventory(a: readonly ModelInfo[], b: readonly ModelInfo[]): boolean {
  return a.length === b.length && a.every((m, i) => m.id === b[i]?.id && m.limit.context === b[i]?.limit.context)
}

export default {
  id: "llamacpp-models",

  async setup(ctx: any) {
    // Prefer an endpoint already configured for this provider id, then a plugin
    // option, then the built-in default.
    const resolveBaseURL = async () => {
      const existing: any = await ctx.provider.get({ providerID: PROVIDER_ID }).catch(() => undefined)
      const configured = existing?.settings?.baseURL ?? ctx.options?.baseURL
      return typeof configured === "string" && configured ? configured : DEFAULT_BASE_URL
    }

    const state: { baseURL: string; models: readonly ModelInfo[] } = { baseURL: DEFAULT_BASE_URL, models: [] }

    const load = async () => {
      try {
        const baseURL = await resolveBaseURL()
        const models = await fetchModels(baseURL)
        if (state.baseURL === baseURL && sameInventory(state.models, models)) return
        state.baseURL = baseURL
        state.models = models
        // Captured inputs are not watched; reload replays the transform.
        await ctx.provider.reload()
      } catch (err: any) {
        // llama-server may not be up yet, or may be restarting. Keep the last
        // good inventory and retry on the next tick.
        console.error(`llamacpp-models: ${err?.message ?? err}`)
      }
    }

    await load()

    // Synchronous, replayable edit: publishes only already-fetched state.
    await ctx.provider.transform((editor: any) => {
      if (state.models.length === 0) return
      if (editor.get(PROVIDER_ID)) {
        editor.models.set(PROVIDER_ID, state.models)
        return
      }
      editor.add({
        info: {
          id: PROVIDER_ID,
          name: PROVIDER_NAME,
          activation: "enabled",
          package: PACKAGE,
          settings: { baseURL: state.baseURL, apiKey: "local" }
        },
        models: state.models
      })
    })

    const timer = setInterval(() => void load(), REFRESH_INTERVAL_MS)
    timer.unref?.()
    return () => clearInterval(timer)
  }
}

// Local structural types, kept loose to avoid a hard dependency on the SDK.
type ModelInfo = {
  id: string
  modelID: string
  providerID: string
  name: string
  capabilities: { tools: boolean; input: string[]; output: string[]; temperature?: boolean }
  variants: unknown[]
  time: { released: number }
  cost: Array<{ input: number; output: number; cache: { read: number; write: number } }>
  status: "alpha" | "beta" | "deprecated" | "active"
  enabled: boolean
  limit: { context: number; output: number }
}