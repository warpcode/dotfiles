import type { Model, Provider } from "@opencode-ai/sdk/v2"
import type { Plugin } from "@opencode-ai/plugin"

// llama.cpp routes by model alias; it has no catalog for opencode to read, so
// the /v1/models list is fetched at startup and mapped into Model objects.
const PROVIDER_ID = "llamacpp"
const DEFAULT_BASE_URL = "http://127.0.0.1:8081/v1"
const FETCH_TIMEOUT_MS = 2000
const DEFAULT_CONTEXT = 8192
const DEFAULT_OUTPUT = 4096

// embedding/rerank/asr/tts/ocr endpoints reject chat completions
const NON_CHAT = /^(embed|rerank|asr|tts|ocr)(-|$)/

const baseURL = (p: Provider) => ((p.options?.baseURL as string) ?? DEFAULT_BASE_URL).replace(/\/$/, "")

function contextSize(raw: any): number {
  const args: string[] = raw.status?.args ?? []
  const i = args.indexOf("--ctx-size")
  const size = i >= 0 ? Number(args[i + 1]) : NaN
  return Number.isFinite(size) && size > 0 ? size : DEFAULT_CONTEXT
}

function outputSize(ctx: number): number {
  return Math.min(DEFAULT_OUTPUT, Math.max(1024, Math.floor(ctx / 4)))
}

function releaseDate(raw: any): string {
  return new Date((raw.created ?? 0) * 1000).toISOString().slice(0, 10)
}

function toModel(raw: any, provider: Provider): Model {
  const input: string[] = raw.architecture?.input_modalities ?? ["text"]
  const ctx = contextSize(raw)
  return {
    id: raw.id,
    providerID: provider.id,
    name: raw.id,
    api: { id: "openai-compatible", url: baseURL(provider), npm: "@ai-sdk/openai-compatible" },
    capabilities: {
      temperature: true,
      reasoning: false,
      attachment: input.includes("image"),
      toolcall: true,
      input: {
        text: input.includes("text"),
        audio: input.includes("audio"),
        image: input.includes("image"),
        video: input.includes("video"),
        pdf: false
      },
      output: { text: true, audio: false, image: false, video: false, pdf: false },
      interleaved: false
    },
    cost: { input: 0, output: 0, cache: { read: 0, write: 0 } },
    limit: { context: ctx, output: outputSize(ctx) },
    status: "active",
    options: {},
    headers: {},
    release_date: releaseDate(raw)
  }
}

const cache = new Map<string, Promise<Record<string, Model>>>()

function fetchModels(provider: Provider): Promise<Record<string, Model>> {
  const cached = cache.get(provider.id)
  if (cached) return cached
  const base = baseURL(provider)
  const pending = fetch(`${base}/models`, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) })
    .then((res) => {
      if (!res.ok) throw new Error(`GET ${base}/models -> ${res.status}`)
      return res.json()
    })
    .then((body) =>
      Object.fromEntries(
        (body.data ?? []).filter((m: any) => m.id && !NON_CHAT.test(m.id)).map((m: any) => [m.id, toModel(m, provider)])
      )
    )
    .catch((err) => {
      cache.delete(provider.id)
      console.error(`llamacpp-models: ${err.message}`)
      return {}
    })
  cache.set(provider.id, pending)
  return pending
}

export const LlamaCppModelsPlugin: Plugin = async () => ({
  provider: {
    id: PROVIDER_ID,
    models: async (provider) => (provider.id === PROVIDER_ID ? await fetchModels(provider) : {})
  },
  config: async (input) => {
    const provider = input?.provider?.llamacpp
    if (!provider) return
    const mapped = await fetchModels(provider)
    provider.models = {}
    for (const [id, m] of Object.entries(mapped)) {
      const modalities = ["text"]
      if (m.capabilities?.input?.image) modalities.push("image")
      provider.models[id] = {
        id,
        name: m.name,
        attachment: m.capabilities?.attachment ?? false,
        reasoning: m.capabilities?.reasoning ?? false,
        temperature: m.capabilities?.temperature ?? true,
        tool_call: m.capabilities?.toolcall ?? true,
        cost: m.cost,
        limit: m.limit,
        modalities: {
          input: modalities,
          output: ["text"]
        }
      }
    }
  }
})

Object.assign(LlamaCppModelsPlugin, { toModel, fetchModels, cache, contextSize, outputSize })
