# base-rules

A mixin kit that installs base behavioral rules into any Claude Code workspace.

The rules are delivered at sandbox creation via the `agent-context@1`
capability with inline `content:` — outside the checkout, so nothing lands in
the workspace and there's no `.gitignore` or startup-race to think about.

> [!WARNING]
> **Known limitation: the rules are not in the model's prompt.** With
> `agent-context@1`, `sbx` writes the body to
> `~/.claude/kits-agent-context/base-rules.md` and puts only an index entry
> into `~/.claude/CLAUDE.md`, telling the agent to read the file "only when a
> kit becomes relevant to your task — do not read them all upfront". On a
> KVM test with sbx v0.49.1, the requests Claude Code sent contained that
> index line and none of the rule text. Rules meant to apply to every task
> therefore depend on the agent choosing to open the file. `agent-context@2`
> inlines the body, but sbx v0.49.1 rejects it (see below), so this stays
> as-is until sbx and the published workloads move to @2.

The rule text itself talks to Claude Code specifically (it references the
`AskUserQuestion` tool by name), so it's written for Claude Code even though
v3 would deliver the same content to any other agent this mixin is composed
onto.

Composition note: this kit stays on `agent-context@1` on purpose. `sbx`
v0.49.1 does not accept `agent-context@2` yet, the spec refuses to compose
@1 with @2, and the published workloads (`docker.io/docker/sbx-kit-claude`,
`sbx-kit-shell`) declare @1. Every kit in this repo is on @1 for the same
reason, so they all stack.

## Rules included

- **interaction** — Clarifying questions threshold (ask when confidence < 98%), no-emoji policy for generated content, and prohibition on pre-approving tools in config files.
- **network-policy** — On a blocked network request, show the `--sandbox`-scoped allow command and ask the user to approve or deny; stop the task on denial instead of working around it.
- **stuck-escalation** — When stuck after genuine investigation, compose a structured deep-research prompt for the human rather than retrying blindly.

## Usage

```bash
sbx run docker.io/docker/sbx-kit-claude:2.1.296 --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-rules" ~/project
```

Stack with other kits:

```bash
sbx run docker.io/docker/sbx-kit-claude:2.1.296 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-rules" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    ~/project
```
