# claude-safe

A fork of the built-in `claude` agent that **does not** pass
`--dangerously-skip-permissions`. Every tool call prompts for approval,
matching how you'd run Claude Code outside a sandbox.

Addresses the community ask in
[docker/sbx-releases#47](https://github.com/docker/sbx-releases/issues/47).

## Usage

```console
$ sbx run claude-safe --kit "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe" ~/my-project
```

The agent name passed to `sbx run` (`claude-safe`) matches the `name:` field
in the kit's `spec.yaml`.

## What changed vs the built-in `claude`

The only difference is the entrypoint:

```diff
 entrypoint:
-  run: [claude, "--dangerously-skip-permissions"]
+  run: [claude]
```

Everything else — image, network, credentials, environment — mirrors the
built-in agent so you keep the same Anthropic API credential handling,
the same `IS_SANDBOX=1` hint, and persistent storage across restarts.

## Use this as a template for other forks

Copy `spec.yaml` and change the `entrypoint.run` array to pass your own
flags. Some ideas:

- `[claude, "--model", "claude-opus-4-5"]` — pin a specific model
- `[claude, "--append-system-prompt", "Always write tests before code."]`
- Run a different base image entirely by swapping `agent.image`.

When you fork an agent, make sure the base image still provides the
[agent user and proxy env vars the spec requires][reqs].

[reqs]: https://docs.docker.com/ai/sandboxes/customize/kits/#base-image-requirements
