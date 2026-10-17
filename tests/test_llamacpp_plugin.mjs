#!/usr/bin/env node
/**
 * Test suite for dot_config/opencode/plugins/llamacpp-models.ts
 *
 * The plugin maps llama.cpp's /v1/models payload into OpenCode 2 provider
 * source definitions. fetch is stubbed and a fake ctx stands in for the plugin
 * context, so nothing needs a running llama-server.
 *
 * Context limits follow what the server will actually serve: the entry's own
 * --ctx-size (routing endpoints set one each), else its context_length, bounded
 * by --fit-ctx while --fit is on.
 */

import assert from "node:assert"
import plugin from "../dot_config/opencode/plugins/llamacpp-models.ts"

const ARGS_FIT = ["llama-server", "--fit", "on", "--fit-ctx", "16384"]

const PAYLOAD = {
  data: [
    // routing endpoint with its own explicit --ctx-size and --parallel 2 (65536 per slot)
    {
      id: "chat",
      created: 1792002408,
      architecture: { input_modalities: ["text"], output_modalities: ["text"] },
      status: { args: [...ARGS_FIT, "--ctx-size", "131072", "--parallel", "2"] }
    },
    // GGUF routed by alias: no --ctx-size, ceiling from context_length bounded by --fit-ctx
    {
      id: "Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF:Q4_K_M",
      created: 1792002408,
      architecture: { input_modalities: ["text"], output_modalities: ["text"] },
      context_length: 32768,
      status: { args: ARGS_FIT }
    },
    {
      id: "small-model",
      created: 1792002408,
      architecture: { input_modalities: ["text", "image"], output_modalities: ["text"] },
      context_length: 4096,
      status: { args: ["llama-server"] }
    },
    // loaded model exposing meta.n_ctx directly
    {
      id: "code",
      created: 1792002408,
      architecture: { input_modalities: ["text"] },
      meta: { n_ctx: 65536, n_ctx_train: 131072 },
      status: { args: ["llama-server", "--fit", "on", "--fit-ctx", "16384", "--ctx-size", "131072", "--parallel", "2"] }
    },
    // nothing to go on at all
    { id: "mystery", created: 1792002408, architecture: { input_modalities: ["text"] }, status: { args: ["llama-server"] } },
    { id: "embed-tiny", architecture: { input_modalities: ["text"] }, status: { args: [] } }
  ]
}

function stubFetch(body, ok = true) {
  globalThis.fetch = async () => ({
    ok,
    status: ok ? 200 : 500,
    json: async () => body
  })
}

function fakeCtx({ existing, options } = {}) {
  const transforms = []
  let reloads = 0
  return {
    options,
    transforms,
    reloads: () => reloads,
    provider: {
      get: async () => existing,
      reload: async () => {
        reloads++
      },
      transform: async (callback) => {
        transforms.push(callback)
        return { dispose: async () => {} }
      }
    }
  }
}

function fakeEditor(existingProviderID) {
  const added = []
  const sets = []
  return {
    added,
    sets,
    publish(transform) {
      transform({
        get: (id) => (id === existingProviderID ? { provider: {}, models: new Map() } : undefined),
        add: (value) => added.push(value),
        models: { set: (providerID, models) => sets.push({ providerID, models }) }
      })
    }
  }
}

// Runs setup against a stubbed server and returns the models it would publish.
async function publish({ body = PAYLOAD, ok = true, existing, options } = {}) {
  stubFetch(body, ok)
  const ctx = fakeCtx({ existing, options })
  const cleanup = await plugin.setup(ctx)
  const editor = fakeEditor(existing?.id)
  ctx.transforms.forEach((transform) => editor.publish(transform))
  cleanup?.()
  return { models: editor.added[0]?.models ?? editor.sets[0]?.models ?? [], provider: editor.added[0]?.info, ctx, editor }
}

