# claude-safe

A fork of the built-in `claude` agent that **does not** pass
`--dangerously-skip-permissions`, and disables `auto` mode entirely so
every tool call prompts for approval, matching how you'd run Claude Code
outside a sandbox.

A Claude Code [managed
settings](https://code.claude.com/docs/en/settings) drop-in at
`/etc/claude-code/managed-settings.d/claude-safe.json` turns off bypass mode
(including `--dangerously-skip-permissions`), removes `auto` from the session
entirely — dropping it from the `Shift+Tab` cycle, forcing the starting mode
to `default`, and making plan mode prompt for shell commands instead of
routing them through the classifier — and stops [Remote
Control](https://code.claude.com/docs/en/remote-control) from
auto-connecting. Managed settings outrank user, project and command-line
settings, so neither the agent nor a project's `.claude/settings.json` can
turn these back on. See
[permission-modes](https://code.claude.com/docs/en/permission-modes) and
[settings-reference](https://code.claude.com/docs/en/settings-reference).

Addresses the community ask in
[docker/sbx-releases#47](https://github.com/docker/sbx-releases/issues/47).

## Usage

```console
$ sbx run "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe" ~/my-project
```

The kit is the first argument of `sbx run`, where a built-in agent name would
go. [`claude-safe-mixin`](../claude-safe-mixin) ships the same policy as a
mixin, for other workloads that carry Claude Code.

## What changed vs the built-in `claude`

The kit is a fork of [docker/sbx-kits-contrib's `claude`
kit](https://github.com/docker/sbx-kits-contrib/tree/7f8518ce98d439a35096ff7f6d00e9b8f65b0f53/claude)
(see [NOTICE.md](./NOTICE.md)). The differences are the managed settings
drop-in above, the entrypoint, and install hooks that no longer seed
bypass-mode settings:

```diff
-ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
+ENTRYPOINT ["claude"]
```

Everything else — image, network, credentials, environment — mirrors the
built-in agent so you keep the same Anthropic API credential handling
and the same `IS_SANDBOX=1` hint.

## Use this as a template for other forks

Copy the kit and change the `ENTRYPOINT` in `claude-safe.dockerfile` to pass
your own flags. Some ideas:

- `["claude", "--model", "claude-opus-4-5"]` — pin a specific model
- `["claude", "--append-system-prompt", "Always write tests before code."]`
- Run a different base image entirely by changing `BASE_IMAGE`.

When you fork an agent, make sure the base image still provides the
[agent user and proxy env vars the spec requires][reqs].

[reqs]: https://docs.docker.com/ai/sandboxes/customize/kits/#base-image-requirements
