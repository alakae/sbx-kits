# base-rules

A mixin kit that installs base behavioral rules into any Claude Code workspace.

Rules are placed in `.claude/rules/` and automatically loaded as persistent instructions.

## Rules included

- **interaction** — Clarifying questions threshold (ask when confidence < 98%), no-emoji policy for generated content, and prohibition on pre-approving tools in config files.
- **network-policy** — On a blocked network request, show the `--sandbox`-scoped allow command and ask the user to approve or deny; stop the task on denial instead of working around it.
- **stuck-escalation** — When stuck after genuine investigation, compose a structured deep-research prompt for the human rather than retrying blindly.

## Usage

```bash
sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-rules" ~/project
```

Stack with other kits:

```bash
sbx run claude \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-rules" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    ~/project
```
