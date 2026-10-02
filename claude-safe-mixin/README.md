# claude-safe-mixin

Claude Code's approval mode as a **mixin**. It layers one file onto any
workload that carries Claude Code: a managed-settings drop-in at
`/etc/claude-code/managed-settings.d/claude-safe.json` that starts every session
in Manual mode, disables bypass-permissions mode, keeps auto mode for when you
ask for it, and makes the managed policy the only source of permission rules.

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 --kit ./claude-safe-mixin .
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe-mixin" ~/my-project
```

Any workload that provides `claude` works (the kit declares `requires:
["claude"]`), such as this repo's `claude-ollama`:

```console
$ sbx run ./claude-ollama --kit ./claude-safe-mixin .
```

## How it works

The mixin doesn't own the launch command, so the base workload keeps its
entrypoint. The policy still wins, because Claude Code's managed settings
outrank command-line flags:

- On a base launched with `claude --dangerously-skip-permissions`, Claude Code
  logs "bypassPermissions mode is disabled by settings" and starts in Manual
  (`default`) mode instead.
- Sessions start in Manual mode (`permissions.defaultMode: "default"`), whatever
  the workload's or your own settings say and despite Claude Code's built-in
  auto default (v2.1.283+).
- Auto mode stays available, but only when you choose it: `Shift+Tab` or
  `--permission-mode auto`.
- Plan mode doesn't use the auto-mode classifier (`useAutoModeDuringPlan:
  false`): a planning command outside the built-in read-only set asks you
  instead of being approved by the classifier.
- Remote Control doesn't auto-connect.
- Allow, ask and deny rules from user, project, local and `--settings` files
  (and `--allowedTools`) are ignored, because the policy sets
  `allowManagedPermissionRulesOnly`. Without it, disabling bypass mode is not
  enough: the claude workload pre-accepts workspace trust, so a repository
  that ships `.claude/settings.json` with `"allow": ["Bash"]` gets its Bash
  calls run without approval. Verified on sbx v0.49.1 with
  `docker.io/docker/sbx-kit-claude:2.1.296`: with the key the same call is
  refused as "needs approval".

The price is that your own allow rules don't apply either, and the approval
prompt offers no "always allow": every tool call that needs permission asks,
every time.

The policy is a drop-in rather than `/etc/claude-code/managed-settings.json`,
so it doesn't replace a policy file another layer may ship.

## What it is not

A guardrail against running tool calls without your approval (unless you
switch to auto mode yourself), not a security boundary against the agent. The
file is root-owned, but the published workloads give the agent passwordless
`sudo`, so an agent set on removing the policy can — though that `sudo rm` is
itself a tool call you have to approve. The sandbox's real boundaries are the
microVM and the network policy.

## Verify

```console
$ cd claude-safe-mixin && docker buildx build . -f claude-safe-mixin.yaml --output type=cacheonly
```
