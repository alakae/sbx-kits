# base-skills

A mixin that drops a collection of Claude Code skills into the sandbox workspace.

## Skills

| Skill | What it does |
| ----- | ------------ |
| `astral-ruff` | Guides the agent to use Ruff for Python linting and formatting |
| `astral-ty` | Guides the agent to use ty for Python type checking |
| `astral-uv` | Guides the agent to use uv for Python package and project management |
| `fix-dependabot` | Resolves peer dependency conflicts on Dependabot branches |
| `review-claude-config` | Audits `.claude/` configuration files against best practices |
| `session-review` | End-of-session retrospective — proposes skill and settings improvements |

## Usage

```console
$ sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" ~/my-project
```

Stack with other kits:

```console
$ sbx run claude \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" \
    ~/my-project
```
