# claude-safe-mixin

[`claude-safe`](../claude-safe)'s approval mode as a **mixin**. It layers one
file onto any workload that carries Claude Code: a managed-settings drop-in at
`/etc/claude-code/managed-settings.d/claude-safe.json` that disables
bypass-permissions mode, auto mode and Remote Control at startup.

## Usage

```console
$ sbx run <claude-workload> --kit ./claude-safe-mixin .
$ sbx run <claude-workload> --kit "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe-mixin" ~/my-project
```

`<claude-workload>` is any workload that provides `claude` (the kit declares
`requires: ["claude"]`), for example contrib's `claude`:

```console
$ sbx run "git+https://github.com/docker/sbx-kits-contrib.git#ref=7f8518ce98d439a35096ff7f6d00e9b8f65b0f53&dir=claude" --kit ./claude-safe-mixin .
```

On [`claude-safe`](../claude-safe) itself the mixin is redundant; that
workload ships the same policy.

## How it works

The mixin doesn't own the launch command, so the base workload keeps its
entrypoint. The policy still wins, because Claude Code's managed settings
outrank command-line flags:

- On a base launched with `claude --dangerously-skip-permissions`, Claude Code
  logs "bypassPermissions mode is disabled by settings" and starts in the
  default (prompting) mode instead.
- Auto mode is unavailable, and Remote Control doesn't auto-connect.

The policy is a drop-in rather than `/etc/claude-code/managed-settings.json`,
so it doesn't replace a policy file another layer may ship.

## Verify

```console
$ cd claude-safe-mixin && docker buildx build . -f claude-safe-mixin.yaml --output type=cacheonly
```
