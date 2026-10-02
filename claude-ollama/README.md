> [!NOTE]
> <strong>Experimental: Sandbox Kit v3</strong>
>
> This kit uses the experimental [Sandbox Kit specification](https://github.com/docker/sandbox-kit-spec), specifically [v3](https://github.com/docker/sandbox-kit-spec/blob/main/docs/spec/SPEC-v3.md). The format and runtime behavior may change before v3 is stable.

# claude-ollama

> `ollama launch claude --model gemma4:e4b-it-q4_K_M` — but in `sbx`.

A fork of the built-in `claude` agent that routes all API calls to a local
**[Ollama](https://ollama.com)** instance instead of Anthropic's API. Useful for
offline development, cost-free experimentation, or testing with custom local models.

> **Prerequisite:** Ollama must be running on your host machine at its default port
> (`localhost:11434`) before starting this sandbox.

> **Only the model endpoint:** the kit itself grants nothing but the Ollama
> port. Your global `sbx` policy still applies on top: `balanced` allows AI
> services (Anthropic and OpenAI included), package registries and more for
> every sandbox. To keep the sandbox to the model endpoint alone, run it under
> a `deny-all` global policy (`sbx policy init deny-all`).

## Usage

```console
sbx run "git+https://github.com/alakae/sbx-kits.git#dir=claude-ollama" ~/my-project
sbx run ./claude-ollama/ ~/my-project
```

The git form needs `github.com/alakae/` in `kit.allowedSources`; see the
repository README.

The workload reference passed to `sbx run` identifies the kit. A v3 descriptor
carries no `name:` field; its matchable name is the `claude-ollama` entry under
`provides`.

That name is also why `requires: ["claude"]` mixins (such as
[`claude-safe-mixin`](../claude-safe-mixin)) do not compose onto this kit: it
provides `claude-ollama`, which is exactly the boundary the v2 kit's own agent
name drew.

The default model is `gemma4:e4b-it-q4_K_M`. To use a different model, set
`CLAUDE_OLLAMA_MODEL` when you create the sandbox
(`sbx run -e CLAUDE_OLLAMA_MODEL=qwen3-coder:30b …`), or change the `ENV`
default in [`claude-ollama.dockerfile`](./claude-ollama.dockerfile).

## What changed vs the built-in `claude`

Instead of calling `api.anthropic.com`, a wrapper script replaces the entrypoint.
Under v3 the entrypoint lives in the image config, where OCI already carries the
runtime contract, so the swap happens in the recipe:

```diff
-ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
+ENTRYPOINT ["/home/agent/.local/bin/claude-ollama"]
```

The wrapper itself is written by a lifecycle `files:` entry, which the runtime
lands before the entrypoint first runs.

The wrapper script:

1. Sets `ANTHROPIC_BASE_URL` to `http://host.docker.internal:11434` (Ollama via Docker's host bridge)
2. Uses a dummy `ANTHROPIC_AUTH_TOKEN` — Ollama doesn't require real credentials
3. Maps every Claude model alias (Opus, Sonnet, Haiku, sub-agent) to `$CLAUDE_OLLAMA_MODEL`
4. Calls `exec claude "$@"` — the real Claude Code CLI takes over from there

**Reference:** [`ollama/ollama` — cmd/launch/claude.go](https://github.com/ollama/ollama/blob/8f39fff70bac0bef2370a6af7020efa29a6a7cad/cmd/launch/claude.go)

The kit's only network grant is the Ollama port. The wrapper talks to
`host.docker.internal:11434`, but the sandbox proxy rewrites
`host.docker.internal` to the host's `localhost` before it applies the policy,
so the allow entry is `localhost:11434` — the name the proxy actually matches.
No Anthropic API domain is granted. The port suffix is kept deliberately rather
than following the portless house style: this is the host itself, so dropping
it would widen the grant from one local model server to every port the host has
open.

