#!/usr/bin/env node
/**
 * Test suite for dot_config/opencode/plugins/llamacpp-models.ts
 *
 * The plugin maps llama.cpp's /v1/models payload into opencode Model objects.
 * fetch is stubbed so the mapping is verified without a running llama-server.
 */

import assert from "node:assert"
import { LlamaCppModelsPlugin } from "../dot_config/opencode/plugins/llamacpp-models.ts"
const { fetchModels, cache, outputSize } = LlamaCppModelsPlugin

const PROVIDER = { id: "llamacpp", options: { baseURL: "http://127.0.0.1:8081/v1" } }

const PAYLOAD = {
  data: [
    {
      id: "chat-quality",
      created: 1792002408,
      architecture: { input_modalities: ["text"], output_modalities: ["text"] },
      status: { args: ["llama-server", "--ctx-size", "32768"] }
    },
    {
      id: "vision-documents",
      created: 1792002408,
      architecture: { input_modalities: ["text", "image"], output_modalities: ["text"] },
      status: { args: ["llama-server"] }
    },
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

stubFetch(PAYLOAD)

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

  await check("plugin registers the llamacpp provider hook", async () => {
    const hooks = await LlamaCppModelsPlugin({})
    assert.equal(hooks.provider.id, "llamacpp")
    assert.equal(typeof hooks.provider.models, "function")
  })

  const models = await fetchModels(PROVIDER)

  await check("non-chat endpoints are excluded", async () => {
    assert.ok(!("embed-tiny" in models))
    assert.ok("chat-quality" in models)
  })

  await check("model fields are mapped from the payload", async () => {
    const m = models["chat-quality"]
    assert.equal(m.id, "chat-quality")
    assert.equal(m.providerID, "llamacpp")
    assert.equal(m.api.url, "http://127.0.0.1:8081/v1")
    assert.equal(m.capabilities.toolcall, true)
  })

  await check("ctx-size from llama-server args sets the context limit", async () => {
    assert.equal(models["chat-quality"].limit.context, 32768)
  })

  await check("missing ctx-size falls back to 8192", async () => {
    assert.equal(models["vision-documents"].limit.context, 8192)
  })

  await check("output limit is capped to prevent zero-budget instant compaction", async () => {
    assert.equal(models["chat-quality"].limit.output, 4096)
    assert.equal(models["vision-documents"].limit.output, 2048)
    assert.equal(outputSize(16384), 4096)
    assert.equal(outputSize(4096), 1024)
  })

  await check("image modality enables attachment", async () => {
    assert.equal(models["vision-documents"].capabilities.attachment, true)
    assert.equal(models["vision-documents"].capabilities.input.image, true)
    assert.equal(models["chat-quality"].capabilities.attachment, false)
  })

  await check("other providers are ignored", async () => {
    const hooks = await LlamaCppModelsPlugin({})
    assert.deepEqual(await hooks.provider.models({ id: "anthropic", options: {} }), {})
  })

  await check("server down yields no models and retries next call", async () => {
    stubFetch(PAYLOAD, false)
    cache.clear()
    assert.deepEqual(await fetchModels(PROVIDER), {})
    stubFetch(PAYLOAD)
    assert.equal((await fetchModels(PROVIDER))["chat-quality"].id, "chat-quality")
  })

  console.log(`\n${passed}/${passed + failed} assertions passed!`)
  process.exit(failed === 0 ? 0 : 1)
}

runTests()