async function runTests() {
  console.log("=== Testing OpenCode llama.cpp model discovery plugin ===")
  let passed = 0
  let failed = 0
  const check = async (name, fn) => {
    try {
      await fn()
      passed++
      console.log(`  PASS ${name}`)
    } catch (err) {
      failed++
      console.log(`  FAIL ${name}: ${err.message}`)
    }
  }

  await check("plugin default-exports a definition with an id and setup", async () => {
    assert.equal(typeof plugin, "object")
    assert.equal(plugin.id, "llamacpp-models")
    assert.equal(typeof plugin.setup, "function")
  })

  const { models, provider } = await publish()

  await check("provider source is published with the fetched inventory", async () => {
    assert.equal(provider.id, "llamacpp")
    assert.equal(provider.package, "@opencode/ai/providers/openai-compatible")
    assert.equal(provider.settings.baseURL, "http://127.0.0.1:8081/v1")
    assert.equal(models.length, 5)
  })

  await check("non-chat endpoints are excluded", async () => {
    assert.ok(!models.some((m) => m.id === "embed-tiny"))
    assert.ok(models.some((m) => m.id === "chat"))
  })

  await check("model fields are mapped from the payload", async () => {
    const m = models.find((x) => x.id === "Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF:Q4_K_M")
    assert.equal(m.modelID, m.id)
    assert.equal(m.providerID, "llamacpp")
    assert.equal(m.name, m.id)
    assert.equal(m.capabilities.tools, true)
    assert.equal(m.time.released, 1792002408000)
    assert.equal(m.status, "active")
  })

  await check("explicit --ctx-size is divided by --parallel and not clamped by --fit-ctx", async () => {
    assert.equal(models.find((m) => m.id === "chat").limit.context, 65536)
  })

  await check("unset --ctx-size uses context_length bounded by --fit-ctx while --fit is on", async () => {
    assert.equal(models.find((m) => m.id === "Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF:Q4_K_M").limit.context, 16384)
    assert.equal(models.find((m) => m.id === "small-model").limit.context, 4096)
  })

  await check("loaded models report meta.n_ctx directly", async () => {
    assert.equal(models.find((m) => m.id === "code").limit.context, 65536)
  })

  await check("entries with no size information fall back to 8192", async () => {
    assert.equal(models.find((m) => m.id === "mystery").limit.context, 8192)
  })

  await check("output limit is a quarter of the served context, capped at 4096", async () => {
    assert.equal(models.find((m) => m.id === "chat").limit.output, 4096)
    assert.equal(models.find((m) => m.id === "mystery").limit.output, 2048)
    assert.equal(models.find((m) => m.id === "small-model").limit.output, 1024)
  })

  await check("input modalities come from the payload", async () => {
    assert.deepEqual(models.find((m) => m.id === "small-model").capabilities.input, ["text", "image"])
    assert.deepEqual(models.find((m) => m.id === "chat").capabilities.output, ["text"])
  })

  await check("a configured provider id is updated in place instead of added", async () => {
    const { editor } = await publish({ existing: { id: "llamacpp", settings: { baseURL: "http://127.0.0.1:9090/v1" } } })
    assert.equal(editor.added.length, 0)
    assert.equal(editor.sets[0].providerID, "llamacpp")
    assert.equal(editor.sets[0].models.length, 5)
  })

  await check("plugin options override the default base URL", async () => {
    stubFetch(PAYLOAD)
    const ctx = fakeCtx({ options: { baseURL: "http://127.0.0.1:7070/v1" } })
    const cleanup = await plugin.setup(ctx)
    const editor = fakeEditor()
    ctx.transforms.forEach((transform) => editor.publish(transform))
    cleanup?.()
    assert.equal(editor.added[0].info.settings.baseURL, "http://127.0.0.1:7070/v1")
  })

  await check("server down publishes nothing and setup still succeeds", async () => {
    const { models: none, provider: missing } = await publish({ ok: false })
    assert.deepEqual(none, [])
    assert.equal(missing, undefined)
  })

  console.log(`\n${passed}/${passed + failed} assertions passed!`)
  process.exit(failed === 0 ? 0 : 1)
}

runTests()